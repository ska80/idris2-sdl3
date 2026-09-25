#include "fixtures.h"
#include <SDL3/SDL.h>

/* Test-only events. Keep these symbols out of the binding library. */
int idris_test_queue_event(int kind) {
    static char text[256];
    SDL_Event   event = {0};
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);
    /* Invalidate text from the previous fixture to test Idris string ownership. */
    text[0] = '\0';

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

    case 6:
        event.type            = SDL_EVENT_MOUSE_MOTION;
        event.motion.windowID = 0x80000001u;
        event.motion.which    = 0xfffffffeu;
        event.motion.state    = 0x80000000u | SDL_BUTTON_LMASK | SDL_BUTTON_RMASK;
        event.motion.x        = 12.5f;
        event.motion.y        = -7.25f;
        event.motion.xrel     = -1.5f;
        event.motion.yrel     = 2.75f;
        break;

    case 7:
    case 8:
    case 9:
        event.type            = kind == 8 ? SDL_EVENT_MOUSE_BUTTON_UP : SDL_EVENT_MOUSE_BUTTON_DOWN;
        event.button.windowID = 0x80000001u;
        event.button.which    = 0xfffffffeu;
        event.button.button   = kind == 9 ? 200 : SDL_BUTTON_RIGHT;
        event.button.down     = kind != 8;
        event.button.clicks   = 2;
        event.button.x        = -0.5f;
        event.button.y        = 100.25f;
        break;

    case 10:
    case 11:
    case 12:
        event.type            = SDL_EVENT_MOUSE_WHEEL;
        event.wheel.windowID  = 0x80000001u;
        event.wheel.which     = 0xfffffffeu;
        event.wheel.x         = kind == 11 ? 2.5f : -2.5f;
        event.wheel.y         = kind == 11 ? -3.75f : 3.75f;
        event.wheel.direction = kind == 10 ? SDL_MOUSEWHEEL_NORMAL : kind == 11 ? SDL_MOUSEWHEEL_FLIPPED : (SDL_MouseWheelDirection)42;
        event.wheel.mouse_x   = -16.5f;
        event.wheel.mouse_y   = 99.25f;
        event.wheel.integer_x = kind == 12 ? SDL_MIN_SINT32 : kind == 11 ? 2 : -2;
        event.wheel.integer_y = kind == 12 ? SDL_MAX_SINT32 : kind == 11 ? -3 : 3;
        break;

    case 13:
    case 15:
    case 17:
        event.type          = SDL_EVENT_TEXT_INPUT;
        event.text.windowID = 0x80000001u;
        if (kind == 13) SDL_strlcpy(text, "héllo 世界 🎮", sizeof(text));
        if (kind == 17) {
            SDL_memset(text, 'x', 200);
            text[200] = '\0';
        }
        event.text.text = text;
        break;

    case 14:
    case 16:
        event.type          = SDL_EVENT_TEXT_EDITING;
        event.edit.windowID = 0x80000001u;
        if (kind == 14) SDL_strlcpy(text, "にほん", sizeof(text));
        event.edit.text   = text;
        event.edit.start  = kind == 14 ? 1 : -1;
        event.edit.length = kind == 14 ? 2 : -1;
        break;

    default:
        return 0;
    }

    return SDL_PeepEvents(&event, 1, SDL_ADDEVENT, 0, 0) == 1;
}
