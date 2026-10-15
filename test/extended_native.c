#include "core.h"
#include "internal.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

static void pixel(SDL_Renderer* renderer, int x, int y, Uint8 expected_r, Uint8 expected_g) {
    SDL_Surface* pixels = SDL_RenderReadPixels(renderer, NULL);
    Uint8        r, g, b, a;

    assert(pixels && SDL_ReadSurfacePixel(pixels, x, y, &r, &g, &b, &a));
    assert(r == expected_r && g == expected_g);

    SDL_DestroySurface(pixels);
}

static void geometry_tests(SDL_Renderer* renderer) {
    assert(!idris_sdl_geometry_new(0, 0) && !idris_sdl_geometry_new(0x80000000u, 0));
    assert(!idris_sdl_geometry_new(1, 0x80000000u));

    IdrisSDLGeometry* geometry = idris_sdl_geometry_new(4, 6);

    assert(geometry);

    const double xy[4][2] = {
        {0, 0},
        {8, 0},
        {8, 8},
        {0, 8}
    };

    const Uint32 indices[6] = {0, 1, 2, 0, 2, 3};

    for (Uint32 i = 0; i < 4; ++i)
        assert(idris_sdl_geometry_vertex(geometry, i, xy[i][0], xy[i][1], 255, 0, 0, 255, xy[i][0] / 8, xy[i][1] / 8));

    for (Uint32 i = 0; i < 6; ++i)
        assert(idris_sdl_geometry_index(geometry, i, indices[i]));

    assert(!idris_sdl_geometry_vertex(geometry, 4, 0, 0, 0, 0, 0, 0, 0, 0));
    assert(!idris_sdl_geometry_vertex(geometry, 0, NAN, 0, 0, 0, 0, 0, 0, 0));
    assert(!idris_sdl_geometry_index(geometry, 6, 0) && !idris_sdl_geometry_index(geometry, 0, 4));
    assert(!idris_sdl_geometry_draw(renderer, geometry, 3, 6));
    assert(!idris_sdl_geometry_draw(renderer, geometry, 4, 5));
    assert(!idris_sdl_geometry_draw(renderer, geometry, 4, 0));
    assert(idris_sdl_geometry_draw(renderer, geometry, 0, 0));
    assert(idris_sdl_geometry_draw(renderer, geometry, 4, 6));

    pixel(renderer, 2, 2, 255, 0);
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STATIC, 1, 1);
    const Uint8  white[] = {255, 255, 255, 255};

    assert(texture && SDL_UpdateTexture(texture, NULL, white, 4));
    assert(SDL_SetTextureColorMod(texture, 0, 0, 0) && SDL_SetTextureAlphaMod(texture, 0));
    assert(SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255) && SDL_RenderClear(renderer));
    assert(idris_sdl_geometry_texture(renderer, texture, geometry, 4, 6));
    pixel(renderer, 2, 2, 255, 0); /* Geometry ignores texture modulation. */

    SDL_DestroyTexture(texture);
    SDL_free(geometry);
}
static void bulk_tests(SDL_Renderer* renderer) {
    IdrisSDLPoints* points   = idris_sdl_points_new(2);
    IdrisSDLRects*  rects    = idris_sdl_rects_new(1);
    const double    values[] = {2, 3, 4, 5};
    Uint8           unaligned[sizeof(values) + 1];

    memcpy(unaligned + 1, values, sizeof(values));

    assert(points && rects);
    assert(idris_sdl_points_copy(points, 0, unaligned, sizeof(unaligned), 1, 2));
    assert(!idris_sdl_points_copy(points, 1, values, sizeof(values), 0, 2));
    assert(!idris_sdl_points_copy(points, 0, values, 16, 0, 2));
    assert(!idris_sdl_points_copy(points, 0, values, sizeof(values), SDL_MAX_UINT64, 1));

    double bad[] = {9, 9, NAN, 1};

    assert(!idris_sdl_points_copy(points, 0, bad, sizeof(bad), 0, 2));
    assert(idris_sdl_points_copy(points, 2, NULL, 0, 0, 0));
    assert(SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255));
    assert(idris_sdl_draw_points(renderer, points, 2));

    pixel(renderer, 2, 3, 0, 255);

    assert(idris_sdl_rects_copy(rects, 0, values, sizeof(values), 0, 1));
    assert(!idris_sdl_rects_copy(rects, 0, values, sizeof(values) - 1, 0, 1));
    assert(idris_sdl_fill_rects(renderer, rects, 1));

    pixel(renderer, 3, 4, 0, 255);

    idris_sdl_points_free(points);
    idris_sdl_rects_free(rects);
}
static void query_tests(SDL_Renderer* renderer) {
    IdrisSDLRenderState* state = idris_sdl_render_state_new();

    assert(state && idris_sdl_render_state(renderer, state, 0) && !state->enabled);

    SDL_Rect rect = {1, 2, 8, 9};

    assert(SDL_SetRenderViewport(renderer, &rect));
    assert(idris_sdl_render_state(renderer, state, 0) && state->enabled && state->x == 1 && state->height == 9);
    assert(SDL_SetRenderViewport(renderer, NULL));
    assert(idris_sdl_render_state(renderer, state, 1) && !state->enabled);

    SDL_Rect empty = {0, 0, 0, 0};

    assert(SDL_SetRenderClipRect(renderer, &empty));
    assert(idris_sdl_render_state(renderer, state, 1) && state->enabled && state->width == 0);
    assert(SDL_SetRenderClipRect(renderer, NULL));
    assert(SDL_SetRenderScale(renderer, 1.5f, 2.5f));
    assert(idris_sdl_render_state(renderer, state, 2) && state->scale_x == 1.5 && state->scale_y == 2.5);
    assert(SDL_SetRenderScale(renderer, 1, 1));
    assert(SDL_SetRenderDrawColor(renderer, 17, 34, 51, 68));
    assert(idris_sdl_render_state(renderer, state, 3) && state->color == 0x11223344);
    assert(idris_sdl_render_state(renderer, state, 4) && state->width == 16);

    SDL_Texture* target = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_TARGET, 8, 8);

    assert(target && SDL_SetRenderTarget(renderer, target));
    assert(SDL_SetRenderLogicalPresentation(renderer, 4, 4, SDL_LOGICAL_PRESENTATION_STRETCH));

    int native_width, native_height;

    assert(SDL_GetRenderOutputSize(renderer, &native_width, &native_height));
    assert(idris_sdl_render_state(renderer, state, 4) && state->width == native_width && state->height == native_height);
    assert(SDL_GetCurrentRenderOutputSize(renderer, &native_width, &native_height));
    assert(idris_sdl_render_state(renderer, state, 5) && state->width == native_width && state->height == native_height);
    assert(SDL_SetTextureColorMod(target, 17, 34, 51) && idris_sdl_texture_color(target) == 0x112233);
    assert(!idris_sdl_render_state(renderer, state, 99) && !idris_sdl_render_state(NULL, state, 0));
    assert(!idris_sdl_render_state(renderer, NULL, 0) && idris_sdl_texture_color(NULL) == -1);
    assert(SDL_SetRenderTarget(renderer, NULL));
    SDL_DestroyTexture(target);
    SDL_free(state);
}

