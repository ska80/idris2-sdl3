/* -*- external-format: utf-8; -*- */

#include "sdl3.h"

#include <stddef.h>

_Static_assert(sizeof(int) == 4, "Bindings require 32-bit C int");

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
        return event->window.windowID;
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
    default:
        return 0;
    }
}
