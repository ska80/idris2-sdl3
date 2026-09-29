#pragma once

#include <SDL3/SDL.h>

Uint32 idris_test_attach_gamepad(void);
int    idris_test_gamepad_input(Sint16 axis, int down);
int    idris_test_detach_gamepad(Uint32 identifier);
Uint32 idris_test_gamepad_rumble(void);
int    idris_test_subset_event(int kind);
