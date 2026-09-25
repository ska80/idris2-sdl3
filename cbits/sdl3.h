/* -*- external-format: utf-8; -*- */

#pragma once

#include <SDL3/SDL.h>

#define IDRIS_SDL3 __attribute__((visibility("default")))

IDRIS_SDL3 int idris_sdl_is_null(const void* ptr);

IDRIS_SDL3 int   idris_sdl_init(Uint32 flags);
IDRIS_SDL3 char* idris_sdl_get_error(void);

IDRIS_SDL3 SDL_Texture* idris_sdl_create_target_texture(SDL_Renderer* renderer, int width, int height);
IDRIS_SDL3 int          idris_sdl_set_render_target(SDL_Renderer* renderer, SDL_Texture* texture);
IDRIS_SDL3 int          idris_sdl_reset_render_target(SDL_Renderer* renderer);
IDRIS_SDL3 int          idris_sdl_render_texture(SDL_Renderer* renderer, SDL_Texture* texture);
IDRIS_SDL3 int          idris_sdl_render_texture_rect(SDL_Renderer* renderer, SDL_Texture* texture, double x, double y, double w, double h);

IDRIS_SDL3 SDL_Renderer* idris_sdl_create_renderer(SDL_Window* window);
IDRIS_SDL3 int           idris_sdl_draw_color(SDL_Renderer* renderer, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
IDRIS_SDL3 int           idris_sdl_clear(SDL_Renderer* renderer);
IDRIS_SDL3 int           idris_sdl_present(SDL_Renderer* renderer);
IDRIS_SDL3 int           idris_sdl_fill_rect(SDL_Renderer* renderer, double x, double y, double w, double h);

IDRIS_SDL3 int idris_sdl_start_text_input(SDL_Window* window);
IDRIS_SDL3 int idris_sdl_stop_text_input(SDL_Window* window);
IDRIS_SDL3 int idris_sdl_text_input_active(SDL_Window* window);
IDRIS_SDL3 int idris_sdl_set_text_input_area(SDL_Window* window, Sint32 x, Sint32 y, Sint32 w, Sint32 h, Sint32 cursor);
IDRIS_SDL3 int idris_sdl_clear_text_input_area(SDL_Window* window);
IDRIS_SDL3 int idris_sdl_clear_composition(SDL_Window* window);

IDRIS_SDL3 SDL_Event* idris_sdl_event_new(void);
IDRIS_SDL3 void       idris_sdl_event_free(SDL_Event* event);
IDRIS_SDL3 int        idris_sdl_poll(SDL_Event* event);
IDRIS_SDL3 Uint32     idris_sdl_event_type(const SDL_Event* event);
IDRIS_SDL3 int        idris_sdl_event_kind(const SDL_Event* event);
IDRIS_SDL3 Uint64     idris_sdl_event_timestamp(const SDL_Event* event);

/* Window access requires a close, keyboard, text input, text editing, or supported mouse event.
 * Key access requires a keyboard event. */
IDRIS_SDL3 Uint32 idris_sdl_event_window(const SDL_Event* event);
IDRIS_SDL3 Uint32 idris_sdl_event_scancode(const SDL_Event* event);
IDRIS_SDL3 Uint32 idris_sdl_event_keycode(const SDL_Event* event);
IDRIS_SDL3 Uint16 idris_sdl_event_modifiers(const SDL_Event* event);
IDRIS_SDL3 int    idris_sdl_event_repeat(const SDL_Event* event);

/* Requires a mouse motion, mouse button, or mouse wheel event. */
IDRIS_SDL3 Uint32 idris_sdl_event_mouse_id(const SDL_Event* event);
IDRIS_SDL3 double idris_sdl_event_mouse_x(const SDL_Event* event);
IDRIS_SDL3 double idris_sdl_event_mouse_y(const SDL_Event* event);

/* Requires a mouse motion event. */
IDRIS_SDL3 Uint32 idris_sdl_event_mouse_buttons(const SDL_Event* event);
IDRIS_SDL3 double idris_sdl_event_mouse_dx(const SDL_Event* event);
IDRIS_SDL3 double idris_sdl_event_mouse_dy(const SDL_Event* event);

/* Requires a mouse button event. */
IDRIS_SDL3 Uint8 idris_sdl_event_mouse_button(const SDL_Event* event);
IDRIS_SDL3 Uint8 idris_sdl_event_mouse_clicks(const SDL_Event* event);

/* Requires a mouse wheel event. */
IDRIS_SDL3 double idris_sdl_event_wheel_x(const SDL_Event* event);
IDRIS_SDL3 double idris_sdl_event_wheel_y(const SDL_Event* event);
IDRIS_SDL3 Uint32 idris_sdl_event_wheel_direction(const SDL_Event* event);
IDRIS_SDL3 Sint32 idris_sdl_event_wheel_integer_x(const SDL_Event* event);
IDRIS_SDL3 Sint32 idris_sdl_event_wheel_integer_y(const SDL_Event* event);

/* Requires a text input or text editing event. Returns borrowed, read-only text. */
IDRIS_SDL3 char*  idris_sdl_event_text(const SDL_Event* event);
/* Requires a text editing event. */
IDRIS_SDL3 Sint32 idris_sdl_event_edit_start(const SDL_Event* event);
IDRIS_SDL3 Sint32 idris_sdl_event_edit_length(const SDL_Event* event);
