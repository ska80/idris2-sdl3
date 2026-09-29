#include "core.h"
#include "subset_fixtures.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

static void gamepads(void) {
    Uint32 id = idris_test_attach_gamepad();
    assert(id);

    IdrisSDLGamepads* list = idris_sdl_gamepads_new();
    assert(list && list->count > 0);

    bool found = false;

    for (Sint32 i = 0; i < list->count; ++i)
        if (idris_sdl_gamepads_at(list, (Uint32)i) == id) found = true;

    assert(found && !idris_sdl_gamepads_at(list, (Uint32)list->count));

    idris_sdl_gamepads_free(list);

    SDL_Gamepad* pad = SDL_OpenGamepad(id);

    assert(pad && idris_sdl_gamepad_connected(pad));
    assert(idris_test_gamepad_input(-32768, 1));
    assert(SDL_GetGamepadAxis(pad, SDL_GAMEPAD_AXIS_LEFTX) == -32768);
    assert(idris_sdl_gamepad_button(pad, SDL_GAMEPAD_BUTTON_SOUTH));
    assert(idris_sdl_gamepad_rumble(pad, 123, 456, 1000));
    assert(idris_test_gamepad_rumble() == ((123u << 16) | 456));
    assert(idris_test_gamepad_input(32767, 0));
    assert(SDL_GetGamepadAxis(pad, SDL_GAMEPAD_AXIS_LEFTX) == 32767);
    assert(!idris_sdl_gamepad_button(pad, SDL_GAMEPAD_BUTTON_SOUTH));
    assert(idris_test_detach_gamepad(id));
    assert(!idris_sdl_gamepad_connected(pad));

    SDL_CloseGamepad(pad);

    assert(!SDL_OpenGamepad(0));
    assert(!idris_sdl_gamepad_connected(NULL));
    assert(!idris_sdl_gamepad_rumble(NULL, 1, 1, 1));
}

static size_t SDLCALL short_write(void* userdata, const void* ptr, size_t count, SDL_IOStatus* status) {
    (void)userdata;
    (void)ptr;
    *status = SDL_IO_STATUS_ERROR;
    SDL_SetError("test partial write");

    return count > 2 ? 2 : count;
}

static bool SDLCALL failed_close(void* userdata) {
    *(int*)userdata += 1;

    return SDL_SetError("test close failure");
}

static void io_ranges(void) {
    SDL_IOStream* io = SDL_IOFromDynamicMem();
    assert(io);

    Uint8 src[] = {1, 2, 3, 4}, guarded[] = {77, 0, 0, 0, 0, 88};
    assert(idris_sdl_io_write(io, src, sizeof(src), 0, 4) == 4);

    src[0] = 99;

    assert(SDL_GetIOSize(io) == 4);
    assert(SDL_SeekIO(io, 0, SDL_IO_SEEK_SET) == 0);
    assert(idris_sdl_io_read(io, guarded, sizeof(guarded), 1, 4) == 4);
    assert(guarded[0] == 77 && guarded[1] == 1 && guarded[4] == 4 && guarded[5] == 88);
    assert(idris_sdl_io_read(io, guarded, sizeof(guarded), 0, 1) == 0);
    assert(SDL_GetIOStatus(io) == SDL_IO_STATUS_EOF);
    assert(idris_sdl_io_read(io, guarded, sizeof(guarded), 6, 0) == 0);
    assert(SDL_GetIOStatus(io) == SDL_IO_STATUS_EOF); /* Zero transfer preserves status. */
    assert(idris_sdl_io_read(io, guarded, sizeof(guarded), 5, 2) == -1);
    assert(idris_sdl_io_write(io, src, 4, SDL_MAX_UINT64, 1) == -1);
    assert(idris_sdl_io_write(io, src, SDL_MAX_UINT64, 0, SDL_MAX_UINT64) == -1);
    assert(idris_sdl_io_read(io, NULL, 4, 0, 1) == -1);
    assert(idris_sdl_io_read(NULL, guarded, 6, 0, 1) == -1);
    assert(idris_sdl_io_flush(io));
    assert(idris_sdl_io_close(io));

    io = SDL_IOFromConstMem(src, sizeof(src));
    assert(io);
    assert(idris_sdl_io_write(io, src, sizeof(src), 0, 1) == 0);
    assert(SDL_GetIOStatus(io) == SDL_IO_STATUS_READONLY);
    assert(idris_sdl_io_close(io));

    SDL_IOStreamInterface iface;
    SDL_INIT_INTERFACE(&iface);

    iface.write = short_write;
    iface.close = failed_close;

    int closed = 0;
    io         = SDL_OpenIO(&iface, &closed);
    assert(io);
    assert(idris_sdl_io_write(io, src, sizeof(src), 0, 4) == 2);
    assert(SDL_GetIOStatus(io) == SDL_IO_STATUS_ERROR);
    assert(strcmp(SDL_GetError(), "test partial write") == 0);
    assert(!idris_sdl_io_close(io));
    assert(closed == 1 && strcmp(SDL_GetError(), "test close failure") == 0);
    /* SDL frees the stream even after this close failure. Do not access it again. */
}

