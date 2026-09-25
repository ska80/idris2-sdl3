/* -*- external-format: utf-8; -*- */

#pragma once

#include <SDL3/SDL.h>

#define IDRIS_SDL3 __attribute__((visibility("default")))

IDRIS_SDL3 int idris_sdl_is_null(const void* ptr);

IDRIS_SDL3 int   idris_sdl_init(Uint32 flags);
IDRIS_SDL3 char* idris_sdl_get_error(void);

IDRIS_SDL3 SDL_Texture* idris_sdl_create_target_texture(SDL_Renderer* renderer, int width, int height);
IDRIS_SDL3 SDL_Texture* idris_sdl_create_streaming_texture(SDL_Renderer* renderer, int width, int height);
/* Size must describe the actual capacity of pixels. No pointer is retained. */
IDRIS_SDL3 int          idris_sdl_update_texture_rgba(SDL_Texture* texture, const void* pixels, Uint64 size, Sint32 pitch);
IDRIS_SDL3 int          idris_sdl_set_texture_color_mod(SDL_Texture* texture, Uint8 r, Uint8 g, Uint8 b);
IDRIS_SDL3 int          idris_sdl_set_texture_alpha_mod(SDL_Texture* texture, Uint8 alpha);
IDRIS_SDL3 int          idris_sdl_set_texture_blend_mode(SDL_Texture* texture, Uint32 mode);
IDRIS_SDL3 int          idris_sdl_set_texture_scale_mode(SDL_Texture* texture, int mode);
IDRIS_SDL3 int          idris_sdl_set_render_target(SDL_Renderer* renderer, SDL_Texture* texture);
IDRIS_SDL3 int          idris_sdl_reset_render_target(SDL_Renderer* renderer);
IDRIS_SDL3 int          idris_sdl_render_texture(SDL_Renderer* renderer, SDL_Texture* texture);
IDRIS_SDL3 int          idris_sdl_render_texture_rect(SDL_Renderer* renderer, SDL_Texture* texture, double x, double y, double w, double h);

/* Size is the actual capacity. Pixels start at the source region, not the texture origin. */
IDRIS_SDL3 int idris_sdl_update_texture_region_rgba(SDL_Texture* texture, Sint32 x, Sint32 y, Sint32 w, Sint32 h, const void* pixels,
                                                    Uint64 size, Sint32 pitch);

IDRIS_SDL3 int idris_sdl_render_texture_source(SDL_Renderer* renderer, SDL_Texture* texture, double x, double y, double w, double h);
IDRIS_SDL3 int idris_sdl_render_texture_region(SDL_Renderer* renderer, SDL_Texture* texture, double sx, double sy, double sw, double sh,
                                               double dx, double dy, double dw, double dh);

IDRIS_SDL3 SDL_FPoint* idris_sdl_coordinate_new(void);
IDRIS_SDL3 void        idris_sdl_coordinate_free(SDL_FPoint* point);
/* Read coordinates only after a successful conversion into this buffer. */
IDRIS_SDL3 double      idris_sdl_coordinate_x(const SDL_FPoint* point);
IDRIS_SDL3 double      idris_sdl_coordinate_y(const SDL_FPoint* point);
IDRIS_SDL3 int         idris_sdl_render_coordinates_from_window(SDL_Renderer* renderer, double x, double y, SDL_FPoint* point);
IDRIS_SDL3 int         idris_sdl_render_coordinates_to_window(SDL_Renderer* renderer, double x, double y, SDL_FPoint* point);

IDRIS_SDL3 int    idris_sdl_set_render_vsync(SDL_Renderer* renderer, Sint64 value);
/* Returns -2 on failure, outside the valid SDL VSync values. */
IDRIS_SDL3 Sint32 idris_sdl_get_render_vsync(SDL_Renderer* renderer);

IDRIS_SDL3 int idris_sdl_set_render_scale(SDL_Renderer* renderer, double x, double y);
IDRIS_SDL3 int idris_sdl_set_render_logical_presentation(SDL_Renderer* renderer, Sint32 w, Sint32 h, int mode);

IDRIS_SDL3 int idris_sdl_set_render_viewport(SDL_Renderer* renderer, Sint32 x, Sint32 y, Sint32 w, Sint32 h);
IDRIS_SDL3 int idris_sdl_reset_render_viewport(SDL_Renderer* renderer);
IDRIS_SDL3 int idris_sdl_set_render_clip_rect(SDL_Renderer* renderer, Sint32 x, Sint32 y, Sint32 w, Sint32 h);
IDRIS_SDL3 int idris_sdl_reset_render_clip_rect(SDL_Renderer* renderer);
IDRIS_SDL3 int idris_sdl_set_draw_blend_mode(SDL_Renderer* renderer, Uint32 mode);

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
