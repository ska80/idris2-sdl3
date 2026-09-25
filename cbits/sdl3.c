#include "sdl3.h"

_Static_assert(sizeof(int) == 4, "Bindings require 32-bit C int");

_Static_assert(SDL_VERSION_ATLEAST(3, 2, 12), "Bindings require SDL 3.2.12 or newer");

_Static_assert(SDL_MOUSEWHEEL_NORMAL == 0 && SDL_MOUSEWHEEL_FLIPPED == 1, "Update SDL3 wheel direction decoding");

_Static_assert(SDLK_ESCAPE == 27, "Update SDL3.Events.escapeKey");

_Static_assert(SDL_LOGICAL_PRESENTATION_DISABLED == 0 && SDL_LOGICAL_PRESENTATION_STRETCH == 1 && SDL_LOGICAL_PRESENTATION_LETTERBOX == 2 &&
                   SDL_LOGICAL_PRESENTATION_OVERSCAN == 3 && SDL_LOGICAL_PRESENTATION_INTEGER_SCALE == 4,
               "Update SDL3 logical presentation constants");

_Static_assert(SDL_BLENDMODE_NONE == 0 && SDL_BLENDMODE_BLEND == 1 && SDL_BLENDMODE_BLEND_PREMULTIPLIED == 0x10 && SDL_BLENDMODE_ADD == 2 &&
                   SDL_BLENDMODE_ADD_PREMULTIPLIED == 0x20 && SDL_BLENDMODE_MOD == 4 && SDL_BLENDMODE_MUL == 8,
               "Update SDL3 blend mode constants");

_Static_assert(SDL_SCALEMODE_NEAREST == 0 && SDL_SCALEMODE_LINEAR == 1, "Update SDL3 scale mode constants");

_Static_assert(SDL_BUTTON_LEFT == 1 && SDL_BUTTON_MIDDLE == 2 && SDL_BUTTON_RIGHT == 3 && SDL_BUTTON_X1 == 4 && SDL_BUTTON_X2 == 5,
               "Update SDL3.Events mouse button constants");

_Static_assert(SDL_INIT_VIDEO == 0x20 && SDL_INIT_AUDIO == 0x10 && SDL_INIT_EVENTS == 0x4000 && SDL_INIT_GAMEPAD == 0x2000,
               "Update SDL3.Flags init constants");

_Static_assert(SDL_WINDOW_FULLSCREEN == 1 && SDL_WINDOW_HIDDEN == 8 && SDL_WINDOW_BORDERLESS == 0x10 && SDL_WINDOW_RESIZABLE == 0x20 &&
                   SDL_WINDOW_HIGH_PIXEL_DENSITY == 0x2000,
               "Update SDL3.Flags window constants");

int idris_sdl_init(Uint32 flags) {
    return SDL_Init(flags);
}

/* Idris copies the string. Its C backend requires char *, not const char *. */
char* idris_sdl_get_error(void) {
    return (char*)SDL_GetError();
}

int idris_sdl_is_null(const void* ptr) {
    return ptr == NULL;
}

SDL_Renderer* idris_sdl_create_renderer(SDL_Window* window) {
    return SDL_CreateRenderer(window, NULL);
}

SDL_Texture* idris_sdl_create_target_texture(SDL_Renderer* renderer, int width, int height) {
    return SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_TARGET, width, height);
}

int idris_sdl_set_texture_color_mod(SDL_Texture* texture, Uint8 r, Uint8 g, Uint8 b) {
    return SDL_SetTextureColorMod(texture, r, g, b);
}

int idris_sdl_set_texture_alpha_mod(SDL_Texture* texture, Uint8 alpha) {
    return SDL_SetTextureAlphaMod(texture, alpha);
}

int idris_sdl_set_texture_blend_mode(SDL_Texture* texture, Uint32 mode) {
    return SDL_SetTextureBlendMode(texture, mode);
}

int idris_sdl_set_texture_scale_mode(SDL_Texture* texture, int mode) {
    return SDL_SetTextureScaleMode(texture, (SDL_ScaleMode)mode);
}

int idris_sdl_set_render_target(SDL_Renderer* renderer, SDL_Texture* texture) {
    return SDL_SetRenderTarget(renderer, texture);
}

int idris_sdl_reset_render_target(SDL_Renderer* renderer) {
    return SDL_SetRenderTarget(renderer, NULL);
}

int idris_sdl_render_texture(SDL_Renderer* renderer, SDL_Texture* texture) {
    return SDL_RenderTexture(renderer, texture, NULL, NULL);
}

int idris_sdl_render_texture_rect(SDL_Renderer* renderer, SDL_Texture* texture, double x, double y, double w, double h) {
    const SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};
    return SDL_RenderTexture(renderer, texture, NULL, &rect);
}

