#include "fixtures.h"
#include <SDL3/SDL.h>

/* Test-only events. Keep these symbols out of the binding library. */
int idris_test_queue_event(int kind) {
    SDL_Event event = {0};
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);

    event.common.timestamp = SDL_UINT64_C(0x100000002);

    switch (kind) {
    case 1:
        event.type = SDL_EVENT_QUIT;

        break;

    case 2:
        event.type            = SDL_EVENT_WINDOW_CLOSE_REQUESTED;
        event.window.windowID = 0x80000001u;

        break;

    case 3:

    case 4:
        event.type         = kind == 3 ? SDL_EVENT_KEY_DOWN : SDL_EVENT_KEY_UP;
        event.key.windowID = 0x80000001u;
        event.key.scancode = SDL_SCANCODE_ESCAPE;
        event.key.key      = SDLK_ESCAPE;
        event.key.mod      = SDL_KMOD_LSHIFT | SDL_KMOD_RCTRL;
        event.key.down     = kind == 3;
        event.key.repeat   = kind == 3;

        break;

    case 5:
        event.type = SDL_EVENT_USER;

        break;

    default:
        return 0;
    }

    return SDL_PeepEvents(&event, 1, SDL_ADDEVENT, 0, 0) == 1;
}
