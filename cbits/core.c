/* -*- external-format: utf-8; -*- */

#include "core.h"

#include <float.h>
#include <stddef.h>

_Static_assert(sizeof(int) == 4, "Bindings require 32-bit C int");

_Static_assert(sizeof(SDL_WindowFlags) == 8, "Bindings require 64-bit SDL window flags");

_Static_assert(SDL_WINDOW_INPUT_FOCUS == 0x200, "Keyboard-focus mask must match the Idris query");

_Static_assert(SDL_WINDOW_ALWAYS_ON_TOP == 0x10000, "Always-on-top mask must match the Idris flag");

_Static_assert(SDL_FLASH_CANCEL == 0 && SDL_FLASH_BRIEFLY == 1 && SDL_FLASH_UNTIL_FOCUSED == 2, "Flash operation codes must match Idris");

_Static_assert(SDL_WINDOW_MINIMIZED == 0x40, "Minimized mask must match the Idris query");

_Static_assert(SDL_WINDOW_MAXIMIZED == 0x80, "Maximized mask must match the Idris query");

_Static_assert(sizeof(SDL_ScaleMode) == 4, "Bindings require 32-bit SDL scale mode codes");

_Static_assert(sizeof(SDL_BlendMode) == 4, "Bindings require 32-bit SDL blend mode codes");

_Static_assert(sizeof(SDL_BlendFactor) == 4 && sizeof(SDL_BlendOperation) == 4, "Bindings require 32-bit SDL blend factors and operations");

_Static_assert(SDL_BLENDFACTOR_ZERO == 1 && SDL_BLENDFACTOR_ONE == 2 && SDL_BLENDFACTOR_SRC_COLOR == 3 &&
                   SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR == 4 && SDL_BLENDFACTOR_SRC_ALPHA == 5 && SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA == 6 &&
                   SDL_BLENDFACTOR_DST_COLOR == 7 && SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR == 8 && SDL_BLENDFACTOR_DST_ALPHA == 9 &&
                   SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA == 10,
               "Update SDL3 blend factor constants");

_Static_assert(SDL_BLENDOPERATION_ADD == 1 && SDL_BLENDOPERATION_SUBTRACT == 2 && SDL_BLENDOPERATION_REV_SUBTRACT == 3 &&
                   SDL_BLENDOPERATION_MINIMUM == 4 && SDL_BLENDOPERATION_MAXIMUM == 5,
               "Update SDL3 blend operation constants");

_Static_assert(sizeof(SDL_PixelFormat) == 4 && sizeof(SDL_Texture) == 16 && offsetof(SDL_Texture, format) == 0 &&
                   offsetof(SDL_Texture, w) == 4 && offsetof(SDL_Texture, h) == 8 && offsetof(SDL_Texture, refcount) == 12,
               "Update SDL3.Raw.NativeTexture for this SDL_Texture layout");

_Static_assert(SDL_VERSION_ATLEAST(3, 2, 12), "Bindings require SDL 3.2.12 or newer");

_Static_assert(SDL_MOUSEWHEEL_NORMAL == 0 && SDL_MOUSEWHEEL_FLIPPED == 1, "Update SDL3 wheel direction decoding");

_Static_assert(SDLK_ESCAPE == 27, "Update SDL3.Events.escapeKey");

_Static_assert(SDL_FLIP_NONE == 0 && SDL_FLIP_HORIZONTAL == 1 && SDL_FLIP_VERTICAL == 2, "Update SDL3 texture flip constants");

_Static_assert(SDL_RENDERER_VSYNC_DISABLED == 0 && SDL_RENDERER_VSYNC_ADAPTIVE == -1, "Update SDL3 VSync constants");

_Static_assert(SDL_LOGICAL_PRESENTATION_DISABLED == 0 && SDL_LOGICAL_PRESENTATION_STRETCH == 1 && SDL_LOGICAL_PRESENTATION_LETTERBOX == 2 &&
                   SDL_LOGICAL_PRESENTATION_OVERSCAN == 3 && SDL_LOGICAL_PRESENTATION_INTEGER_SCALE == 4,
               "Update SDL3 logical presentation constants");

_Static_assert(SDL_BLENDMODE_NONE == 0 && SDL_BLENDMODE_BLEND == 1 && SDL_BLENDMODE_BLEND_PREMULTIPLIED == 0x10 && SDL_BLENDMODE_ADD == 2 &&
                   SDL_BLENDMODE_ADD_PREMULTIPLIED == 0x20 && SDL_BLENDMODE_MOD == 4 && SDL_BLENDMODE_MUL == 8,
               "Update SDL3 blend mode constants");

_Static_assert(SDL_SCALEMODE_NEAREST == 0 && SDL_SCALEMODE_LINEAR == 1, "Update SDL3 scale mode constants");

_Static_assert(SDL_BUTTON_LEFT == 1 && SDL_BUTTON_MIDDLE == 2 && SDL_BUTTON_RIGHT == 3 && SDL_BUTTON_X1 == 4 && SDL_BUTTON_X2 == 5,
               "Update SDL3.Events mouse button constants");

_Static_assert(SDL_INIT_VIDEO == 0x20 && SDL_INIT_AUDIO == 0x10 && SDL_INIT_EVENTS == 0x4000 && SDL_INIT_GAMEPAD == 0x2000,
               "Update SDL3.Flags init constants");

_Static_assert(SDL_WINDOW_FULLSCREEN == 1 && SDL_WINDOW_HIDDEN == 8 && SDL_WINDOW_BORDERLESS == 0x10 && SDL_WINDOW_RESIZABLE == 0x20 &&
                   SDL_WINDOW_HIGH_PIXEL_DENSITY == 0x2000,
               "Update SDL3.Flags window constants");

int idris_sdl_init(Uint32 flags) {
    return SDL_Init(flags);
}

/* Idris copies the borrowed SDL string. */
char* idris_sdl_get_error(void) {
    return (char*)SDL_GetError();
}

int idris_sdl_is_null(const void* ptr) {
    return ptr == NULL;
}

double idris_sdl_get_window_pixel_density(SDL_Window* window) {
    return (double)SDL_GetWindowPixelDensity(window);
}

double idris_sdl_get_window_display_scale(SDL_Window* window) {
    return (double)SDL_GetWindowDisplayScale(window);
}

int idris_sdl_minimize_window(SDL_Window* window) {
    return SDL_MinimizeWindow(window);
}

int idris_sdl_maximize_window(SDL_Window* window) {
    return SDL_MaximizeWindow(window);
}

