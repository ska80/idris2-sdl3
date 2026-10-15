#include "fixtures.h"

#include <SDL3/SDL.h>
#include <stdlib.h>

const char* idris_test_font_path(void) {
    const char* configured = getenv("SDL3_TEST_FONT");

    if (configured && *configured) return configured;

    const char* paths[] = {"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/TTF/DejaVuSans.ttf"};

    for (unsigned i = 0; i < sizeof(paths) / sizeof(paths[0]); ++i) {
        SDL_IOStream* stream = SDL_IOFromFile(paths[i], "rb");

        if (stream) {
            SDL_CloseIO(stream);
            return paths[i];
        }
    }

    return "";
}