int idris_sdl_render_texture_source(SDL_Renderer* renderer, SDL_Texture* texture, double x, double y, double w, double h) {
    const SDL_FRect source = {(float)x, (float)y, (float)w, (float)h};
    return SDL_RenderTexture(renderer, texture, &source, NULL);
}

int idris_sdl_render_texture_region(SDL_Renderer* renderer, SDL_Texture* texture, double sx, double sy, double sw, double sh, double dx,
                                    double dy, double dw, double dh) {
    const SDL_FRect source      = {(float)sx, (float)sy, (float)sw, (float)sh};
    const SDL_FRect destination = {(float)dx, (float)dy, (float)dw, (float)dh};
    return SDL_RenderTexture(renderer, texture, &source, &destination);
}

SDL_FPoint* idris_sdl_coordinate_new(void) {
    SDL_FPoint* point = SDL_calloc(1, sizeof(SDL_FPoint));
    if (!point) SDL_SetError("Cannot allocate coordinate buffer");
    return point;
}

void idris_sdl_coordinate_free(SDL_FPoint* point) {
    SDL_free(point);
}

double idris_sdl_coordinate_x(const SDL_FPoint* point) {
    return point->x;
}

double idris_sdl_coordinate_y(const SDL_FPoint* point) {
    return point->y;
}

int idris_sdl_render_coordinates_from_window(SDL_Renderer* renderer, double x, double y, SDL_FPoint* point) {
    return SDL_RenderCoordinatesFromWindow(renderer, (float)x, (float)y, &point->x, &point->y);
}

int idris_sdl_render_coordinates_to_window(SDL_Renderer* renderer, double x, double y, SDL_FPoint* point) {
    return SDL_RenderCoordinatesToWindow(renderer, (float)x, (float)y, &point->x, &point->y);
}

int idris_sdl_set_render_scale(SDL_Renderer* renderer, double x, double y) {
    return SDL_SetRenderScale(renderer, (float)x, (float)y);
}

int idris_sdl_set_render_logical_presentation(SDL_Renderer* renderer, Sint32 w, Sint32 h, int mode) {
    return SDL_SetRenderLogicalPresentation(renderer, w, h, (SDL_RendererLogicalPresentation)mode);
}

int idris_sdl_set_render_viewport(SDL_Renderer* renderer, Sint32 x, Sint32 y, Sint32 w, Sint32 h) {
    const SDL_Rect rect = {x, y, w, h};
    return SDL_SetRenderViewport(renderer, &rect);
}

int idris_sdl_reset_render_viewport(SDL_Renderer* renderer) {
    return SDL_SetRenderViewport(renderer, NULL);
}

int idris_sdl_set_render_clip_rect(SDL_Renderer* renderer, Sint32 x, Sint32 y, Sint32 w, Sint32 h) {
    const SDL_Rect rect = {x, y, w, h};
    return SDL_SetRenderClipRect(renderer, &rect);
}

int idris_sdl_reset_render_clip_rect(SDL_Renderer* renderer) {
    return SDL_SetRenderClipRect(renderer, NULL);
}

int idris_sdl_set_draw_blend_mode(SDL_Renderer* renderer, Uint32 mode) {
    return SDL_SetRenderDrawBlendMode(renderer, mode);
}

int idris_sdl_draw_color(SDL_Renderer* r, Uint8 red, Uint8 g, Uint8 b, Uint8 a) {
    return SDL_SetRenderDrawColor(r, red, g, b, a);
}

int idris_sdl_clear(SDL_Renderer* r) {
    return SDL_RenderClear(r);
}

int idris_sdl_present(SDL_Renderer* r) {
    return SDL_RenderPresent(r);
}

int idris_sdl_fill_rect(SDL_Renderer* r, double x, double y, double w, double h) {
    const SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};
    return SDL_RenderFillRect(r, &rect);
}

int idris_sdl_start_text_input(SDL_Window* window) {
    return SDL_StartTextInput(window);
}

int idris_sdl_stop_text_input(SDL_Window* window) {
    return SDL_StopTextInput(window);
}

int idris_sdl_text_input_active(SDL_Window* window) {
    return SDL_TextInputActive(window);
}

int idris_sdl_set_text_input_area(SDL_Window* window, Sint32 x, Sint32 y, Sint32 w, Sint32 h, Sint32 cursor) {
    const SDL_Rect rect = {x, y, w, h};
    return SDL_SetTextInputArea(window, &rect, cursor);
}

int idris_sdl_clear_text_input_area(SDL_Window* window) {
    return SDL_SetTextInputArea(window, NULL, 0);
}

int idris_sdl_clear_composition(SDL_Window* window) {
    return SDL_ClearComposition(window);
}

SDL_Event* idris_sdl_event_new(void) {
    SDL_Event* event = SDL_calloc(1, sizeof(SDL_Event));
    if (!event) SDL_SetError("Cannot allocate SDL event buffer");
    return event;
}