int idris_sdl_restore_window(SDL_Window* window) {
    return SDL_RestoreWindow(window);
}

int idris_sdl_set_window_mouse_grab(SDL_Window* window, Sint32 grabbed) {
    return SDL_SetWindowMouseGrab(window, grabbed != 0);
}

int idris_sdl_get_window_mouse_grab(SDL_Window* window) {
    return SDL_GetWindowMouseGrab(window);
}

int idris_sdl_set_window_opacity(SDL_Window* window, double opacity) {
    if (opacity != opacity) return SDL_SetError("Window opacity must not be NaN");

    /* Apply SDL's range clamp before narrowing, including values beyond float range. */
    opacity = SDL_clamp(opacity, 0.0, 1.0);

    return SDL_SetWindowOpacity(window, (float)opacity);
}

double idris_sdl_get_window_opacity(SDL_Window* window) {
    return (double)SDL_GetWindowOpacity(window);
}

int idris_sdl_flash_window(SDL_Window* window, Sint32 operation) {
    return SDL_FlashWindow(window, (SDL_FlashOperation)operation);
}

int idris_sdl_set_window_always_on_top(SDL_Window* window, Sint32 enabled) {
    return SDL_SetWindowAlwaysOnTop(window, enabled != 0);
}

int idris_sdl_raise_window(SDL_Window* window) {
    return SDL_RaiseWindow(window);
}

int idris_sdl_set_window_fullscreen(SDL_Window* window, Sint32 fullscreen) {
    return SDL_SetWindowFullscreen(window, fullscreen != 0);
}

int idris_sdl_set_window_bordered(SDL_Window* window, Sint32 bordered) {
    return SDL_SetWindowBordered(window, bordered != 0);
}

int idris_sdl_set_window_resizable(SDL_Window* window, Sint32 resizable) {
    return SDL_SetWindowResizable(window, resizable != 0);
}

int idris_sdl_show_window(SDL_Window* window) {
    return SDL_ShowWindow(window);
}

int idris_sdl_hide_window(SDL_Window* window) {
    return SDL_HideWindow(window);
}

int idris_sdl_set_window_title(SDL_Window* window, const char* title) {
    return SDL_SetWindowTitle(window, title);
}

int idris_sdl_set_window_size(SDL_Window* window, Sint32 width, Sint32 height) {
    return SDL_SetWindowSize(window, width, height);
}

int idris_sdl_sync_window(SDL_Window* window) {
    return SDL_SyncWindow(window);
}

IdrisSDLSize* idris_sdl_size_new(void) {
    IdrisSDLSize* size = SDL_calloc(1, sizeof(*size));

    if (!size) SDL_SetError("Cannot allocate window size storage");

    return size;
}

void idris_sdl_size_free(IdrisSDLSize* size) {
    SDL_free(size);
}

static int valid_size(const IdrisSDLSize* size) {
    if (size->width < 0 || size->height < 0) return SDL_SetError("SDL returned negative dimensions");

    return 1;
}

int idris_sdl_get_window_size(SDL_Window* window, IdrisSDLSize* size) {
    if (!size) return SDL_SetError("Window size storage is null");

    if (!SDL_GetWindowSize(window, &size->width, &size->height)) return 0;

    return valid_size(size);
}

int idris_sdl_get_window_size_pixels(SDL_Window* window, IdrisSDLSize* size) {
    if (!size) return SDL_SetError("Window size storage is null");

    if (!SDL_GetWindowSizeInPixels(window, &size->width, &size->height)) return 0;

    return valid_size(size);
}

SDL_Renderer* idris_sdl_create_renderer(SDL_Window* window) {
    return SDL_CreateRenderer(window, NULL);
}

SDL_Texture* idris_sdl_create_target_texture(SDL_Renderer* renderer, int width, int height) {
    return SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_TARGET, width, height);
}

SDL_Texture* idris_sdl_create_streaming_texture(SDL_Renderer* renderer, int width, int height) {
    return SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STREAMING, width, height);
}

IdrisSDLTextureLock* idris_sdl_texture_lock_new(void) {
    IdrisSDLTextureLock* lock = SDL_calloc(1, sizeof(*lock));

    if (!lock) SDL_SetError("Cannot allocate texture lock storage");

    return lock;
}

void idris_sdl_texture_lock_free(IdrisSDLTextureLock* lock) {
    if (!lock) return;

    if (lock->texture) SDL_UnlockTexture(lock->texture);

    SDL_free(lock);
}

int idris_sdl_lock_texture_rgba(IdrisSDLTextureLock* lock, SDL_Texture* texture, int region, Sint32 x, Sint32 y, Sint32 w, Sint32 h) {
    if (!lock || !texture) return SDL_SetError("Texture and lock storage must not be null");

    if (lock->texture) return SDL_SetError("Texture lock storage is already active");

    if (lock->generation == SDL_MAX_UINT64) return SDL_SetError("Texture lock generation is exhausted");

    if (texture->format != SDL_PIXELFORMAT_RGBA32) return SDL_SetError("Texture must use RGBA32 pixels");

    if (texture->w <= 0 || texture->h <= 0) return SDL_SetError("Texture dimensions must be positive");

    if (!region) {
        x = 0;
        y = 0;
        w = texture->w;
        h = texture->h;
    }

    if (x < 0 || y < 0 || w <= 0 || h <= 0 || w > texture->w || h > texture->h || x > texture->w - w || y > texture->h - h) {
        return SDL_SetError("Lock rectangle must have positive dimensions and fit inside the texture");
    }

    SDL_Rect rect   = {x, y, w, h};
    void*    pixels = NULL;
    int      pitch  = 0;

    if (!SDL_LockTexture(texture, region ? &rect : NULL, &pixels, &pitch)) return 0;

    /* The last row contains only the locked width, not a whole pitch from this offset. */
    const Uint64 row_bytes = (Uint64)w * 4;

    if (!pixels || pitch <= 0 || (Uint64)pitch < row_bytes || (Uint64)(h - 1) * (Uint64)pitch + row_bytes > SIZE_MAX) {
        SDL_UnlockTexture(texture);

        return SDL_SetError("SDL returned invalid RGBA lock storage");
    }

    lock->width  = w;
    lock->height = h;
    lock->pitch  = pitch;
    lock->generation++;
    lock->pixels  = pixels;
    lock->texture = texture;

    return 1;
}

static int valid_texture_lock(const IdrisSDLTextureLock* lock, Uint64 generation) {
    if (!lock || !lock->texture || !lock->pixels || lock->generation != generation)
        return SDL_SetError("RGBA texture lock is inactive or stale");

    return 1;
}