static void mouse_clipboard_events(void) {
    SDL_Window* window = SDL_CreateWindow("subset", 32, 32, SDL_WINDOW_HIDDEN);
    assert(window);

    int requested = idris_sdl_relative_mouse(window, 1);

    if (requested) assert(idris_sdl_relative_mouse_enabled(window));

    assert(idris_sdl_relative_mouse(window, 0));
    assert(!idris_sdl_relative_mouse_enabled(window));
    assert(!idris_sdl_relative_mouse(NULL, 1));
    assert(idris_sdl_hide_cursor() && !idris_sdl_cursor_visible());
    assert(idris_sdl_show_cursor() && idris_sdl_cursor_visible());

    SDL_Cursor* cursor = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_POINTER);
    if (cursor) {
        assert(idris_sdl_set_cursor(cursor));
        assert(idris_sdl_default_cursor());
        SDL_DestroyCursor(cursor);
    }

    (void)idris_sdl_capture_mouse(0); /* Dummy support varies. */
    assert(idris_sdl_clipboard_set("clipboard λ"));
    assert(idris_sdl_clipboard_has_text());

    SDL_SetError("stale");

    char* copy = idris_sdl_clipboard_get();

    assert(copy && strcmp(copy, "clipboard λ") == 0);
    assert(idris_sdl_clipboard_set(""));
    assert(strcmp(copy, "clipboard λ") == 0);

    SDL_free(copy);

    assert(!idris_sdl_clipboard_has_text());
    copy = idris_sdl_clipboard_get();
    assert(copy && !copy[0]);

    SDL_free(copy);

    for (int kind = 0; kind <= 10; ++kind) {
        assert(idris_test_subset_event(kind));

        SDL_Event event;

        assert(SDL_PeepEvents(&event, 1, SDL_GETEVENT, SDL_EVENT_FIRST, SDL_EVENT_LAST) == 1);
        assert(idris_sdl_event_kind(&event) == kind + 27);
        assert(idris_sdl_event_timestamp(&event) == 0x100000002ull);

        if (kind < 6) assert(idris_sdl_event_gamepad(&event) == 0x80000001u);

        if (kind == 3) {
            assert(idris_sdl_event_gamepad_control(&event) == 255);
            assert(idris_sdl_event_gamepad_value(&event) == -32768);
        }

        if (kind >= 6) {
            assert(idris_sdl_event_window(&event) == 0xffffffffu);
            assert(idris_sdl_event_drop_x(&event) == -12.5);
            assert(idris_sdl_event_drop_y(&event) == 100.25);
            assert(strcmp(idris_sdl_event_drop_source(&event), "source Ω") == 0);
        }
    }

    SDL_Event empty = {0};
    empty.type      = SDL_EVENT_DROP_FILE;

    assert(idris_sdl_event_window(&empty) == 0);
    assert(!idris_sdl_event_drop_data(&empty)[0] && !idris_sdl_event_drop_source(&empty)[0]);

    SDL_DestroyWindow(window);
}

int main(void) {
    assert(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD));

    gamepads();
    io_ranges();
    mouse_clipboard_events();

    SDL_Quit();

    puts("Core subset native tests passed");

    return 0;
}
