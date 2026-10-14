#include "ttf.h"

#include <float.h>

int idris_ttf_init(void) {
    return TTF_Init();
}

TTF_Font* idris_ttf_open_font(const char* path, double size) {
    if (!(size > 0 && size <= FLT_MAX) || (float)size == 0) {
        SDL_SetError("Font size must be finite, positive, and fit a positive float");

        return NULL;
    }

    return TTF_OpenFont(path, (float)size);
}

TTF_Text* idris_ttf_create_text(TTF_TextEngine* engine, TTF_Font* font, const char* text) {
    return TTF_CreateText(engine, font, text, 0);
}

int idris_ttf_set_text(TTF_Text* text, const char* value) {
    return TTF_SetTextString(text, value, 0);
}

int idris_ttf_wrap(TTF_Text* text, Uint32 width) {
    if (width > SDL_MAX_SINT32) return SDL_SetError("Text wrap width exceeds signed 32-bit range");

    return TTF_SetTextWrapWidth(text, (int)width);
}

int idris_ttf_color(TTF_Text* text, Uint8 r, Uint8 g, Uint8 b, Uint8 a) {
    return TTF_SetTextColor(text, r, g, b, a);
}

int idris_ttf_draw(TTF_Text* text, double x, double y) {
    if (!(x >= -FLT_MAX && x <= FLT_MAX && y >= -FLT_MAX && y <= FLT_MAX))
        return SDL_SetError("Text position must be finite and fit SDL floats");

    return TTF_DrawRendererText(text, (float)x, (float)y);
}

IdrisSDLSize* idris_ttf_size_new(void) {
    IdrisSDLSize* size = SDL_calloc(1, sizeof(*size));

    if (!size) SDL_SetError("Cannot allocate text size storage");

    return size;
}

int idris_ttf_size(TTF_Text* text, IdrisSDLSize* size) {
    if (!size) return SDL_SetError("Text size storage is null");

    int width, height;

    if (!TTF_GetTextSize(text, &width, &height)) return 0;

    if (width < 0 || height < 0) return SDL_SetError("SDL_ttf returned negative text dimensions");

    size->width  = width;
    size->height = height;

    return 1;
}
