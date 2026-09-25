#pragma once

#include <SDL3/SDL.h>

char* idris_test_make_bmp(void);
int   idris_test_queue_event(int kind);
int   idris_test_pixel(Uint32 window_id, int x, int y, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
int   idris_test_text_input_area(Uint32 window_id, Sint32 x, Sint32 y, Sint32 w, Sint32 h, Sint32 cursor);