int idris_sdl_unlock_texture_rgba(IdrisSDLTextureLock* lock, Uint64 generation) {
    if (!valid_texture_lock(lock, generation)) return 0;

    SDL_UnlockTexture(lock->texture);

    lock->texture = NULL;
    lock->pixels  = NULL;

    return 1;
}

int idris_sdl_locked_pixel_rgba(IdrisSDLTextureLock* lock, Uint64 generation, Sint32 x, Sint32 y, Uint8 r, Uint8 g, Uint8 b, Uint8 a) {
    if (!valid_texture_lock(lock, generation)) return 0;

    if (x < 0 || y < 0 || x >= lock->width || y >= lock->height) return SDL_SetError("Pixel coordinates are outside the locked region");

    Uint8* pixel = (Uint8*)lock->pixels + (size_t)y * (size_t)lock->pitch + (size_t)x * 4;
    pixel[0]     = r;
    pixel[1]     = g;
    pixel[2]     = b;
    pixel[3]     = a;

    return 1;
}

int idris_sdl_locked_fill_rgba(IdrisSDLTextureLock* lock, Uint64 generation, Uint8 r, Uint8 g, Uint8 b, Uint8 a) {
    if (!valid_texture_lock(lock, generation)) return 0;

    for (Sint32 y = 0; y < lock->height; ++y) {
        Uint8* row = (Uint8*)lock->pixels + (size_t)y * (size_t)lock->pitch;

        for (Sint32 x = 0; x < lock->width; ++x) {
            row[0] = r;
            row[1] = g;
            row[2] = b;
            row[3] = a;
            row += 4;
        }
    }

    return 1;
}

int idris_sdl_locked_copy_rgba(IdrisSDLTextureLock* lock, Uint64 generation, const void* pixels, Uint64 size, Sint32 pitch) {
    if (!valid_texture_lock(lock, generation)) return 0;

    const Uint64 row_bytes = (Uint64)lock->width * 4;

    if (!pixels || pitch <= 0 || (Uint64)pitch < row_bytes) return SDL_SetError("Source buffer and RGBA pitch are invalid");

    const Uint64 required = (Uint64)pitch * (Uint64)lock->height;

    if (size < required || required > SIZE_MAX) return SDL_SetError("Source buffer is too small for the locked region and pitch");

    for (Sint32 y = 0; y < lock->height; ++y) {
        SDL_memcpy((Uint8*)lock->pixels + (size_t)y * (size_t)lock->pitch, (const Uint8*)pixels + (size_t)y * (size_t)pitch,
                   (size_t)row_bytes);
    }

    return 1;
}

int idris_sdl_get_texture_size(SDL_Texture* texture) {
    /* SDL permits NULL outputs. Validate without rounding dimensions through float. */
    return SDL_GetTextureSize(texture, NULL, NULL);
}

static int update_texture_rgba(SDL_Texture* texture, const SDL_Rect* rect, const void* pixels, Uint64 size, Sint32 pitch) {
    if (!texture || !pixels) return SDL_SetError("Texture and pixel buffer must not be null");

    if (texture->format != SDL_PIXELFORMAT_RGBA32) return SDL_SetError("Texture must use RGBA32 pixels");

    if (texture->w <= 0 || texture->h <= 0) return SDL_SetError("Texture dimensions must be positive");

    const int width  = rect ? rect->w : texture->w;
    const int height = rect ? rect->h : texture->h;

    if (rect && (rect->x < 0 || rect->y < 0 || width <= 0 || height <= 0 || width > texture->w || height > texture->h ||
                 rect->x > texture->w - width || rect->y > texture->h - height)) {
        return SDL_SetError("Upload rectangle must have positive dimensions and fit inside the texture");
    }

    const Uint64 row_bytes = (Uint64)width * 4;

    if (pitch <= 0 || (Uint64)pitch < row_bytes) return SDL_SetError("Pixel pitch is smaller than one RGBA row");

    /* Both factors are positive 32-bit integers, so this product fits Uint64. */
    const Uint64 required = (Uint64)pitch * (Uint64)height;

    if (size < required) return SDL_SetError("Pixel buffer is too small for the upload and pitch");

    return SDL_UpdateTexture(texture, rect, pixels, pitch);
}

int idris_sdl_update_texture_rgba(SDL_Texture* texture, const void* pixels, Uint64 size, Sint32 pitch) {
    return update_texture_rgba(texture, NULL, pixels, size, pitch);
}

int idris_sdl_update_texture_region_rgba(SDL_Texture* texture, Sint32 x, Sint32 y, Sint32 w, Sint32 h, const void* pixels, Uint64 size,
                                         Sint32 pitch) {
    const SDL_Rect rect = {x, y, w, h};

    return update_texture_rgba(texture, &rect, pixels, size, pitch);
}

int idris_sdl_set_texture_color_mod(SDL_Texture* texture, Uint8 r, Uint8 g, Uint8 b) {
    return SDL_SetTextureColorMod(texture, r, g, b);
}

int idris_sdl_set_texture_alpha_mod(SDL_Texture* texture, Uint8 alpha) {
    return SDL_SetTextureAlphaMod(texture, alpha);
}

int idris_sdl_get_texture_alpha_mod(SDL_Texture* texture) {
    Uint8 alpha;

    if (!SDL_GetTextureAlphaMod(texture, &alpha)) return -1;

    return alpha;
}

Sint64 idris_sdl_get_texture_blend_mode(SDL_Texture* texture) {
    SDL_BlendMode mode;

    if (!SDL_GetTextureBlendMode(texture, &mode)) return -1;

    return mode;
}

int idris_sdl_set_texture_blend_mode(SDL_Texture* texture, Uint32 mode) {
    return SDL_SetTextureBlendMode(texture, mode);
}

Sint64 idris_sdl_get_texture_scale_mode(SDL_Texture* texture) {
    SDL_ScaleMode mode;

    if (!SDL_GetTextureScaleMode(texture, &mode)) return -2147483649LL;

    return (Sint32)mode;
}

int idris_sdl_set_texture_scale_mode(SDL_Texture* texture, int mode) {
    return SDL_SetTextureScaleMode(texture, (SDL_ScaleMode)mode);
}

int idris_sdl_set_render_target(SDL_Renderer* renderer, SDL_Texture* texture) {
    return SDL_SetRenderTarget(renderer, texture);
}

int idris_sdl_reset_render_target(SDL_Renderer* renderer) {
    return SDL_SetRenderTarget(renderer, NULL);
}

