#include "image.h"
#include "image_fixtures.h"

#include <assert.h>
#include <stdio.h>
#include <unistd.h>

int main(void) {
    assert(SDL_Init(SDL_INIT_VIDEO));

    SDL_Window*   window   = SDL_CreateWindow("image tests", 8, 8, SDL_WINDOW_HIDDEN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, "software");

    assert(window && renderer);

    for (int jpeg = 0; jpeg <= 1; ++jpeg) {
        const char* path = idris_test_make_image(jpeg);

        assert(*path);

        SDL_IOStream* io = SDL_IOFromFile(path, "rb");

        assert(io);

        SDL_Surface* surface = idris_image_load_io(io);

        assert(surface && surface->w == 3 && surface->h == 2);

        Uint8 r, g, b, a;

        assert(SDL_ReadSurfacePixel(surface, 2, 1, &r, &g, &b, &a));
        assert(r >= 98 && r <= 102 && g >= 148 && g <= 152 && b >= 198 && b <= 202);
        assert(a == (jpeg ? 255 : 128));
        assert(SDL_SeekIO(io, 0, SDL_IO_SEEK_SET) == 0);

        SDL_Texture* texture = idris_image_load_texture_io(renderer, io);

        assert(texture && texture->w == 3 && texture->h == 2);
        assert(SDL_CloseIO(io));

        SDL_DestroySurface(surface);

        assert(SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_NONE));
        assert(SDL_RenderTexture(renderer, texture, NULL, NULL));

        SDL_Surface* pixels = SDL_RenderReadPixels(renderer, NULL);

        assert(pixels && SDL_ReadSurfacePixel(pixels, 0, 0, &r, &g, &b, &a));
        assert(g >= 148 && g <= 152);

        SDL_DestroySurface(pixels);
        SDL_DestroyTexture(texture);

        assert(unlink(path) == 0);
    }

    SDL_IOStream* bad = SDL_IOFromConstMem("bad", 3);

    assert(bad && !idris_image_load_io(bad));
    assert(SDL_GetIOSize(bad) == 3 && SDL_SeekIO(bad, 0, SDL_IO_SEEK_SET) == 0);
    assert(!idris_image_load_texture_io(renderer, bad));
    assert(SDL_GetIOSize(bad) == 3 && SDL_CloseIO(bad));
    assert(!idris_image_load_io(NULL));
    assert(!IMG_Load("/nonexistent/idris-image"));

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    puts("Image native tests passed");
}