static void input_tests(void) {
    SDL_PumpEvents();

    IdrisSDLKeyboard* keyboard = idris_sdl_keyboard_new();
    int               count;
    const bool*       keys = SDL_GetKeyboardState(&count);

    assert(keyboard && idris_sdl_keyboard_refresh(keyboard));

    for (int i = 0; i < count; ++i)
        assert(idris_sdl_keyboard_key(keyboard, (Uint32)i) == (int)keys[i]);

    assert(!idris_sdl_keyboard_key(keyboard, SDL_MAX_UINT32) && !idris_sdl_keyboard_refresh(NULL));

    SDL_free(keyboard);
    IdrisSDLMouseState* mouse = idris_sdl_mouse_state_new();
    float               x, y;
    Uint32              buttons = SDL_GetMouseState(&x, &y);

    assert(mouse && idris_sdl_mouse_state(mouse, 0) && mouse->x == x && mouse->y == y && mouse->buttons == buttons);
    assert(idris_sdl_mouse_state(mouse, 1) && idris_sdl_mouse_state(mouse, 1));
    assert(mouse->x == 0 && mouse->y == 0);
    assert(!idris_sdl_mouse_state(NULL, 0));

    SDL_free(mouse);

    assert(!idris_sdl_gamepad_has_axis(NULL, 0) && !idris_sdl_gamepad_has_button(NULL, 0));
    assert(!idris_sdl_gamepad_has_rumble(NULL));

    SDL_Event event        = {0};
    event.render.windowID  = SDL_MAX_UINT32;
    event.render.timestamp = 0x100000002ull;
    event.type             = SDL_EVENT_RENDER_TARGETS_RESET;

    assert(idris_sdl_event_kind(&event) == 38 && idris_sdl_event_window(&event) == SDL_MAX_UINT32);

    event.type = SDL_EVENT_RENDER_DEVICE_RESET;

    assert(idris_sdl_event_kind(&event) == 39 && idris_sdl_event_timestamp(&event) == 0x100000002ull);
}

static void abi_checks(void) {
    assert(idris_sdl_buffer_range(0, 0, 0));
    assert(idris_sdl_buffer_range(32, 32, 0));
    assert(idris_sdl_buffer_range(32, 16, 16));
    assert(!idris_sdl_buffer_range(32, 33, 0));
    assert(!idris_sdl_buffer_range(32, 16, 17));
    assert(!idris_sdl_buffer_range(SDL_MAX_UINT64, SDL_MAX_UINT64, 1));
    assert(!idris_sdl_buffer_range(SDL_MAX_UINT64, 1, SDL_MAX_UINT64));
    assert(idris_sdl_buffer_range(SIZE_MAX, SIZE_MAX, 0));
    assert(!idris_sdl_buffer_range(SDL_MAX_UINT64, SIZE_MAX, 1));
    assert(idris_sdl_fits_float(FLT_MAX) && idris_sdl_fits_float(-FLT_MAX));
    assert(idris_sdl_fits_float(0) && idris_sdl_fits_float(1.0e-300));
    assert(!idris_sdl_fits_float(NAN) && !idris_sdl_fits_float(INFINITY));
    assert(!idris_sdl_fits_float(-INFINITY) && !idris_sdl_fits_float((double)FLT_MAX * 2));
}

int main(void) {
    abi_checks();

    assert(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD));

    SDL_Window*   window   = SDL_CreateWindow("extended tests", 16, 16, SDL_WINDOW_HIDDEN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, "software");

    assert(window && renderer);

    geometry_tests(renderer);
    bulk_tests(renderer);
    query_tests(renderer);

    input_tests();

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    puts("Extended native tests passed");
}