int idris_sdl_render_texture(SDL_Renderer* renderer, SDL_Texture* texture) {
    return SDL_RenderTexture(renderer, texture, NULL, NULL);
}

int idris_sdl_render_texture_rect(SDL_Renderer* renderer, SDL_Texture* texture, double x, double y, double w, double h) {
    const SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};

    return SDL_RenderTexture(renderer, texture, NULL, &rect);
}

int idris_sdl_render_texture_source(SDL_Renderer* renderer, SDL_Texture* texture, double x, double y, double w, double h) {
    const SDL_FRect source = {(float)x, (float)y, (float)w, (float)h};

    return SDL_RenderTexture(renderer, texture, &source, NULL);
}

int idris_sdl_render_texture_region(SDL_Renderer* renderer, SDL_Texture* texture, double sx, double sy, double sw, double sh, double dx,
                                    double dy, double dw, double dh) {
    const SDL_FRect source      = {(float)sx, (float)sy, (float)sw, (float)sh};
    const SDL_FRect destination = {(float)dx, (float)dy, (float)dw, (float)dh};

    return SDL_RenderTexture(renderer, texture, &source, &destination);
}

int idris_sdl_render_texture_rotated(SDL_Renderer* renderer, SDL_Texture* texture, Uint32 options, double sx, double sy, double sw,
                                     double sh, double dx, double dy, double dw, double dh, double angle, double cx, double cy) {
    const SDL_FRect  source      = {(float)sx, (float)sy, (float)sw, (float)sh};
    const SDL_FRect  destination = {(float)dx, (float)dy, (float)dw, (float)dh};
    const SDL_FPoint center      = {(float)cx, (float)cy};

    return SDL_RenderTextureRotated(renderer, texture, (options & 1) ? &source : NULL, (options & 2) ? &destination : NULL, angle,
                                    (options & 4) ? &center : NULL, (SDL_FlipMode)((options >> 3) & 3));
}

IdrisSDLPoint* idris_sdl_coordinate_new(void) {
    IdrisSDLPoint* point = SDL_calloc(1, sizeof(*point));

    if (!point) SDL_SetError("Cannot allocate coordinate buffer");

    return point;
}

void idris_sdl_coordinate_free(IdrisSDLPoint* point) {
    SDL_free(point);
}

int idris_sdl_render_coordinates_from_window(SDL_Renderer* renderer, double x, double y, IdrisSDLPoint* point) {
    if (!point) return SDL_SetError("Coordinate storage is null");

    float converted_x, converted_y;

    if (!SDL_RenderCoordinatesFromWindow(renderer, (float)x, (float)y, &converted_x, &converted_y)) return 0;

    point->x = converted_x;
    point->y = converted_y;

    return 1;
}

int idris_sdl_render_coordinates_to_window(SDL_Renderer* renderer, double x, double y, IdrisSDLPoint* point) {
    if (!point) return SDL_SetError("Coordinate storage is null");

    float converted_x, converted_y;

    if (!SDL_RenderCoordinatesToWindow(renderer, (float)x, (float)y, &converted_x, &converted_y)) return 0;

    point->x = converted_x;
    point->y = converted_y;

    return 1;
}

int idris_sdl_set_render_scale(SDL_Renderer* renderer, double x, double y) {
    return SDL_SetRenderScale(renderer, (float)x, (float)y);
}

int idris_sdl_set_render_logical_presentation(SDL_Renderer* renderer, Sint32 w, Sint32 h, int mode) {
    return SDL_SetRenderLogicalPresentation(renderer, w, h, (SDL_RendererLogicalPresentation)mode);
}

int idris_sdl_set_render_viewport(SDL_Renderer* renderer, Sint32 x, Sint32 y, Sint32 w, Sint32 h) {
    const SDL_Rect rect = {x, y, w, h};

    return SDL_SetRenderViewport(renderer, &rect);
}

int idris_sdl_reset_render_viewport(SDL_Renderer* renderer) {
    return SDL_SetRenderViewport(renderer, NULL);
}

int idris_sdl_set_render_clip_rect(SDL_Renderer* renderer, Sint32 x, Sint32 y, Sint32 w, Sint32 h) {
    const SDL_Rect rect = {x, y, w, h};

    return SDL_SetRenderClipRect(renderer, &rect);
}

int idris_sdl_reset_render_clip_rect(SDL_Renderer* renderer) {
    return SDL_SetRenderClipRect(renderer, NULL);
}

Sint64 idris_sdl_get_draw_blend_mode(SDL_Renderer* renderer) {
    SDL_BlendMode mode;

    if (!SDL_GetRenderDrawBlendMode(renderer, &mode)) return -1;

    return mode;
}

int idris_sdl_set_draw_blend_mode(SDL_Renderer* renderer, Uint32 mode) {
    return SDL_SetRenderDrawBlendMode(renderer, mode);
}

int idris_sdl_draw_color(SDL_Renderer* r, Uint8 red, Uint8 g, Uint8 b, Uint8 a) {
    return SDL_SetRenderDrawColor(r, red, g, b, a);
}

int idris_sdl_clear(SDL_Renderer* r) {
    return SDL_RenderClear(r);
}

int idris_sdl_set_render_vsync(SDL_Renderer* renderer, Sint64 value) {
    /* Validate before narrowing, including values supplied as unsigned intervals. */
    if (value < -1 || value > 2147483647) return SDL_SetError("Invalid VSync mode or interval");

    return SDL_SetRenderVSync(renderer, (int)value);
}

Sint32 idris_sdl_get_render_vsync(SDL_Renderer* renderer) {
    int value;

    if (!SDL_GetRenderVSync(renderer, &value)) return -2;

    if (value < -1) {
        SDL_SetError("Unknown SDL VSync mode");

        return -2;
    }

    return value;
}

int idris_sdl_present(SDL_Renderer* r) {
    return SDL_RenderPresent(r);
}

struct IdrisSDLPoints {
    Uint32     capacity;
    SDL_FPoint values[];
};

IdrisSDLPoints* idris_sdl_points_new(Uint32 capacity) {
    if (capacity == 0 || capacity > SDL_MAX_SINT32) {
        SDL_SetError("Point buffer capacity must be between 1 and 2147483647");

        return NULL;
    }

    size_t bytes;

    if (!SDL_size_mul_check_overflow(capacity, sizeof(SDL_FPoint), &bytes) ||
        !SDL_size_add_check_overflow(sizeof(IdrisSDLPoints), bytes, &bytes)) {
        SDL_SetError("Point buffer capacity exceeds the native allocation limit");

        return NULL;
    }

    IdrisSDLPoints* points = SDL_calloc(1, bytes);

    if (!points) {
        SDL_SetError("Cannot allocate point buffer");

        return NULL;
    }

    points->capacity = capacity;

    return points;
}

