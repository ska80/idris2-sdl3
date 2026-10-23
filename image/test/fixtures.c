#define _POSIX_C_SOURCE 200809L

#include "fixtures.h"

#include <SDL3_image/SDL_image.h>

#include <stdlib.h>
#include <unistd.h>

const char* idris_test_make_image(Sint32 jpeg) {
    static char path[64];
    SDL_strlcpy(path, "/tmp/idris2-sdl3-image-XXXXXX", sizeof(path));
    int fd = mkstemp(path);

    if (fd < 0) return "";

    close(fd);
    SDL_Surface* surface = SDL_CreateSurface(3, 2, SDL_PIXELFORMAT_RGBA32);
    bool         saved   = surface && SDL_FillSurfaceRect(surface, NULL, SDL_MapSurfaceRGBA(surface, 100, 150, 200, 128)) &&
                 (jpeg ? IMG_SaveJPG(surface, path, 100) : IMG_SavePNG(surface, path));
    SDL_DestroySurface(surface);

    if (!saved) {
        unlink(path);

        return "";
    }

    return path;
}
