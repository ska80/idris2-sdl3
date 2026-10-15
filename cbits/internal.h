/* -*- external-format: utf-8; -*- */

#pragma once

#include <SDL3/SDL_stdinc.h>

#include <float.h>

/* ABI checks shared by adapters. No error mutation or native allocation. */
static inline bool idris_sdl_fits_float(double value) {
    return value >= -FLT_MAX && value <= FLT_MAX;
}

/* Subtraction avoids overflow even when offset/count use the full Uint64 range. */
static inline bool idris_sdl_buffer_range(Uint64 capacity, Uint64 offset, Uint64 count) {
    return offset <= capacity && count <= capacity - offset && offset <= SIZE_MAX && count <= SIZE_MAX - (size_t)offset;
}
