#include "sdl3.h"

_Static_assert(sizeof(int) == 4, "Bindings require 32-bit C int");

_Static_assert(SDL_VERSION_ATLEAST(3, 2, 12), "Bindings require SDL 3.2.12 or newer");

_Static_assert(SDL_MOUSEWHEEL_NORMAL == 0 && SDL_MOUSEWHEEL_FLIPPED == 1, "Update SDL3 wheel direction decoding");

_Static_assert(SDLK_ESCAPE == 27, "Update SDL3.Events.escapeKey");

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
    default:
        return 0;
    }
}
