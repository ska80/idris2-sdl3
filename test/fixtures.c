#define _POSIX_C_SOURCE 200809L

#include "fixtures.h"
#include <SDL3/SDL.h>
#include <stdlib.h>
#include <unistd.h>

SDL_Texture* idris_test_texture_fields(Sint32 width, Sint32 height) {
    static SDL_Texture layout;
    layout = (SDL_Texture){.format = (SDL_PixelFormat)0x89abcdefu, .w = width, .h = height, .refcount = 42};

    return &layout;
}

SDL_Texture* idris_test_null_texture(void) {
    return NULL;
}

int idris_test_window_style(Uint32 identifier, int bordered, int resizable) {
    SDL_Window* window = SDL_GetWindowFromID(identifier);

    if (!window) return 0;

    SDL_WindowFlags flags = SDL_GetWindowFlags(window);

    return ((flags & SDL_WINDOW_BORDERLESS) == 0) == (bordered != 0) && ((flags & SDL_WINDOW_RESIZABLE) != 0) == (resizable != 0);
}

Uint32 idris_test_compose_blend(int slot, int choice) {
    static const SDL_BlendFactor    factors[]    = {SDL_BLENDFACTOR_ZERO,      SDL_BLENDFACTOR_ONE,
                                                    SDL_BLENDFACTOR_SRC_COLOR, SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR,
                                                    SDL_BLENDFACTOR_SRC_ALPHA, SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                                    SDL_BLENDFACTOR_DST_COLOR, SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR,
                                                    SDL_BLENDFACTOR_DST_ALPHA, SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA};
    static const SDL_BlendOperation operations[] = {SDL_BLENDOPERATION_ADD, SDL_BLENDOPERATION_SUBTRACT, SDL_BLENDOPERATION_REV_SUBTRACT,
                                                    SDL_BLENDOPERATION_MINIMUM, SDL_BLENDOPERATION_MAXIMUM};
    SDL_BlendFactor                 src_rgb = SDL_BLENDFACTOR_ONE, dst_rgb = SDL_BLENDFACTOR_ZERO;
    SDL_BlendFactor                 src_a = SDL_BLENDFACTOR_SRC_ALPHA, dst_a = SDL_BLENDFACTOR_DST_ALPHA;
    SDL_BlendOperation              rgb_op = SDL_BLENDOPERATION_ADD, alpha_op = SDL_BLENDOPERATION_MAXIMUM;

    if (slot < 0 || slot > 5 || choice < 0 || choice >= ((slot == 2 || slot == 5) ? 5 : 10)) return SDL_BLENDMODE_INVALID;

    switch (slot) {
    case 0:
        src_rgb = factors[choice];
        break;
    case 1:
        dst_rgb = factors[choice];
        break;
    case 2:
        rgb_op = operations[choice];
        break;
    case 3:
        src_a = factors[choice];
        break;
    case 4:
        dst_a = factors[choice];
        break;
    case 5:
        alpha_op = operations[choice];
        break;
    }
    return SDL_ComposeCustomBlendMode(src_rgb, dst_rgb, rgb_op, src_a, dst_a, alpha_op);
}

void idris_test_size_fields(IdrisSDLSize* size, Sint32 width, Sint32 height) {
    size->width  = width;
    size->height = height;
}

/* Used only on the main thread. No callback enters Idris. */
static SDL_Texture* watched_targets[3];

static const char* target_watch_names[3] = {"idris.test.target.0", "idris.test.target.1", "idris.test.target.2"};

static void SDLCALL target_destroyed(void* userdata, void* value) {
    (void)value;
    *(SDL_Texture**)userdata = NULL;
}

int idris_test_watch_target(Uint32 identifier, int slot) {
    if (slot < 0 || slot >= 3 || watched_targets[slot]) return SDL_SetError("Target watch slot is invalid or occupied");

    SDL_Window*   window   = SDL_GetWindowFromID(identifier);
    SDL_Renderer* renderer = window ? SDL_GetRenderer(window) : NULL;
    SDL_Texture*  texture  = renderer ? SDL_GetRenderTarget(renderer) : NULL;

    if (!texture) return SDL_SetError("No target texture is selected for observation");

    SDL_PropertiesID properties = SDL_GetTextureProperties(texture);

    if (!properties) return 0;
    if (!SDL_SetPointerPropertyWithCleanup(properties, target_watch_names[slot], &watched_targets[slot], target_destroyed,
                                           &watched_targets[slot]))
        return 0;

    watched_targets[slot] = texture;

    return 1;
}

