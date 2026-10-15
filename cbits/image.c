/* -*- external-format: utf-8; -*- */

#include "image.h"

SDL_Surface* idris_image_load_io(SDL_IOStream* stream) {
    return IMG_Load_IO(stream, false);
}

SDL_Texture* idris_image_load_texture_io(SDL_Renderer* renderer, SDL_IOStream* stream) {
    return IMG_LoadTexture_IO(renderer, stream, false);
}
