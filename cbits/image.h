#pragma once

#include <SDL3_image/SDL_image.h>

#define IDRIS_IMAGE __attribute__((visibility("default")))

/* Borrow the stream for this call. Never close it, including on failure. */
IDRIS_IMAGE SDL_Surface* idris_image_load_io(SDL_IOStream* stream);
IDRIS_IMAGE SDL_Texture* idris_image_load_texture_io(SDL_Renderer* renderer, SDL_IOStream* stream);
