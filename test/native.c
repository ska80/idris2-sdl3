#include "sdl3.h"

#include <assert.h>
#include <stdio.h>

static void size_tests(void) {
    assert(SDL_Init(SDL_INIT_VIDEO));

    SDL_Window* window = SDL_CreateWindow("size storage", 37, 23, SDL_WINDOW_HIDDEN);
    assert(window);

    IdrisSDLSize* size = idris_sdl_size_new();
    assert(size);
    assert(idris_sdl_get_window_size(window, size) == 1);
    assert(size->width == 37 && size->height == 23);

    IdrisSDLSize copied = *size;
    assert(idris_sdl_get_window_size_pixels(window, size) == 1);
    assert(size->width == 37 && size->height == 23);
    assert(idris_sdl_get_window_size(NULL, size) == 0);
    assert(idris_sdl_get_window_size_pixels(NULL, size) == 0);
    assert(SDL_SetWindowSize(window, 53, 31));
    assert(SDL_SyncWindow(window));
    assert(idris_sdl_get_window_size(window, size) == 1);
    assert(size->width == 53 && size->height == 31);
    assert(idris_sdl_get_window_size(window, NULL) == 0);
    assert(idris_sdl_get_window_size_pixels(window, NULL) == 0);

    idris_sdl_size_free(size);
    idris_sdl_size_free(NULL);

    SDL_DestroyWindow(window);

    assert(copied.width == 37 && copied.height == 23);
}

static void point_buffer_tests(void) {
    assert(idris_sdl_points_new(0) == NULL);
    assert(idris_sdl_points_new(0x80000000u) == NULL);
    assert(idris_sdl_points_new(SDL_MAX_UINT32) == NULL);
    if (sizeof(size_t) == 4) assert(idris_sdl_points_new(0x20000000u) == NULL);
    assert(idris_sdl_points_set(NULL, 0, 1, 2) == 0);
    assert(idris_sdl_draw_points(NULL, NULL, 0) == 0);
    assert(idris_sdl_draw_lines(NULL, NULL, 0) == 0);

    IdrisSDLPoints* points = idris_sdl_points_new(3);
    assert(points);
    assert(idris_sdl_points_set(points, 0, 1.25, -2.5) == 1);
    assert(idris_sdl_points_set(points, 2, 4.5, 8.25) == 1);
    assert(idris_sdl_points_set(points, 3, 0, 0) == 0);
    assert(idris_sdl_points_set(points, SDL_MAX_UINT32, 0, 0) == 0);
    assert(idris_sdl_draw_points(NULL, points, 4) == 0);
    assert(idris_sdl_draw_lines(NULL, points, SDL_MAX_UINT32) == 0);
    assert(idris_sdl_draw_points(NULL, points, 0) == 0);
    assert(idris_sdl_draw_lines(NULL, points, 0) == 0);
    assert(idris_sdl_draw_points(NULL, points, 3) == 0);
    assert(idris_sdl_draw_lines(NULL, points, 3) == 0);
    assert(SDL_GetError()[0] != '\0');
    idris_sdl_points_free(points);
    idris_sdl_points_free(NULL);
}