int idris_test_target_alive(int slot) {
    return slot >= 0 && slot < 3 ? watched_targets[slot] != NULL : -1;
}

int idris_test_target_selected(Uint32 identifier, int slot) {
    SDL_Window*   window   = SDL_GetWindowFromID(identifier);
    SDL_Renderer* renderer = window ? SDL_GetRenderer(window) : NULL;

    if (!renderer) return 0;

    SDL_Texture* selected = SDL_GetRenderTarget(renderer);

    if (slot == -1) return selected == NULL;

    return slot >= 0 && slot < 3 && watched_targets[slot] && selected == watched_targets[slot];
}

/* Linux test fixture. Return a unique file path, copied by Idris. */
char* idris_test_make_bmp(void) {
    static char path[64];

    SDL_strlcpy(path, "/tmp/idris2-sdl3-bmp-XXXXXX", sizeof(path));

    int fd = mkstemp(path);

    if (fd < 0) return "";

    close(fd);

    SDL_Surface* surface = SDL_CreateSurface(8, 4, SDL_PIXELFORMAT_RGBA32);

    if (!surface) {
        unlink(path);
        return "";
    }

    const SDL_Rect left  = {0, 0, 4, 4};
    const SDL_Rect right = {4, 0, 4, 4};

    int ok = SDL_FillSurfaceRect(surface, &left, SDL_MapSurfaceRGBA(surface, 220, 30, 40, 255)) &&
             SDL_FillSurfaceRect(surface, &right, SDL_MapSurfaceRGBA(surface, 20, 210, 60, 255)) && SDL_SaveBMP(surface, path);

    SDL_DestroySurface(surface);

    if (!ok) {
        unlink(path);

        return "";
    }

    return path;
}

int idris_test_text_input_area(Uint32 window_id, Sint32 x, Sint32 y, Sint32 w, Sint32 h, Sint32 cursor) {
    SDL_Rect area;
    int      actual_cursor;

    SDL_Window* window = SDL_GetWindowFromID(window_id);

    if (!window || !SDL_GetTextInputArea(window, &area, &actual_cursor)) return 0;

    return area.x == x && area.y == y && area.w == w && area.h == h && actual_cursor == cursor;
}

/* Readback allocates only in tests, never in the binding's draw path. */
int idris_test_pixel_near(Uint32 window_id, int x, int y, Uint8 r, Uint8 g, Uint8 b, Uint8 a, Uint8 tolerance) {
    SDL_Window* window = SDL_GetWindowFromID(window_id);

    if (!window) return 0;

    SDL_Renderer* renderer = SDL_GetRenderer(window);

    if (!renderer) return 0;

    const SDL_Rect rect = {x, y, 1, 1};

    SDL_Surface* surface = SDL_RenderReadPixels(renderer, &rect);

    if (!surface) return 0;

    Uint8 actual_r, actual_g, actual_b, actual_a;
    int   ok = SDL_ReadSurfacePixel(surface, 0, 0, &actual_r, &actual_g, &actual_b, &actual_a);

    SDL_DestroySurface(surface);

    return ok && abs((int)actual_r - r) <= tolerance && abs((int)actual_g - g) <= tolerance && abs((int)actual_b - b) <= tolerance &&
           abs((int)actual_a - a) <= tolerance;
}

int idris_test_pixel(Uint32 window_id, int x, int y, Uint8 r, Uint8 g, Uint8 b, Uint8 a) {
    return idris_test_pixel_near(window_id, x, y, r, g, b, a, 0);
}

static Uint32 SDLCALL queue_delayed_quit(void* userdata, SDL_TimerID timer, Uint32 interval) {
    (void)userdata;
    (void)timer;
    (void)interval;

    SDL_Event event = {0};
    event.type      = SDL_EVENT_QUIT;

    SDL_PushEvent(&event);

    return 0;
}

Uint32 idris_test_schedule_quit(void) {
    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);

    return SDL_AddTimer(10, queue_delayed_quit, NULL);
}

void idris_test_cancel_timer(Uint32 timer) {
    SDL_RemoveTimer(timer);
}

