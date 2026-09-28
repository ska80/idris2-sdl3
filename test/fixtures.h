#pragma once

#include "../cbits/sdl3.h"

void idris_test_size_fields(IdrisSDLSize* size, Sint32 width, Sint32 height);
int  idris_test_resize_window(Uint32 identifier, Sint32 width, Sint32 height);

int idris_test_pixel_near(Uint32 window_id, int x, int y, Uint8 r, Uint8 g, Uint8 b, Uint8 a, Uint8 tolerance);

/* 0: no window, 1: window without renderer, 2: window with renderer. */
int idris_test_window_state(Uint32 identifier);

/* Main-thread observations through texture-property cleanup, not freed handles. */
int idris_test_watch_target(Uint32 identifier, int slot);
int idris_test_target_alive(int slot);
/* -1 selects the window. Other slots must contain a live watched texture. */
int idris_test_target_selected(Uint32 identifier, int slot);

Uint32 idris_test_schedule_quit(void);
void   idris_test_cancel_timer(Uint32 timer);

char* idris_test_make_bmp(void);
int   idris_test_queue_event(int kind);
int   idris_test_pixel(Uint32 window_id, int x, int y, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
int   idris_test_text_input_area(Uint32 window_id, Sint32 x, Sint32 y, Sint32 w, Sint32 h, Sint32 cursor);