int main(void) {
    assert(idris_sdl_init(SDL_INIT_EVENTS) == 1);
    assert(idris_sdl_is_null(NULL) == 1);
    assert(idris_sdl_create_renderer(NULL) == NULL);
    assert(idris_sdl_get_window_size(NULL, NULL) == 0);
    assert(idris_sdl_get_window_size_pixels(NULL, NULL) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_create_target_texture(NULL, 16, 16) == NULL);
    assert(idris_sdl_create_streaming_texture(NULL, 2, 2) == NULL);

    const Uint8 pixels[16] = {0};

    assert(idris_sdl_update_texture_rgba(NULL, pixels, sizeof(pixels), 8) == 0);
    assert(idris_sdl_update_texture_region_rgba(NULL, 0, 0, 1, 1, pixels, sizeof(pixels), 4) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_set_texture_color_mod(NULL, 255, 255, 255) == 0);
    assert(idris_sdl_set_texture_alpha_mod(NULL, 255) == 0);
    assert(idris_sdl_set_texture_blend_mode(NULL, SDL_BLENDMODE_BLEND) == 0);
    assert(idris_sdl_set_texture_scale_mode(NULL, SDL_SCALEMODE_NEAREST) == 0);
    assert(idris_sdl_set_render_viewport(NULL, 0, 0, 16, 16) == 0);
    assert(idris_sdl_reset_render_viewport(NULL) == 0);
    assert(idris_sdl_set_render_clip_rect(NULL, 0, 0, 16, 16) == 0);
    assert(idris_sdl_reset_render_clip_rect(NULL) == 0);
    assert(idris_sdl_set_draw_blend_mode(NULL, SDL_BLENDMODE_BLEND) == 0);
    assert(idris_sdl_set_render_scale(NULL, 2.0, 3.0) == 0);
    assert(idris_sdl_set_render_vsync(NULL, 0) == 0);
    assert(idris_sdl_set_render_vsync(NULL, -2) == 0);
    assert(idris_sdl_set_render_vsync(NULL, 4294967295LL) == 0);
    assert(idris_sdl_get_render_vsync(NULL) == -2);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_set_render_logical_presentation(NULL, 320, 240, SDL_LOGICAL_PRESENTATION_LETTERBOX) == 0);
    assert(idris_sdl_reset_render_target(NULL) == 0);
    assert(idris_sdl_set_render_target(NULL, NULL) == 0);
    assert(idris_sdl_draw_point(NULL, 1.25, 2.5) == 0);
    assert(idris_sdl_draw_line(NULL, 1.25, 2.5, 3.75, 4.5) == 0);
    assert(idris_sdl_draw_rect(NULL, 1, 1.25, 2.5, 3.75, 4.5) == 0);
    assert(idris_sdl_draw_rect(NULL, 0, 0, 0, 0, 0) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_render_texture(NULL, NULL) == 0);
    assert(idris_sdl_render_texture_rotated(NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90, 0, 0) == 0);
    assert(idris_sdl_render_texture_rotated(NULL, NULL, 31, 0, 0, 8, 8, 2, 3, 16, 16, 45, 4, 5) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_render_texture_rect(NULL, NULL, 0, 0, 16, 16) == 0);
    assert(idris_sdl_render_texture_source(NULL, NULL, 0, 0, 16, 16) == 0);
    assert(idris_sdl_render_texture_region(NULL, NULL, 0, 0, 16, 16, 0, 0, 32, 32) == 0);
    assert(SDL_CreateTextureFromSurface(NULL, NULL) == NULL);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_start_text_input(NULL) == 0);
    assert(idris_sdl_stop_text_input(NULL) == 0);
    assert(idris_sdl_text_input_active(NULL) == 0);
    assert(idris_sdl_set_text_input_area(NULL, 0, 0, 40, 20, 5) == 0);
    assert(idris_sdl_clear_text_input_area(NULL) == 0);
    assert(idris_sdl_clear_composition(NULL) == 0);

    SDL_Event empty_text = {0};
    empty_text.type      = SDL_EVENT_TEXT_INPUT;
    assert(idris_sdl_event_text(&empty_text)[0] == '\0');
    empty_text.type = SDL_EVENT_TEXT_EDITING;
    assert(idris_sdl_event_text(&empty_text)[0] == '\0');

    IdrisSDLPoint* coordinates = idris_sdl_coordinate_new();
    assert(coordinates);
    assert(idris_sdl_render_coordinates_from_window(NULL, 1.5, 2.5, coordinates) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_render_coordinates_to_window(NULL, 1.5, 2.5, coordinates) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_render_coordinates_from_window(NULL, 1.5, 2.5, NULL) == 0);
    assert(idris_sdl_render_coordinates_to_window(NULL, 1.5, 2.5, NULL) == 0);
    idris_sdl_coordinate_free(coordinates);
    idris_sdl_coordinate_free(NULL);

    SDL_Event* buffer = idris_sdl_event_new();

    assert(buffer && !idris_sdl_is_null(buffer));

    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);

    assert(idris_sdl_poll(buffer) == 0);
    assert(idris_sdl_wait_event(NULL) == 0);
    assert(idris_sdl_wait_event_timeout(NULL, 0) == -1);
    assert(idris_sdl_wait_event_timeout(buffer, 0x80000000u) == -1);
    SDL_SetError("Stale error before a timed wait");
    assert(idris_sdl_wait_event_timeout(buffer, 0) == 0);
    assert(SDL_GetError()[0] == '\0');
    assert(idris_sdl_wait_event_timeout(buffer, 1) == 0);

    const Uint32 types[] = {SDL_EVENT_QUIT, SDL_EVENT_WINDOW_CLOSE_REQUESTED, SDL_EVENT_KEY_DOWN, SDL_EVENT_KEY_UP, SDL_EVENT_USER};

    for (int i = 0; i < 5; ++i) {
        SDL_Event event = {0};
        event.type      = types[i];

        assert(SDL_PushEvent(&event));
        assert(idris_sdl_poll(buffer) == 1);
        assert(idris_sdl_event_type(buffer) == types[i]);
        assert(idris_sdl_event_kind(buffer) == (i == 4 ? 0 : i + 1));
        assert(SDL_PushEvent(&event));
        assert(idris_sdl_wait_event(buffer) == 1);
        assert(idris_sdl_event_type(buffer) == types[i]);
        assert(SDL_PushEvent(&event));
        assert(idris_sdl_wait_event_timeout(buffer, 0) == 1);
        assert(idris_sdl_event_type(buffer) == types[i]);

        SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);
    }

    SDL_Event size_event        = {0};
    size_event.type             = SDL_EVENT_WINDOW_RESIZED;
    size_event.window.timestamp = SDL_UINT64_C(0x100000002);
    size_event.window.windowID  = 0x80000001u;
    size_event.window.data1     = SDL_MIN_SINT32;
    size_event.window.data2     = SDL_MAX_SINT32;
    assert(idris_sdl_event_kind(&size_event) == 11);
    assert(idris_sdl_event_window(&size_event) == 0x80000001u);
    assert(idris_sdl_event_timestamp(&size_event) == SDL_UINT64_C(0x100000002));
    assert(idris_sdl_event_window_data1(&size_event) == SDL_MIN_SINT32);
    assert(idris_sdl_event_window_data2(&size_event) == SDL_MAX_SINT32);
    size_event.type = SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED;
    assert(idris_sdl_event_kind(&size_event) == 12);
    assert(idris_sdl_event_window(&size_event) == 0x80000001u);

    idris_sdl_event_free(buffer);

    size_tests();
    point_buffer_tests();
    SDL_Quit();

    puts("Native tests passed");

    return 0;
}
