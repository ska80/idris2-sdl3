||| Unsafe C boundary. Prefer SDL3 for typed handles and null checks.
module SDL3.Raw

%default total

%foreign "C:idris_sdl_init, libidris2_sdl3, sdl3.h"
export
prim__init : Bits32 -> PrimIO Int

%foreign "C:SDL_Quit, libSDL3, SDL3/SDL.h"
export
prim__quit : PrimIO ()

%foreign "C:idris_sdl_get_error, libidris2_sdl3, sdl3.h"
export
prim__getError : PrimIO String

%foreign "C:idris_sdl_is_null, libidris2_sdl3, sdl3.h"
export
prim__isNull : AnyPtr -> PrimIO Int

%foreign "C:SDL_CreateWindow, libSDL3, SDL3/SDL.h"
export
prim__createWindow : String -> Int -> Int -> Bits64 -> PrimIO AnyPtr

%foreign "C:SDL_DestroyWindow, libSDL3, SDL3/SDL.h"
export
prim__destroyWindow : AnyPtr -> PrimIO ()

%foreign "C:SDL_GetWindowID, libSDL3, SDL3/SDL.h"
export
prim__getWindowID : AnyPtr -> PrimIO Bits32

%foreign "C:idris_sdl_create_renderer, libidris2_sdl3, sdl3.h"
export
prim__createRenderer : AnyPtr -> PrimIO AnyPtr

%foreign "C:SDL_DestroyRenderer, libSDL3, SDL3/SDL.h"
export
prim__destroyRenderer : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_draw_color, libidris2_sdl3, sdl3.h"
export
prim__drawColor : AnyPtr -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_sdl_clear, libidris2_sdl3, sdl3.h"
export
prim__clear : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_present, libidris2_sdl3, sdl3.h"
export
prim__present : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_fill_rect, libidris2_sdl3, sdl3.h"
export
prim__fillRect : AnyPtr -> Double -> Double -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_start_text_input, libidris2_sdl3, sdl3.h"
export
prim__startTextInput : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_stop_text_input, libidris2_sdl3, sdl3.h"
export
prim__stopTextInput : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_text_input_active, libidris2_sdl3, sdl3.h"
export
prim__textInputActive : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_event_new, libidris2_sdl3, sdl3.h"
export
prim__eventNew : PrimIO AnyPtr

%foreign "C:idris_sdl_event_free, libidris2_sdl3, sdl3.h"
export
prim__eventFree : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_poll, libidris2_sdl3, sdl3.h"
export
prim__poll : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_event_kind, libidris2_sdl3, sdl3.h"
export
prim__eventKind : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_event_type, libidris2_sdl3, sdl3.h"
export
prim__eventType : AnyPtr -> PrimIO Bits32

%foreign "C:idris_sdl_event_timestamp, libidris2_sdl3, sdl3.h"
export
prim__eventTimestamp : AnyPtr -> PrimIO Bits64

||| Requires a window-close, keyboard, text input, text editing, or supported mouse event.
%foreign "C:idris_sdl_event_window, libidris2_sdl3, sdl3.h"
export
prim__eventWindow : AnyPtr -> PrimIO Bits32

||| Requires a keyboard event.
%foreign "C:idris_sdl_event_scancode, libidris2_sdl3, sdl3.h"
export
prim__eventScancode : AnyPtr -> PrimIO Bits32

||| Requires a keyboard event.
%foreign "C:idris_sdl_event_keycode, libidris2_sdl3, sdl3.h"
export
prim__eventKeycode : AnyPtr -> PrimIO Bits32

||| Requires a keyboard event.
%foreign "C:idris_sdl_event_modifiers, libidris2_sdl3, sdl3.h"
export
prim__eventModifiers : AnyPtr -> PrimIO Bits16

||| Requires a keyboard event.
%foreign "C:idris_sdl_event_repeat, libidris2_sdl3, sdl3.h"
export
prim__eventRepeat : AnyPtr -> PrimIO Int

