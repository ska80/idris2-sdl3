#include "subset_fixtures.h"

static SDL_Joystick* joystick;
static Uint32 rumble;
static bool SDLCALL record_rumble(void* userdata, Uint16 low, Uint16 high) {
    (void)userdata;
    rumble = ((Uint32)low << 16) | high;
    return true;
}
Uint32 idris_test_attach_gamepad(void) {
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
    SDL_VirtualJoystickDesc desc;
    SDL_INIT_INTERFACE(&desc);
    desc.type = SDL_JOYSTICK_TYPE_GAMEPAD;
    desc.naxes = 6;
    desc.nbuttons = 21;
    desc.axis_mask = 0x3f;
    desc.button_mask = 0x1fffff;
    desc.name = "Idris virtual gamepad";
    desc.Rumble = record_rumble;
    SDL_JoystickID id = SDL_AttachVirtualJoystick(&desc);
    if (!id) return 0;
    joystick = SDL_OpenJoystick(id);
    if (!joystick) { SDL_DetachVirtualJoystick(id); return 0; }
    rumble = 0;
    return id;
}
int idris_test_gamepad_input(Sint16 axis, int down) {
    if (!SDL_SetJoystickVirtualAxis(joystick, 0, axis) ||
        !SDL_SetJoystickVirtualButton(joystick, 0, down != 0)) return 0;
    SDL_UpdateGamepads();
    return 1;
}
int idris_test_detach_gamepad(Uint32 identifier) {
    if (!joystick) return 1;
    int result = SDL_DetachVirtualJoystick(identifier);
    SDL_CloseJoystick(joystick);
    joystick = NULL;
    return result;
}
Uint32 idris_test_gamepad_rumble(void) { return rumble; }

int idris_test_subset_event(int kind) {
    static const Uint32 types[] = {
        SDL_EVENT_GAMEPAD_ADDED, SDL_EVENT_GAMEPAD_REMOVED, SDL_EVENT_GAMEPAD_REMAPPED,
        SDL_EVENT_GAMEPAD_AXIS_MOTION, SDL_EVENT_GAMEPAD_BUTTON_DOWN, SDL_EVENT_GAMEPAD_BUTTON_UP,
        SDL_EVENT_DROP_FILE, SDL_EVENT_DROP_TEXT, SDL_EVENT_DROP_BEGIN, SDL_EVENT_DROP_COMPLETE,
        SDL_EVENT_DROP_POSITION
    };
    if (kind < 0 || kind > 10) return 0;
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);
    SDL_Event e = {0};
    e.type = types[kind];
    e.common.timestamp = 0x100000002ull;
    if (kind <= 2) e.gdevice.which = 0x80000001u;
    else if (kind == 3) {
        e.gaxis.which = 0x80000001u;
        e.gaxis.axis = 255; /* Unknown codes must survive decoding. */
        e.gaxis.value = -32768;
    } else if (kind <= 5) {
        e.gbutton.which = 0x80000001u;
        e.gbutton.button = 255;
        e.gbutton.down = kind == 4;
    } else {
        e.drop.windowID = 0xffffffffu;
        e.drop.x = -12.5f;
        e.drop.y = 100.25f;
        e.drop.source = "source Ω";
        e.drop.data = kind == 6 ? "/tmp/雪 file.wav" : kind == 7 ? "drop λ text" : NULL;
    }
    return SDL_PeepEvents(&e, 1, SDL_ADDEVENT, SDL_EVENT_FIRST, SDL_EVENT_LAST) == 1;
}