/* Query by identifier, without dereferencing a destroyed handle. */
int idris_test_window_state(Uint32 identifier) {
    SDL_Window* window = SDL_GetWindowFromID(identifier);

    if (!window) return 0;

    return SDL_GetRenderer(window) ? 2 : 1;
}

/* Test-only events. Keep these symbols out of the binding library. */
int idris_test_queue_event(int kind) {
    static char text[256];

    SDL_Event event = {0};

    SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);

    /* Invalidate text from the previous fixture to test Idris string ownership. */
    text[0] = '\0';

    event.common.timestamp = SDL_UINT64_C(0x100000002);

    switch (kind) {
    case 1:
        event.type = SDL_EVENT_QUIT;
        break;

    case 2:
        event.type            = SDL_EVENT_WINDOW_CLOSE_REQUESTED;
        event.window.windowID = 0x80000001u;
        break;

    case 3:

    case 4:
        event.type         = kind == 3 ? SDL_EVENT_KEY_DOWN : SDL_EVENT_KEY_UP;
        event.key.windowID = 0x80000001u;
        event.key.scancode = SDL_SCANCODE_ESCAPE;
        event.key.key      = SDLK_ESCAPE;
        event.key.mod      = SDL_KMOD_LSHIFT | SDL_KMOD_RCTRL;
        event.key.down     = kind == 3;
        event.key.repeat   = kind == 3;
        break;

    case 5:
        event.type = SDL_EVENT_USER;
        break;

    case 6:
        event.type            = SDL_EVENT_MOUSE_MOTION;
        event.motion.windowID = 0x80000001u;
        event.motion.which    = 0xfffffffeu;
        event.motion.state    = 0x80000000u | SDL_BUTTON_LMASK | SDL_BUTTON_RMASK;
        event.motion.x        = 12.5f;
        event.motion.y        = -7.25f;
        event.motion.xrel     = -1.5f;
        event.motion.yrel     = 2.75f;
        break;

    case 7:
    case 8:
    case 9:
        event.type            = kind == 8 ? SDL_EVENT_MOUSE_BUTTON_UP : SDL_EVENT_MOUSE_BUTTON_DOWN;
        event.button.windowID = 0x80000001u;
        event.button.which    = 0xfffffffeu;
        event.button.button   = kind == 9 ? 200 : SDL_BUTTON_RIGHT;
        event.button.down     = kind != 8;
        event.button.clicks   = 2;
        event.button.x        = -0.5f;
        event.button.y        = 100.25f;
        break;

    case 10:
    case 11:
    case 12:
        event.type            = SDL_EVENT_MOUSE_WHEEL;
        event.wheel.windowID  = 0x80000001u;
        event.wheel.which     = 0xfffffffeu;
        event.wheel.x         = kind == 11 ? 2.5f : -2.5f;
        event.wheel.y         = kind == 11 ? -3.75f : 3.75f;
        event.wheel.direction = kind == 10 ? SDL_MOUSEWHEEL_NORMAL : kind == 11 ? SDL_MOUSEWHEEL_FLIPPED : (SDL_MouseWheelDirection)42;
        event.wheel.mouse_x   = -16.5f;
        event.wheel.mouse_y   = 99.25f;
        event.wheel.integer_x = kind == 12 ? SDL_MIN_SINT32 : kind == 11 ? 2 : -2;
        event.wheel.integer_y = kind == 12 ? SDL_MAX_SINT32 : kind == 11 ? -3 : 3;
        break;

    case 13:
    case 15:
    case 17:
        event.type          = SDL_EVENT_TEXT_INPUT;
        event.text.windowID = 0x80000001u;

        if (kind == 13) SDL_strlcpy(text, "héllo 世界 🎮", sizeof(text));

        if (kind == 17) {
            SDL_memset(text, 'x', 200);
            text[200] = '\0';
        }

        event.text.text = text;
        break;

    case 14:
    case 16:
        event.type          = SDL_EVENT_TEXT_EDITING;
        event.edit.windowID = 0x80000001u;

        if (kind == 14) SDL_strlcpy(text, "にほん", sizeof(text));

        event.edit.text   = text;
        event.edit.start  = kind == 14 ? 1 : -1;
        event.edit.length = kind == 14 ? 2 : -1;
        break;

    case 47:
    case 48:
    case 49:
    case 50:
        event.type            = (kind == 47 || kind == 49) ? SDL_EVENT_WINDOW_ENTER_FULLSCREEN : SDL_EVENT_WINDOW_LEAVE_FULLSCREEN;
        event.window.windowID = kind >= 49 ? 0 : kind == 47 ? 0x80000001u : 0xffffffffu;
        event.window.data1    = SDL_MIN_SINT32;
        event.window.data2    = SDL_MAX_SINT32;
        break;

    case 44:
    case 45:
    case 46:
        event.type            = SDL_EVENT_WINDOW_MOVED;
        event.window.windowID = kind == 44 ? 0x80000001u : kind == 45 ? 0 : 0xffffffffu;
        event.window.data1    = kind == 44 ? -320 : kind == 45 ? 0 : SDL_MIN_SINT32;
        event.window.data2    = kind == 44 ? 240 : kind == 45 ? 0 : SDL_MAX_SINT32;
        break;

    case 38:
    case 39:
    case 40:
    case 41:
    case 42:
    case 43: {
        const Uint32 types[]  = {SDL_EVENT_WINDOW_SHOWN, SDL_EVENT_WINDOW_HIDDEN, SDL_EVENT_WINDOW_EXPOSED};
        event.type            = types[(kind - 38) % 3];
        event.window.windowID = kind >= 41 ? 0 : kind == 38 ? 0x80000001u : kind == 39 ? 0xffffffffu : 42;
        event.window.data1    = SDL_MIN_SINT32;
        event.window.data2    = SDL_MAX_SINT32;
        break;
    }

    case 32:
    case 33:
    case 34:
    case 35:
    case 36:
    case 37: {
        const Uint32 types[]  = {SDL_EVENT_WINDOW_MINIMIZED, SDL_EVENT_WINDOW_MAXIMIZED, SDL_EVENT_WINDOW_RESTORED};
        event.type            = types[(kind - 32) % 3];
        event.window.windowID = kind >= 35 ? 0 : kind == 32 ? 0x80000001u : kind == 33 ? 0xffffffffu : 42;
        event.window.data1    = SDL_MIN_SINT32;
        event.window.data2    = SDL_MAX_SINT32;
        break;
    }

    case 28:
    case 29:
    case 30:
    case 31:
        event.type            = (kind == 28 || kind == 30) ? SDL_EVENT_WINDOW_MOUSE_ENTER : SDL_EVENT_WINDOW_MOUSE_LEAVE;
        event.window.windowID = kind >= 30 ? 0 : kind == 28 ? 0x80000001u : 0xffffffffu;
        /* These are window events, not mouse motion events. */
        event.window.data1    = SDL_MIN_SINT32;
        event.window.data2    = SDL_MAX_SINT32;
        break;

    case 24:
    case 25:
    case 26:
    case 27:
        event.type            = (kind == 24 || kind == 26) ? SDL_EVENT_WINDOW_FOCUS_GAINED : SDL_EVENT_WINDOW_FOCUS_LOST;
        event.window.windowID = kind >= 26 ? 0 : kind == 24 ? 0x80000001u : 0xffffffffu;
        event.window.data1    = SDL_MIN_SINT32;
        event.window.data2    = SDL_MAX_SINT32;
        break;

    case 22:
    case 23:
        event.type            = SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED;
        event.window.windowID = kind == 22 ? 0x80000001u : 0;
        /* No scale payload exists. These fields must not become dimensions or a factor. */
        event.window.data1    = SDL_MIN_SINT32;
        event.window.data2    = SDL_MAX_SINT32;
        break;

    case 18:
    case 19:
    case 20:
    case 21:
        event.type            = kind == 18 ? SDL_EVENT_WINDOW_RESIZED : SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED;
        event.window.windowID = 0x80000001u;
        event.window.data1    = kind == 18 ? 800 : kind == 19 ? 1600 : kind == 20 ? 0 : SDL_MIN_SINT32;
        event.window.data2    = kind == 18 ? 600 : kind == 19 ? 1200 : kind == 20 ? 0 : SDL_MAX_SINT32;
        break;

    default:
        return 0;
    }

    return SDL_PeepEvents(&event, 1, SDL_ADDEVENT, 0, 0) == 1;
}
