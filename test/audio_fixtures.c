#define _POSIX_C_SOURCE 200809L

#include "audio_fixtures.h"

#include <SDL3/SDL.h>

#include <stdlib.h>
#include <unistd.h>

const char* idris_test_make_wav(void) {
    static char        path[64];
    static const Uint8 bytes[] = {'R', 'I', 'F', 'F', 44, 0, 0,  0,  'W', 'A', 'V', 'E', 'f', 'm', 't', ' ', 16, 0,
                                  0,   0,   1,   0,   1,  0, 64, 31, 0,   0,   128, 62,  0,   0,   2,   0,   16, 0,
                                  'd', 'a', 't', 'a', 8,  0, 0,  0,  0,   0,   0,   16,  0,   240, 255, 127};

    SDL_strlcpy(path, "/tmp/idris2-sdl3-audio-XXXXXX", sizeof(path));

    int fd = mkstemp(path);
    if (fd < 0) return "";

    close(fd);

    if (!SDL_SaveFile(path, bytes, sizeof(bytes))) {
        unlink(path);

        return "";
    }

    return path;
}