void idris_sdl_points_free(IdrisSDLPoints* points) {
    SDL_free(points);
}

int idris_sdl_points_set(IdrisSDLPoints* points, Uint32 index, double x, double y) {
    if (!points) return SDL_SetError("Point buffer is null");

    if (index >= points->capacity) return SDL_SetError("Point buffer index is out of range");

    points->values[index] = (SDL_FPoint){(float)x, (float)y};

    return 1;
}

int idris_sdl_draw_points(SDL_Renderer* renderer, const IdrisSDLPoints* points, Uint32 count) {
    if (!points) return SDL_SetError("Point buffer is null");

    if (count > points->capacity) return SDL_SetError("Point count exceeds buffer capacity");

    return SDL_RenderPoints(renderer, points->values, (int)count);
}

int idris_sdl_draw_lines(SDL_Renderer* renderer, const IdrisSDLPoints* points, Uint32 count) {
    if (!points) return SDL_SetError("Point buffer is null");

    if (count > points->capacity) return SDL_SetError("Point count exceeds buffer capacity");

    return SDL_RenderLines(renderer, points->values, (int)count);
}

struct IdrisSDLRects {
    Uint32    capacity;
    SDL_FRect values[];
};

IdrisSDLRects* idris_sdl_rects_new(Uint32 capacity) {
    if (capacity == 0 || capacity > SDL_MAX_SINT32) {
        SDL_SetError("Rectangle buffer capacity must be between 1 and 2147483647");

        return NULL;
    }

    size_t bytes;

    if (!SDL_size_mul_check_overflow(capacity, sizeof(SDL_FRect), &bytes) ||
        !SDL_size_add_check_overflow(sizeof(IdrisSDLRects), bytes, &bytes)) {
        SDL_SetError("Rectangle buffer capacity exceeds the native allocation limit");

        return NULL;
    }

    IdrisSDLRects* rects = SDL_calloc(1, bytes);

    if (!rects) {
        SDL_SetError("Cannot allocate rectangle buffer");

        return NULL;
    }

    rects->capacity = capacity;

    return rects;
}

void idris_sdl_rects_free(IdrisSDLRects* rects) {
    SDL_free(rects);
}

int idris_sdl_rects_set(IdrisSDLRects* rects, Uint32 index, double x, double y, double w, double h) {
    if (!rects) return SDL_SetError("Rectangle buffer is null");

    if (index >= rects->capacity) return SDL_SetError("Rectangle buffer index is out of range");

    rects->values[index] = (SDL_FRect){(float)x, (float)y, (float)w, (float)h};

    return 1;
}

int idris_sdl_draw_rects(SDL_Renderer* renderer, const IdrisSDLRects* rects, Uint32 count) {
    if (!rects) return SDL_SetError("Rectangle buffer is null");

    if (count > rects->capacity) return SDL_SetError("Rectangle count exceeds buffer capacity");

    return SDL_RenderRects(renderer, rects->values, (int)count);
}

int idris_sdl_fill_rects(SDL_Renderer* renderer, const IdrisSDLRects* rects, Uint32 count) {
    if (!rects) return SDL_SetError("Rectangle buffer is null");

    if (count > rects->capacity) return SDL_SetError("Rectangle count exceeds buffer capacity");

    return SDL_RenderFillRects(renderer, rects->values, (int)count);
}

int idris_sdl_draw_point(SDL_Renderer* renderer, double x, double y) {
    return SDL_RenderPoint(renderer, (float)x, (float)y);
}

int idris_sdl_draw_line(SDL_Renderer* renderer, double x1, double y1, double x2, double y2) {
    return SDL_RenderLine(renderer, (float)x1, (float)y1, (float)x2, (float)y2);
}

int idris_sdl_draw_rect(SDL_Renderer* renderer, Sint32 has_rect, double x, double y, double w, double h) {
    const SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};

    return SDL_RenderRect(renderer, has_rect ? &rect : NULL);
}

int idris_sdl_fill_rect(SDL_Renderer* r, double x, double y, double w, double h) {
    const SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};

    return SDL_RenderFillRect(r, &rect);
}

int idris_sdl_start_text_input(SDL_Window* window) {
    return SDL_StartTextInput(window);
}

int idris_sdl_stop_text_input(SDL_Window* window) {
    return SDL_StopTextInput(window);
}

int idris_sdl_text_input_active(SDL_Window* window) {
    return SDL_TextInputActive(window);
}

int idris_sdl_set_text_input_area(SDL_Window* window, Sint32 x, Sint32 y, Sint32 w, Sint32 h, Sint32 cursor) {
    const SDL_Rect rect = {x, y, w, h};

    return SDL_SetTextInputArea(window, &rect, cursor);
}

int idris_sdl_clear_text_input_area(SDL_Window* window) {
    return SDL_SetTextInputArea(window, NULL, 0);
}

int idris_sdl_clear_composition(SDL_Window* window) {
    return SDL_ClearComposition(window);
}

SDL_Event* idris_sdl_event_new(void) {
    SDL_Event* event = SDL_calloc(1, sizeof(SDL_Event));

    if (!event) SDL_SetError("Cannot allocate SDL event buffer");

    return event;
}

void idris_sdl_event_free(SDL_Event* event) {
    SDL_free(event);
}

int idris_sdl_poll(SDL_Event* event) {
    return SDL_PollEvent(event);
}

int idris_sdl_wait_event(SDL_Event* event) {
    if (!event) return SDL_SetError("Event buffer must not be null");

    return SDL_WaitEvent(event);
}

int idris_sdl_wait_event_timeout(SDL_Event* event, Uint32 timeout_ms) {
    if (!event || timeout_ms > 2147483647) {
        SDL_SetError("Event buffer or wait timeout is invalid");
        return -1;
    }

    /* SDL reports both timeout and failure as false. Do not use a stale error. */
    SDL_ClearError();

    if (SDL_WaitEventTimeout(event, (Sint32)timeout_ms)) return 1;

    return SDL_GetError()[0] ? -1 : 0;
}

Uint32 idris_sdl_event_type(const SDL_Event* event) {
    return event->type;
}

Uint64 idris_sdl_event_timestamp(const SDL_Event* event) {
    return event->common.timestamp;
}