||| Requires a mouse motion, mouse button, or mouse wheel event.
%foreign "C:idris_sdl_event_mouse_id, libidris2_sdl3, sdl3.h"
export
prim__eventMouseID : AnyPtr -> PrimIO Bits32

||| Requires a mouse motion, mouse button, or mouse wheel event.
%foreign "C:idris_sdl_event_mouse_x, libidris2_sdl3, sdl3.h"
export
prim__eventMouseX : AnyPtr -> PrimIO Double

||| Requires a mouse motion, mouse button, or mouse wheel event.
%foreign "C:idris_sdl_event_mouse_y, libidris2_sdl3, sdl3.h"
export
prim__eventMouseY : AnyPtr -> PrimIO Double

||| Requires a mouse motion event.
%foreign "C:idris_sdl_event_mouse_buttons, libidris2_sdl3, sdl3.h"
export
prim__eventMouseButtons : AnyPtr -> PrimIO Bits32

||| Requires a mouse motion event.
%foreign "C:idris_sdl_event_mouse_dx, libidris2_sdl3, sdl3.h"
export
prim__eventMouseDX : AnyPtr -> PrimIO Double

||| Requires a mouse motion event.
%foreign "C:idris_sdl_event_mouse_dy, libidris2_sdl3, sdl3.h"
export
prim__eventMouseDY : AnyPtr -> PrimIO Double

||| Requires a mouse button event.
%foreign "C:idris_sdl_event_mouse_button, libidris2_sdl3, sdl3.h"
export
prim__eventMouseButton : AnyPtr -> PrimIO Bits8

||| Requires a mouse button event.
%foreign "C:idris_sdl_event_mouse_clicks, libidris2_sdl3, sdl3.h"
export
prim__eventMouseClicks : AnyPtr -> PrimIO Bits8

||| Requires a mouse wheel event.
%foreign "C:idris_sdl_event_wheel_x, libidris2_sdl3, sdl3.h"
export
prim__eventWheelX : AnyPtr -> PrimIO Double

||| Requires a mouse wheel event.
%foreign "C:idris_sdl_event_wheel_y, libidris2_sdl3, sdl3.h"
export
prim__eventWheelY : AnyPtr -> PrimIO Double

||| Requires a mouse wheel event.
%foreign "C:idris_sdl_event_wheel_direction, libidris2_sdl3, sdl3.h"
export
prim__eventWheelDirection : AnyPtr -> PrimIO Bits32

||| Requires a mouse wheel event.
%foreign "C:idris_sdl_event_wheel_integer_x, libidris2_sdl3, sdl3.h"
export
prim__eventWheelIntegerX : AnyPtr -> PrimIO Int32

||| Requires a mouse wheel event.
%foreign "C:idris_sdl_event_wheel_integer_y, libidris2_sdl3, sdl3.h"
export
prim__eventWheelIntegerY : AnyPtr -> PrimIO Int32

||| Requires a text input or text editing event. Copies the UTF-8 text into Idris.
%foreign "C:idris_sdl_event_text, libidris2_sdl3, sdl3.h"
export
prim__eventText : AnyPtr -> PrimIO String

||| Requires a text editing event.
%foreign "C:idris_sdl_event_edit_start, libidris2_sdl3, sdl3.h"
export
prim__eventEditStart : AnyPtr -> PrimIO Int32

||| Requires a text editing event.
%foreign "C:idris_sdl_event_edit_length, libidris2_sdl3, sdl3.h"
export
prim__eventEditLength : AnyPtr -> PrimIO Int32

%foreign "C:SDL_GetTicks, libSDL3, SDL3/SDL.h"
export
prim__ticks : PrimIO Bits64

%foreign "C:SDL_Delay, libSDL3, SDL3/SDL.h"
export
prim__delay : Bits32 -> PrimIO ()
