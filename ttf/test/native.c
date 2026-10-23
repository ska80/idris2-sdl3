#include "ttf.h"
#include "fixtures.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>

int main(void) {
    assert(SDL_Init(SDL_INIT_VIDEO));
    assert(idris_ttf_init() && idris_ttf_init());

    TTF_Quit();

    const char* path = idris_test_font_path();

    if (!*path) {
        fputs("Set SDL3_TEST_FONT to a TrueType font or install DejaVu Sans\n", stderr);
        return 1;
    }

    assert(!idris_ttf_open_font(path, 0) && !idris_ttf_open_font(path, -1));
    assert(!idris_ttf_open_font(path, NAN) && !idris_ttf_open_font(path, INFINITY));
    assert(!idris_ttf_open_font(path, 1.0e300) && !idris_ttf_open_font(path, 1.0e-300));
    assert(!idris_ttf_open_font("/nonexistent/idris-font.ttf", 18));

    TTF_Font*       font     = idris_ttf_open_font(path, 18);
    SDL_Window*     window   = SDL_CreateWindow("ttf tests", 128, 128, SDL_WINDOW_HIDDEN);
    SDL_Renderer*   renderer = SDL_CreateRenderer(window, "software");
    TTF_TextEngine* engine   = TTF_CreateRendererTextEngine(renderer);

    assert(font && window && renderer && engine);

    char      source[] = "UTF-8: \xce\xbb caf\xc3\xa9";
    TTF_Text* text     = idris_ttf_create_text(engine, font, source);

    assert(text);
    source[0] = 'X';
    assert(text->text[0] == 'U');

    IdrisSDLSize* size = idris_ttf_size_new();

    assert(size && idris_ttf_size(text, size));
    assert(size->width > 0 && size->height > 0);
    assert(idris_ttf_set_text(text, "one two three four five"));
    assert(idris_ttf_size(text, size));

    const int unwrapped_height = size->height;

    assert(idris_ttf_wrap(text, 40) && idris_ttf_size(text, size));
    assert(size->height > unwrapped_height);
    assert(!idris_ttf_wrap(text, 0x80000000u));

    int wrap;

    assert(TTF_GetTextWrapWidth(text, &wrap) && wrap == 40);
    assert(idris_ttf_wrap(text, 0));
    assert(idris_ttf_color(text, 255, 0, 0, 255));
    assert(SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255) && SDL_RenderClear(renderer));
    assert(!idris_ttf_draw(text, NAN, 0) && !idris_ttf_draw(text, 0, INFINITY));
    assert(idris_ttf_draw(text, 1.5, 2.5));

    SDL_Surface* pixels = SDL_RenderReadPixels(renderer, NULL);

    assert(pixels);

    bool drawn = false;

    for (int y = 0; y < pixels->h; ++y)
        for (int x = 0; x < pixels->w; ++x) {
            Uint8 r, g, b, a;
            assert(SDL_ReadSurfacePixel(pixels, x, y, &r, &g, &b, &a));
            assert(g == 0 && b == 0);
            drawn |= r != 0;
        }

    assert(drawn);

    SDL_DestroySurface(pixels);

    assert(!idris_ttf_size(text, NULL));
    assert(idris_ttf_set_text(text, "") && idris_ttf_size(text, size));
    assert(size->width == 0);

    TTF_DestroyText(text);
    SDL_free(size);
    TTF_DestroyRendererTextEngine(engine);
    TTF_CloseFont(font);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    TTF_Quit();
    SDL_Quit();

    puts("TTF native tests passed");
}
