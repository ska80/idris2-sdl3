#include "sdl3.h"

_Static_assert(sizeof(int) == 4, "Bindings require 32-bit C int");

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
    default:
        return 0;
    }
}
