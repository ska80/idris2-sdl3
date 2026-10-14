#pragma once

#include "core.h"

#include <SDL3_ttf/SDL_ttf.h>

#define IDRIS_TTF __attribute__((visibility("default")))

IDRIS_TTF int           idris_ttf_init(void);
IDRIS_TTF TTF_Font*     idris_ttf_open_font(const char* path, double size);
IDRIS_TTF TTF_Text*     idris_ttf_create_text(TTF_TextEngine* engine, TTF_Font* font, const char* text);
IDRIS_TTF int           idris_ttf_set_text(TTF_Text* text, const char* value);
IDRIS_TTF int           idris_ttf_wrap(TTF_Text* text, Uint32 width);
IDRIS_TTF int           idris_ttf_color(TTF_Text* text, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
IDRIS_TTF int           idris_ttf_draw(TTF_Text* text, double x, double y);
IDRIS_TTF IdrisSDLSize* idris_ttf_size_new(void);
IDRIS_TTF int           idris_ttf_size(TTF_Text* text, IdrisSDLSize* size);
