#include "sdl3.h"

#include <assert.h>
#include <stdio.h>

int main(void) {
    assert(idris_sdl_init(SDL_INIT_EVENTS) == 1);
    assert(idris_sdl_is_null(NULL) == 1);
    assert(idris_sdl_create_renderer(NULL) == NULL);
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
    assert(idris_sdl_render_texture(NULL, NULL) == 0);
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

    SDL_FPoint* coordinates = idris_sdl_coordinate_new();
    assert(coordinates);
    assert(idris_sdl_render_coordinates_from_window(NULL, 1.5, 2.5, coordinates) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    assert(idris_sdl_render_coordinates_to_window(NULL, 1.5, 2.5, coordinates) == 0);
    assert(idris_sdl_get_error()[0] != '\0');
    idris_sdl_coordinate_free(coordinates);

    SDL_Event* buffer = idris_sdl_event_new();

    assert(buffer && !idris_sdl_is_null(buffer));

    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);

    assert(idris_sdl_poll(buffer) == 0);

    const Uint32 types[] = {SDL_EVENT_QUIT, SDL_EVENT_WINDOW_CLOSE_REQUESTED, SDL_EVENT_KEY_DOWN, SDL_EVENT_KEY_UP, SDL_EVENT_USER};

    for (int i = 0; i < 5; ++i) {
        SDL_Event event = {0};
        event.type      = types[i];

        assert(SDL_PushEvent(&event));
        assert(idris_sdl_poll(buffer) == 1);
        assert(idris_sdl_event_type(buffer) == types[i]);
        assert(idris_sdl_event_kind(buffer) == (i == 4 ? 0 : i + 1));

        SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);
    }

    idris_sdl_event_free(buffer);

    SDL_Quit();

    puts("Native event tests passed");

    return 0;
}
