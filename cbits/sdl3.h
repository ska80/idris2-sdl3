/* -*- external-format: utf-8; -*- */

#pragma once

#include <SDL3/SDL.h>

#define IDRIS_SDL3 __attribute__((visibility("default")))

IDRIS_SDL3 int           idris_sdl_init(Uint32 flags);
IDRIS_SDL3 char*         idris_sdl_get_error(void);
IDRIS_SDL3 int           idris_sdl_is_null(const void* ptr);
IDRIS_SDL3 SDL_Renderer* idris_sdl_create_renderer(SDL_Window* window);
IDRIS_SDL3 int           idris_sdl_draw_color(SDL_Renderer* renderer, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
IDRIS_SDL3 int           idris_sdl_clear(SDL_Renderer* renderer);
IDRIS_SDL3 int           idris_sdl_present(SDL_Renderer* renderer);
IDRIS_SDL3 int           idris_sdl_fill_rect(SDL_Renderer* renderer, double x, double y, double w, double h);
IDRIS_SDL3 SDL_Event*    idris_sdl_event_new(void);
IDRIS_SDL3 void          idris_sdl_event_free(SDL_Event* event);
IDRIS_SDL3 int           idris_sdl_poll(SDL_Event* event);
IDRIS_SDL3 Uint32        idris_sdl_event_type(const SDL_Event* event);
IDRIS_SDL3 int           idris_sdl_event_kind(const SDL_Event* event);
IDRIS_SDL3 Uint64        idris_sdl_event_timestamp(const SDL_Event* event);
/* Window access requires a close or keyboard event. Key access requires a keyboard event. */
IDRIS_SDL3 Uint32        idris_sdl_event_window(const SDL_Event* event);
IDRIS_SDL3 Uint32        idris_sdl_event_scancode(const SDL_Event* event);
IDRIS_SDL3 Uint32        idris_sdl_event_keycode(const SDL_Event* event);
IDRIS_SDL3 Uint16        idris_sdl_event_modifiers(const SDL_Event* event);
IDRIS_SDL3 int           idris_sdl_event_repeat(const SDL_Event* event);