void idris_sdl_event_free(SDL_Event* event) {
    SDL_free(event);
}

int idris_sdl_poll(SDL_Event* event) {
    return SDL_PollEvent(event);
}

Uint32 idris_sdl_event_type(const SDL_Event* event) {
    return event->type;
}

Uint64 idris_sdl_event_timestamp(const SDL_Event* event) {
    return event->common.timestamp;
}

Uint32 idris_sdl_event_window(const SDL_Event* event) {
    switch (event->type) {
    case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
        return event->window.windowID;
    case SDL_EVENT_TEXT_INPUT:
        return event->text.windowID;
    case SDL_EVENT_TEXT_EDITING:
        return event->edit.windowID;
    case SDL_EVENT_MOUSE_MOTION:
        return event->motion.windowID;
    case SDL_EVENT_MOUSE_WHEEL:
        return event->wheel.windowID;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
    case SDL_EVENT_MOUSE_BUTTON_UP:
        return event->button.windowID;
    default:
        return event->key.windowID;
    }
}

Uint32 idris_sdl_event_scancode(const SDL_Event* event) {
    return (Uint32)event->key.scancode;
}

Uint32 idris_sdl_event_keycode(const SDL_Event* event) {
    return event->key.key;
}

Uint16 idris_sdl_event_modifiers(const SDL_Event* event) {
    return event->key.mod;
}

int idris_sdl_event_repeat(const SDL_Event* event) {
    return event->key.repeat;
}

Uint32 idris_sdl_event_mouse_id(const SDL_Event* event) {
    if (event->type == SDL_EVENT_MOUSE_WHEEL) return event->wheel.which;
    return event->type == SDL_EVENT_MOUSE_MOTION ? event->motion.which : event->button.which;
}

Uint32 idris_sdl_event_mouse_buttons(const SDL_Event* event) {
    return event->motion.state;
}

Uint8 idris_sdl_event_mouse_button(const SDL_Event* event) {
    return event->button.button;
}

Uint8 idris_sdl_event_mouse_clicks(const SDL_Event* event) {
    return event->button.clicks;
}

double idris_sdl_event_mouse_x(const SDL_Event* event) {
    if (event->type == SDL_EVENT_MOUSE_WHEEL) return event->wheel.mouse_x;
    return event->type == SDL_EVENT_MOUSE_MOTION ? event->motion.x : event->button.x;
}

double idris_sdl_event_mouse_y(const SDL_Event* event) {
    if (event->type == SDL_EVENT_MOUSE_WHEEL) return event->wheel.mouse_y;
    return event->type == SDL_EVENT_MOUSE_MOTION ? event->motion.y : event->button.y;
}

double idris_sdl_event_mouse_dx(const SDL_Event* event) {
    return event->motion.xrel;
}

double idris_sdl_event_mouse_dy(const SDL_Event* event) {
    return event->motion.yrel;
}

double idris_sdl_event_wheel_x(const SDL_Event* event) {
    return event->wheel.x;
}

double idris_sdl_event_wheel_y(const SDL_Event* event) {
    return event->wheel.y;
}

Uint32 idris_sdl_event_wheel_direction(const SDL_Event* event) {
    return (Uint32)event->wheel.direction;
}

Sint32 idris_sdl_event_wheel_integer_x(const SDL_Event* event) {
    return event->wheel.integer_x;
}

Sint32 idris_sdl_event_wheel_integer_y(const SDL_Event* event) {
    return event->wheel.integer_y;
}

/* Borrowed until the next poll. Idris copies this string and never writes to it. */
char* idris_sdl_event_text(const SDL_Event* event) {
    const char* text = event->type == SDL_EVENT_TEXT_INPUT ? event->text.text : event->edit.text;
    return (char*)(text ? text : "");
}

Sint32 idris_sdl_event_edit_start(const SDL_Event* event) {
    return event->edit.start;
}

Sint32 idris_sdl_event_edit_length(const SDL_Event* event) {
    return event->edit.length;
}

int idris_sdl_event_kind(const SDL_Event* event) {
    switch (event->type) {
    case SDL_EVENT_QUIT:
        return 1;
    case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
        return 2;
    case SDL_EVENT_KEY_DOWN:
        return 3;
    case SDL_EVENT_KEY_UP:
        return 4;
    case SDL_EVENT_MOUSE_MOTION:
        return 5;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
        return 6;
    case SDL_EVENT_MOUSE_BUTTON_UP:
        return 7;
    case SDL_EVENT_MOUSE_WHEEL:
        return 8;
    case SDL_EVENT_TEXT_INPUT:
        return 9;
    case SDL_EVENT_TEXT_EDITING:
        return 10;
    default:
        return 0;
    }
}