Uint32 idris_sdl_event_window(const SDL_Event* event) {
    switch (event->type) {
    case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
    case SDL_EVENT_WINDOW_RESIZED:
    case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
    case SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED:
    case SDL_EVENT_WINDOW_FOCUS_GAINED:
    case SDL_EVENT_WINDOW_FOCUS_LOST:
    case SDL_EVENT_WINDOW_MOUSE_ENTER:
    case SDL_EVENT_WINDOW_MOUSE_LEAVE:
    case SDL_EVENT_WINDOW_MINIMIZED:
    case SDL_EVENT_WINDOW_MAXIMIZED:
    case SDL_EVENT_WINDOW_RESTORED:
    case SDL_EVENT_WINDOW_SHOWN:
    case SDL_EVENT_WINDOW_HIDDEN:
    case SDL_EVENT_WINDOW_EXPOSED:
    case SDL_EVENT_WINDOW_MOVED:
    case SDL_EVENT_WINDOW_ENTER_FULLSCREEN:
    case SDL_EVENT_WINDOW_LEAVE_FULLSCREEN:
        return event->window.windowID;
    case SDL_EVENT_DROP_FILE:
    case SDL_EVENT_DROP_TEXT:
    case SDL_EVENT_DROP_BEGIN:
    case SDL_EVENT_DROP_COMPLETE:
    case SDL_EVENT_DROP_POSITION:
        return event->drop.windowID;
    case SDL_EVENT_TEXT_INPUT:
        return event->text.windowID;
    case SDL_EVENT_TEXT_EDITING:
        return event->edit.windowID;
    case SDL_EVENT_MOUSE_MOTION:
        return event->motion.windowID;
    case SDL_EVENT_MOUSE_WHEEL:
        return event->wheel.windowID;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
    case SDL_EVENT_MOUSE_BUTTON_UP:
        return event->button.windowID;
    default:
        return event->key.windowID;
    }
}

Sint32 idris_sdl_event_window_data1(const SDL_Event* event) {
    return event->window.data1;
}

Sint32 idris_sdl_event_window_data2(const SDL_Event* event) {
    return event->window.data2;
}

Uint32 idris_sdl_event_scancode(const SDL_Event* event) {
    return (Uint32)event->key.scancode;
}

Uint32 idris_sdl_event_keycode(const SDL_Event* event) {
    return event->key.key;
}

Uint16 idris_sdl_event_modifiers(const SDL_Event* event) {
    return event->key.mod;
}

int idris_sdl_event_repeat(const SDL_Event* event) {
    return event->key.repeat;
}

Uint32 idris_sdl_event_mouse_id(const SDL_Event* event) {
    if (event->type == SDL_EVENT_MOUSE_WHEEL) return event->wheel.which;

    return event->type == SDL_EVENT_MOUSE_MOTION ? event->motion.which : event->button.which;
}

Uint32 idris_sdl_event_mouse_buttons(const SDL_Event* event) {
    return event->motion.state;
}

Uint8 idris_sdl_event_mouse_button(const SDL_Event* event) {
    return event->button.button;
}

Uint8 idris_sdl_event_mouse_clicks(const SDL_Event* event) {
    return event->button.clicks;
}

double idris_sdl_event_mouse_x(const SDL_Event* event) {
    if (event->type == SDL_EVENT_MOUSE_WHEEL) return event->wheel.mouse_x;

    return event->type == SDL_EVENT_MOUSE_MOTION ? event->motion.x : event->button.x;
}

double idris_sdl_event_mouse_y(const SDL_Event* event) {
    if (event->type == SDL_EVENT_MOUSE_WHEEL) return event->wheel.mouse_y;

    return event->type == SDL_EVENT_MOUSE_MOTION ? event->motion.y : event->button.y;
}

double idris_sdl_event_mouse_dx(const SDL_Event* event) {
    return event->motion.xrel;
}

double idris_sdl_event_mouse_dy(const SDL_Event* event) {
    return event->motion.yrel;
}

double idris_sdl_event_wheel_x(const SDL_Event* event) {
    return event->wheel.x;
}

double idris_sdl_event_wheel_y(const SDL_Event* event) {
    return event->wheel.y;
}

Uint32 idris_sdl_event_wheel_direction(const SDL_Event* event) {
    return (Uint32)event->wheel.direction;
}

Sint32 idris_sdl_event_wheel_integer_x(const SDL_Event* event) {
    return event->wheel.integer_x;
}

Sint32 idris_sdl_event_wheel_integer_y(const SDL_Event* event) {
    return event->wheel.integer_y;
}

/* Borrowed until the next poll. Idris copies this string and never writes to it. */
char* idris_sdl_event_text(const SDL_Event* event) {
    const char* text = event->type == SDL_EVENT_TEXT_INPUT ? event->text.text : event->edit.text;

    return (char*)(text ? text : "");
}

Sint32 idris_sdl_event_edit_start(const SDL_Event* event) {
    return event->edit.start;
}

Sint32 idris_sdl_event_edit_length(const SDL_Event* event) {
    return event->edit.length;
}

int idris_sdl_event_kind(const SDL_Event* event) {
    switch (event->type) {
    case SDL_EVENT_QUIT:
        return 1;
    case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
        return 2;
    case SDL_EVENT_KEY_DOWN:
        return 3;
    case SDL_EVENT_KEY_UP:
        return 4;
    case SDL_EVENT_MOUSE_MOTION:
        return 5;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
        return 6;
    case SDL_EVENT_MOUSE_BUTTON_UP:
        return 7;
    case SDL_EVENT_MOUSE_WHEEL:
        return 8;
    case SDL_EVENT_TEXT_INPUT:
        return 9;
    case SDL_EVENT_TEXT_EDITING:
        return 10;
    case SDL_EVENT_WINDOW_RESIZED:
        return 11;
    case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
        return 12;
    case SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED:
        return 13;
    case SDL_EVENT_WINDOW_FOCUS_GAINED:
        return 14;
    case SDL_EVENT_WINDOW_FOCUS_LOST:
        return 15;
    case SDL_EVENT_WINDOW_MOUSE_ENTER:
        return 16;
    case SDL_EVENT_WINDOW_MOUSE_LEAVE:
        return 17;
    case SDL_EVENT_WINDOW_MINIMIZED:
        return 18;
    case SDL_EVENT_WINDOW_MAXIMIZED:
        return 19;
    case SDL_EVENT_WINDOW_RESTORED:
        return 20;
    case SDL_EVENT_WINDOW_SHOWN:
        return 21;
    case SDL_EVENT_WINDOW_HIDDEN:
        return 22;
    case SDL_EVENT_WINDOW_EXPOSED:
        return 23;
    case SDL_EVENT_WINDOW_MOVED:
        return 24;
    case SDL_EVENT_WINDOW_ENTER_FULLSCREEN:
        return 25;
    case SDL_EVENT_WINDOW_LEAVE_FULLSCREEN:
        return 26;
    case SDL_EVENT_GAMEPAD_ADDED:
        return 27;
    case SDL_EVENT_GAMEPAD_REMOVED:
        return 28;
    case SDL_EVENT_GAMEPAD_REMAPPED:
        return 29;
    case SDL_EVENT_GAMEPAD_AXIS_MOTION:
        return 30;
    case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
        return 31;
    case SDL_EVENT_GAMEPAD_BUTTON_UP:
        return 32;
    case SDL_EVENT_DROP_FILE:
        return 33;
    case SDL_EVENT_DROP_TEXT:
        return 34;
    case SDL_EVENT_DROP_BEGIN:
        return 35;
    case SDL_EVENT_DROP_COMPLETE:
        return 36;
    case SDL_EVENT_DROP_POSITION:
        return 37;
    default:
        return 0;
    }
}

