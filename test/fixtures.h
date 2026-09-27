#pragma once

#include <SDL3/SDL.h>

int idris_test_pixel_near(Uint32 window_id, int x, int y, Uint8 r, Uint8 g, Uint8 b, Uint8 a, Uint8 tolerance);

/* 0: no window, 1: window without renderer, 2: window with renderer. */
int idris_test_window_state(Uint32 identifier);

Uint32 idris_test_schedule_quit(void);
void   idris_test_cancel_timer(Uint32 timer);

char* idris_test_make_bmp(void);
int   idris_test_queue_event(int kind);
int   idris_test_pixel(Uint32 window_id, int x, int y, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
int   idris_test_text_input_area(Uint32 window_id, Sint32 x, Sint32 y, Sint32 w, Sint32 h, Sint32 cursor);
