#include "extended_fixtures.h"

void idris_test_error(const char* message) {
    SDL_SetError("%s", message);
}

int idris_test_render_reset(Sint32 device) {
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);
    SDL_Event event = {0};

    event.render.type      = device ? SDL_EVENT_RENDER_DEVICE_RESET : SDL_EVENT_RENDER_TARGETS_RESET;
    event.render.timestamp = 0x100000002ull;
    event.render.windowID  = 0xffffffffu;

    return SDL_PeepEvents(&event, 1, SDL_ADDEVENT, 0, 0);
}