/* Core audio playback. */
_Static_assert(sizeof(int) == sizeof(Sint32), "Audio ABI requires 32-bit C int");

_Static_assert(SDL_AUDIO_U8 == 0x0008 && SDL_AUDIO_S8 == 0x8008 && SDL_AUDIO_S16LE == 0x8010 && SDL_AUDIO_S16BE == 0x9010 &&
                   SDL_AUDIO_S32LE == 0x8020 && SDL_AUDIO_S32BE == 0x9020 && SDL_AUDIO_F32LE == 0x8120 && SDL_AUDIO_F32BE == 0x9120,
               "Audio format codes must match Idris");

static int valid_spec(const SDL_AudioSpec* spec) {
    switch (spec->format) {
    case SDL_AUDIO_U8:
    case SDL_AUDIO_S8:
    case SDL_AUDIO_S16LE:
    case SDL_AUDIO_S16BE:
    case SDL_AUDIO_S32LE:
    case SDL_AUDIO_S32BE:
    case SDL_AUDIO_F32LE:
    case SDL_AUDIO_F32BE:
        break;
    default:
        return SDL_SetError("Unsupported PCM audio format");
    }

    if (spec->channels < 1 || spec->channels > 8 || spec->freq <= 0)
        return SDL_SetError("Audio requires 1 to 8 channels and a positive sample rate");

    return 1;
}

SDL_AudioStream* idris_sdl_audio_open(Uint32 format, Sint32 channels, Sint32 frequency) {
    const SDL_AudioSpec spec = {(SDL_AudioFormat)format, channels, frequency};

    if (!valid_spec(&spec)) return NULL;

    /* SDL owns the device with this stream. No callback enters Idris from an audio thread. */
    return SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL);
}

static int put_range(SDL_AudioStream* stream, const SDL_AudioSpec* spec, const void* data, Uint64 capacity, Uint32 offset, Uint32 length) {
    if (!valid_spec(spec)) return 0;

    const Uint32 frame_bytes = (Uint32)SDL_AUDIO_FRAMESIZE(*spec);

    if (length > SDL_MAX_SINT32 || (Uint64)offset + length > capacity || (Uint64)offset + length > SIZE_MAX || offset % frame_bytes ||
        length % frame_bytes) {
        return SDL_SetError("Audio range must fit the buffer and contain aligned whole sample frames");
    }

    if (length == 0) return 1;

    if (!data) return SDL_SetError("Audio data must not be null");

    return SDL_PutAudioStreamData(stream, (const Uint8*)data + offset, (int)length);
}

int idris_sdl_audio_put(SDL_AudioStream* stream, const void* data, Uint64 capacity, Uint32 offset, Uint32 length) {
    SDL_AudioSpec spec;

    if (!SDL_GetAudioStreamFormat(stream, &spec, NULL)) return 0;

    return put_range(stream, &spec, data, capacity, offset, length);
}

int idris_sdl_audio_pause(SDL_AudioStream* stream) {
    return SDL_PauseAudioStreamDevice(stream);
}
int idris_sdl_audio_resume(SDL_AudioStream* stream) {
    return SDL_ResumeAudioStreamDevice(stream);
}
int idris_sdl_audio_paused(SDL_AudioStream* stream) {
    return SDL_AudioStreamDevicePaused(stream);
}
int idris_sdl_audio_clear(SDL_AudioStream* stream) {
    return SDL_ClearAudioStream(stream);
}
int idris_sdl_audio_flush(SDL_AudioStream* stream) {
    return SDL_FlushAudioStream(stream);
}

int idris_sdl_audio_set_gain(SDL_AudioStream* stream, double gain) {
    if (!(gain >= 0.0 && gain <= FLT_MAX)) return SDL_SetError("Audio gain must be finite, nonnegative, and fit a float");

    return SDL_SetAudioStreamGain(stream, (float)gain);
}

double idris_sdl_audio_get_gain(SDL_AudioStream* stream) {
    return (double)SDL_GetAudioStreamGain(stream);
}

IdrisSDLWAV* idris_sdl_wav_load(const char* path) {
    IdrisSDLWAV* wav = SDL_calloc(1, sizeof(*wav));
    if (!wav) {
        SDL_SetError("Cannot allocate WAV metadata");

        return NULL;
    }

    SDL_AudioSpec spec;

    if (!SDL_LoadWAV(path, &spec, &wav->data, &wav->length)) {
        SDL_free(wav);

        return NULL;
    }

    if (!valid_spec(&spec)) {
        SDL_free(wav->data);
        SDL_free(wav);

        return NULL;
    }

    wav->format    = (Uint32)spec.format;
    wav->channels  = spec.channels;
    wav->frequency = spec.freq;

    return wav;
}

void idris_sdl_wav_free(IdrisSDLWAV* wav) {
    if (!wav) return;

    SDL_free(wav->data);
    SDL_free(wav);
}

int idris_sdl_audio_put_wav(SDL_AudioStream* stream, const IdrisSDLWAV* wav, Uint32 offset, Uint32 length) {
    if (!wav) return SDL_SetError("WAV data must not be null");

    SDL_AudioSpec spec;

    if (!SDL_GetAudioStreamFormat(stream, &spec, NULL)) return 0;

    if ((Uint32)spec.format != wav->format || spec.channels != wav->channels || spec.freq != wav->frequency)
        return SDL_SetError("WAV format must match the playback stream input");

    return put_range(stream, &spec, wav->data, wav->length, offset, length);
}

_Static_assert(SDL_GAMEPAD_AXIS_LEFTX == 0 && SDL_GAMEPAD_AXIS_RIGHT_TRIGGER == 5, "Gamepad axis codes must match Idris");

_Static_assert(SDL_GAMEPAD_BUTTON_SOUTH == 0 && SDL_GAMEPAD_BUTTON_DPAD_RIGHT == 14 && SDL_GAMEPAD_BUTTON_TOUCHPAD == 20,
               "Gamepad button codes must match Idris");

_Static_assert(SDL_SYSTEM_CURSOR_DEFAULT == 0 && SDL_SYSTEM_CURSOR_POINTER == 11, "Cursor codes must match Idris");

_Static_assert(SDL_IO_SEEK_SET == 0 && SDL_IO_SEEK_CUR == 1 && SDL_IO_SEEK_END == 2 && SDL_IO_STATUS_READY == 0 &&
                   SDL_IO_STATUS_WRITEONLY == 5,
               "IO codes must match Idris");

IdrisSDLGamepads* idris_sdl_gamepads_new(void) {
    IdrisSDLGamepads* list = SDL_calloc(1, sizeof(*list));
    if (!list) {
        SDL_SetError("Cannot allocate gamepad list");
        return NULL;
    }

    int count = 0;

    list->ids = SDL_GetGamepads(&count);
    if (!list->ids) {
        SDL_free(list);
        return NULL;
    }

    list->count = count;

    return list;
}

Uint32 idris_sdl_gamepads_at(const IdrisSDLGamepads* list, Uint32 index) {
    if (!list || index >= (Uint32)list->count) {
        SDL_SetError("Gamepad index is outside the list");

        return 0;
    }

    return list->ids[index];
}

void idris_sdl_gamepads_free(IdrisSDLGamepads* list) {
    if (list) {
        SDL_free(list->ids);
        SDL_free(list);
    }
}

int idris_sdl_gamepad_connected(SDL_Gamepad* gamepad) {
    return SDL_GamepadConnected(gamepad);
}

int idris_sdl_gamepad_button(SDL_Gamepad* gamepad, Sint32 button) {
    return SDL_GetGamepadButton(gamepad, (SDL_GamepadButton)button);
}

int idris_sdl_gamepad_rumble(SDL_Gamepad* gamepad, Uint16 low, Uint16 high, Uint32 ms) {
    return SDL_RumbleGamepad(gamepad, low, high, ms);
}

int idris_sdl_relative_mouse(SDL_Window* window, int enabled) {
    return SDL_SetWindowRelativeMouseMode(window, enabled != 0);
}

int idris_sdl_relative_mouse_enabled(SDL_Window* window) {
    return SDL_GetWindowRelativeMouseMode(window);
}

int idris_sdl_capture_mouse(int enabled) {
    return SDL_CaptureMouse(enabled != 0);
}

int idris_sdl_set_cursor(SDL_Cursor* cursor) {
    return SDL_SetCursor(cursor);
}

int idris_sdl_default_cursor(void) {
    SDL_Cursor* cursor = SDL_GetDefaultCursor();

    return cursor ? SDL_SetCursor(cursor) : 0;
}

int idris_sdl_show_cursor(void) {
    return SDL_ShowCursor();
}

int idris_sdl_hide_cursor(void) {
    return SDL_HideCursor();
}

int idris_sdl_cursor_visible(void) {
    return SDL_CursorVisible();
}

int idris_sdl_clipboard_set(const char* text) {
    return SDL_SetClipboardText(text);
}

char* idris_sdl_clipboard_get(void) {
    /* Empty text is valid. Normalize SDL's empty-string error result to null. */
    SDL_ClearError();

    char* text = SDL_GetClipboardText();

    if (SDL_GetError()[0]) {
        SDL_free(text);

        return NULL;
    }

    return text;
}

int idris_sdl_clipboard_has_text(void) {
    return SDL_HasClipboardText();
}

const char* idris_sdl_string(const char* text) {
    return text ? text : "";
}

Uint32 idris_sdl_event_gamepad(const SDL_Event* event) {
    switch (event->type) {
    case SDL_EVENT_GAMEPAD_AXIS_MOTION:
        return event->gaxis.which;
    case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
    case SDL_EVENT_GAMEPAD_BUTTON_UP:
        return event->gbutton.which;
    default:
        return event->gdevice.which;
    }
}

Uint8 idris_sdl_event_gamepad_control(const SDL_Event* event) {
    return event->type == SDL_EVENT_GAMEPAD_AXIS_MOTION ? event->gaxis.axis : event->gbutton.button;
}

Sint16 idris_sdl_event_gamepad_value(const SDL_Event* event) {
    return event->gaxis.value;
}

const char* idris_sdl_event_drop_data(const SDL_Event* event) {
    return idris_sdl_string(event->drop.data);
}

const char* idris_sdl_event_drop_source(const SDL_Event* event) {
    return idris_sdl_string(event->drop.source);
}

double idris_sdl_event_drop_x(const SDL_Event* event) {
    return event->drop.x;
}

double idris_sdl_event_drop_y(const SDL_Event* event) {
    return event->drop.y;
}

int idris_sdl_io_close(SDL_IOStream* stream) {
    return SDL_CloseIO(stream);
}

int idris_sdl_io_flush(SDL_IOStream* stream) {
    return SDL_FlushIO(stream);
}

static int valid_io_range(SDL_IOStream* stream, const void* buffer, Uint64 capacity, Uint64 offset, Uint64 count) {
    if (!stream || offset > capacity || count > capacity - offset || offset > SIZE_MAX || count > SIZE_MAX - (size_t)offset ||
        count > SDL_MAX_SINT64 || (count && !buffer)) {
        return SDL_SetError("IO range must fit a live stream and buffer");
    }

    return 1;
}

Sint64 idris_sdl_io_read(SDL_IOStream* stream, void* buffer, Uint64 capacity, Uint64 offset, Uint64 count) {
    if (!valid_io_range(stream, buffer, capacity, offset, count)) return -1;

    return (Sint64)SDL_ReadIO(stream, count ? (Uint8*)buffer + (size_t)offset : buffer, (size_t)count);
}

Sint64 idris_sdl_io_write(SDL_IOStream* stream, const void* buffer, Uint64 capacity, Uint64 offset, Uint64 count) {
    if (!valid_io_range(stream, buffer, capacity, offset, count)) return -1;

    return (Sint64)SDL_WriteIO(stream, count ? (const Uint8*)buffer + (size_t)offset : buffer, (size_t)count);
}
