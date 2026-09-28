||| Unsafe C boundary. Prefer SDL3 for typed handles and null checks.
module SDL3.Raw

import Data.Buffer
import System.FFI

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

%foreign "C:idris_sdl_set_window_size, libidris2_sdl3, sdl3.h"
export
prim__setWindowSize : AnyPtr -> Int32 -> Int32 -> PrimIO Int

%foreign "C:idris_sdl_sync_window, libidris2_sdl3, sdl3.h"
export
prim__syncWindow : AnyPtr -> PrimIO Int

%foreign "C:SDL_DestroyWindow, libSDL3, SDL3/SDL.h"
export
prim__destroyWindow : AnyPtr -> PrimIO ()

||| Chez copies SDL's borrowed UTF-8 string. Requires a live window on the main thread.
%foreign "C:SDL_GetWindowTitle, libSDL3, SDL3/SDL.h"
export
prim__getWindowTitle : AnyPtr -> PrimIO String

%foreign "C:idris_sdl_set_window_title, libidris2_sdl3, sdl3.h"
export
prim__setWindowTitle : AnyPtr -> String -> PrimIO Int

||| Full SDL flag mask. Requires a live window on the main thread.
%foreign "C:SDL_GetWindowFlags, libSDL3, SDL3/SDL.h"
export
prim__getWindowFlags : AnyPtr -> PrimIO Bits64

||| Zero means false. Nonzero means true. The adapter converts both C boolean boundaries.
%foreign "C:idris_sdl_set_window_bordered, libidris2_sdl3, sdl3.h"
export
prim__setWindowBordered : AnyPtr -> Int32 -> PrimIO Int

%foreign "C:idris_sdl_set_window_resizable, libidris2_sdl3, sdl3.h"
export
prim__setWindowResizable : AnyPtr -> Int32 -> PrimIO Int

%foreign "C:idris_sdl_show_window, libidris2_sdl3, sdl3.h"
export
prim__showWindow : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_hide_window, libidris2_sdl3, sdl3.h"
export
prim__hideWindow : AnyPtr -> PrimIO Int

%foreign "C:SDL_GetWindowID, libSDL3, SDL3/SDL.h"
export
prim__getWindowID : AnyPtr -> PrimIO Bits32

%foreign "C:idris_sdl_create_renderer, libidris2_sdl3, sdl3.h"
export
prim__createRenderer : AnyPtr -> PrimIO AnyPtr

%foreign "C:SDL_DestroyRenderer, libSDL3, SDL3/SDL.h"
export
prim__destroyRenderer : AnyPtr -> PrimIO ()

%foreign "C:SDL_LoadBMP, libSDL3, SDL3/SDL.h"
export
prim__loadBMP : String -> PrimIO AnyPtr

%foreign "C:SDL_DestroySurface, libSDL3, SDL3/SDL.h"
export
prim__destroySurface : AnyPtr -> PrimIO ()

||| SDL3's public SDL_Texture layout. SDL owns the memory.
||| Treat all fields as read-only. Never read a null or destroyed texture.
public export
NativeTexture : Type
NativeTexture = Struct "SDL_Texture" [("format", Bits32), ("w", Int32), ("h", Int32), ("refcount", Int32)]

%foreign "C:idris_sdl_is_null, libidris2_sdl3, sdl3.h"
export
prim__textureIsNull : NativeTexture -> PrimIO Int

||| Validate with SDL before reading the public dimensions in the IO continuation.
%foreign "C:idris_sdl_get_texture_size, libidris2_sdl3, sdl3.h"
export
prim__getTextureSize : NativeTexture -> PrimIO Int

%foreign "C:SDL_CreateTextureFromSurface, libSDL3, SDL3/SDL.h"
export
prim__createTextureFromSurface : AnyPtr -> AnyPtr -> PrimIO NativeTexture

%foreign "C:idris_sdl_create_target_texture, libidris2_sdl3, sdl3.h"
export
prim__createTargetTexture : AnyPtr -> Int -> Int -> PrimIO NativeTexture

%foreign "C:idris_sdl_create_streaming_texture, libidris2_sdl3, sdl3.h"
export
prim__createStreamingTexture : AnyPtr -> Int -> Int -> PrimIO NativeTexture

||| Size must be the actual buffer capacity. Prefer SDL3.updateTextureRGBA.
%foreign "C:idris_sdl_update_texture_rgba, libidris2_sdl3, sdl3.h"
export
prim__updateTextureRGBA : NativeTexture -> Buffer -> Bits64 -> Int32 -> PrimIO Int

||| Size must be the actual buffer capacity. Pixels start at the source region.
%foreign "C:idris_sdl_update_texture_region_rgba, libidris2_sdl3, sdl3.h"
export
prim__updateTextureRegionRGBA : NativeTexture -> Int32 -> Int32 -> Int32 -> Int32 -> Buffer -> Bits64 -> Int32 -> PrimIO Int

||| Full layout of caller-owned IdrisSDLSize storage. Not an Idris value record.
public export
NativeSize : Type
NativeSize = Struct "IdrisSDLSize" [("width", Int32), ("height", Int32)]

%foreign "C:idris_sdl_size_new, libidris2_sdl3, sdl3.h"
export
prim__newSize : PrimIO NativeSize

%foreign "C:idris_sdl_is_null, libidris2_sdl3, sdl3.h"
export
prim__sizeIsNull : NativeSize -> PrimIO Int

%foreign "C:idris_sdl_size_free, libidris2_sdl3, sdl3.h"
export
prim__freeSize : NativeSize -> PrimIO ()

||| Fill existing storage. Read fields only after a return value of 1.
%foreign "C:idris_sdl_get_window_size, libidris2_sdl3, sdl3.h"
export
prim__getWindowSize : AnyPtr -> NativeSize -> PrimIO Int

%foreign "C:idris_sdl_get_window_size_pixels, libidris2_sdl3, sdl3.h"
export
prim__getWindowSizeInPixels : AnyPtr -> NativeSize -> PrimIO Int

%foreign "C:SDL_DestroyTexture, libSDL3, SDL3/SDL.h"
export
prim__destroyTexture : NativeTexture -> PrimIO ()

%foreign "C:idris_sdl_set_texture_color_mod, libidris2_sdl3, sdl3.h"
export
prim__setTextureColorMod : NativeTexture -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_sdl_set_texture_alpha_mod, libidris2_sdl3, sdl3.h"
export
prim__setTextureAlphaMod : NativeTexture -> Bits8 -> PrimIO Int

||| Returns 0 through 255, or -1 on failure. No borrowed output pointer escapes.
%foreign "C:idris_sdl_get_texture_alpha_mod, libidris2_sdl3, sdl3.h"
export
prim__getTextureAlphaMod : NativeTexture -> PrimIO Int32

||| Raw SDL enum arguments. Composition does not test renderer support.
%foreign "C:SDL_ComposeCustomBlendMode, libSDL3, SDL3/SDL.h"
export
prim__composeBlendMode : Int32 -> Int32 -> Int32 -> Int32 -> Int32 -> Int32 -> PrimIO Bits32

%foreign "C:idris_sdl_set_texture_blend_mode, libidris2_sdl3, sdl3.h"
export
prim__setTextureBlendMode : NativeTexture -> Bits32 -> PrimIO Int

||| Unsigned 32-bit mode code, or -1 on failure. The marker cannot collide with a mode code.
%foreign "C:idris_sdl_get_texture_blend_mode, libidris2_sdl3, sdl3.h"
export
prim__getTextureBlendMode : NativeTexture -> PrimIO Int64

%foreign "C:idris_sdl_set_texture_scale_mode, libidris2_sdl3, sdl3.h"
export
prim__setTextureScaleMode : NativeTexture -> Int -> PrimIO Int

||| A signed 32-bit mode code, or -2147483649 on failure. The marker is outside the code range.
%foreign "C:idris_sdl_get_texture_scale_mode, libidris2_sdl3, sdl3.h"
export
prim__getTextureScaleMode : NativeTexture -> PrimIO Int64

||| Borrowed pointer to the current target. Null means the window target.
||| Requires a live renderer on the main thread. Does not transfer ownership.
%foreign "C:SDL_GetRenderTarget, libSDL3, SDL3/SDL.h"
export
prim__getRenderTarget : AnyPtr -> PrimIO NativeTexture

%foreign "C:idris_sdl_set_render_target, libidris2_sdl3, sdl3.h"
export
prim__setRenderTarget : AnyPtr -> NativeTexture -> PrimIO Int

%foreign "C:idris_sdl_reset_render_target, libidris2_sdl3, sdl3.h"
export
prim__resetRenderTarget : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_render_texture, libidris2_sdl3, sdl3.h"
export
prim__renderTexture : AnyPtr -> NativeTexture -> PrimIO Int

%foreign "C:idris_sdl_render_texture_rect, libidris2_sdl3, sdl3.h"
export
prim__renderTextureRect : AnyPtr -> NativeTexture -> Double -> Double -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_render_texture_source, libidris2_sdl3, sdl3.h"
export
prim__renderTextureSource : AnyPtr -> NativeTexture -> Double -> Double -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_render_texture_region, libidris2_sdl3, sdl3.h"
export
prim__renderTextureRegion : AnyPtr -> NativeTexture -> Double -> Double -> Double -> Double ->
                           Double -> Double -> Double -> Double -> PrimIO Int

||| Option bits 0, 1, 2 select source, destination, and center structs, or NULL.
||| Bits 3 and 4 encode SDL flip flags.
%foreign "C:idris_sdl_render_texture_rotated, libidris2_sdl3, sdl3.h"
export
prim__renderTextureRotated : AnyPtr -> NativeTexture -> Bits32 -> Double -> Double -> Double -> Double ->
                            Double -> Double -> Double -> Double -> Double -> Double -> Double -> PrimIO Int

||| Full layout of the adapter's double-valued result, not SDL's float-valued point.
public export
NativePoint : Type
NativePoint = Struct "IdrisSDLPoint" [("x", Double), ("y", Double)]

%foreign "C:idris_sdl_coordinate_new, libidris2_sdl3, sdl3.h"
export
prim__coordinateNew : PrimIO NativePoint

%foreign "C:idris_sdl_is_null, libidris2_sdl3, sdl3.h"
export
prim__coordinateIsNull : NativePoint -> PrimIO Int

%foreign "C:idris_sdl_coordinate_free, libidris2_sdl3, sdl3.h"
export
prim__coordinateFree : NativePoint -> PrimIO ()

||| Requires a live coordinate buffer as the final argument.
%foreign "C:idris_sdl_render_coordinates_from_window, libidris2_sdl3, sdl3.h"
export
prim__renderCoordinatesFromWindow : AnyPtr -> Double -> Double -> NativePoint -> PrimIO Int

||| Requires a live coordinate buffer as the final argument.
%foreign "C:idris_sdl_render_coordinates_to_window, libidris2_sdl3, sdl3.h"
export
prim__renderCoordinatesToWindow : AnyPtr -> Double -> Double -> NativePoint -> PrimIO Int

%foreign "C:idris_sdl_set_render_scale, libidris2_sdl3, sdl3.h"
export
prim__setRenderScale : AnyPtr -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_set_render_logical_presentation, libidris2_sdl3, sdl3.h"
export
prim__setRenderLogicalPresentation : AnyPtr -> Int32 -> Int32 -> Int -> PrimIO Int

%foreign "C:idris_sdl_set_render_viewport, libidris2_sdl3, sdl3.h"
export
prim__setRenderViewport : AnyPtr -> Int32 -> Int32 -> Int32 -> Int32 -> PrimIO Int

%foreign "C:idris_sdl_reset_render_viewport, libidris2_sdl3, sdl3.h"
export
prim__resetRenderViewport : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_set_render_clip_rect, libidris2_sdl3, sdl3.h"
export
prim__setRenderClipRect : AnyPtr -> Int32 -> Int32 -> Int32 -> Int32 -> PrimIO Int

%foreign "C:idris_sdl_reset_render_clip_rect, libidris2_sdl3, sdl3.h"
export
prim__resetRenderClipRect : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_set_draw_blend_mode, libidris2_sdl3, sdl3.h"
export
prim__setDrawBlendMode : AnyPtr -> Bits32 -> PrimIO Int

||| Unsigned 32-bit blend code, or -1 on failure. Requires a live renderer on the main thread.
%foreign "C:idris_sdl_get_draw_blend_mode, libidris2_sdl3, sdl3.h"
export
prim__getDrawBlendMode : AnyPtr -> PrimIO Int64

%foreign "C:idris_sdl_draw_color, libidris2_sdl3, sdl3.h"
export
prim__drawColor : AnyPtr -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_sdl_clear, libidris2_sdl3, sdl3.h"
export
prim__clear : AnyPtr -> PrimIO Int

||| Accepts -1 (adaptive), 0 (disabled), or a positive 32-bit C int interval.
%foreign "C:idris_sdl_set_render_vsync, libidris2_sdl3, sdl3.h"
export
prim__setRenderVSync : AnyPtr -> Int64 -> PrimIO Int

||| Returns -2 on failure, otherwise SDL's VSync value (-1, 0, or positive).
%foreign "C:idris_sdl_get_render_vsync, libidris2_sdl3, sdl3.h"
export
prim__getRenderVSync : AnyPtr -> PrimIO Int32

%foreign "C:idris_sdl_present, libidris2_sdl3, sdl3.h"
export
prim__present : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_points_new, libidris2_sdl3, sdl3.h"
export
prim__pointsNew : Bits32 -> PrimIO AnyPtr

%foreign "C:idris_sdl_points_free, libidris2_sdl3, sdl3.h"
export
prim__pointsFree : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_points_set, libidris2_sdl3, sdl3.h"
export
prim__pointsSet : AnyPtr -> Bits32 -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_draw_points, libidris2_sdl3, sdl3.h"
export
prim__drawPoints : AnyPtr -> AnyPtr -> Bits32 -> PrimIO Int

%foreign "C:idris_sdl_draw_lines, libidris2_sdl3, sdl3.h"
export
prim__drawLines : AnyPtr -> AnyPtr -> Bits32 -> PrimIO Int

%foreign "C:idris_sdl_rects_new, libidris2_sdl3, sdl3.h"
export
prim__rectsNew : Bits32 -> PrimIO AnyPtr

%foreign "C:idris_sdl_rects_free, libidris2_sdl3, sdl3.h"
export
prim__rectsFree : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_rects_set, libidris2_sdl3, sdl3.h"
export
prim__rectsSet : AnyPtr -> Bits32 -> Double -> Double -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_draw_rects, libidris2_sdl3, sdl3.h"
export
prim__drawRects : AnyPtr -> AnyPtr -> Bits32 -> PrimIO Int

%foreign "C:idris_sdl_fill_rects, libidris2_sdl3, sdl3.h"
export
prim__fillRects : AnyPtr -> AnyPtr -> Bits32 -> PrimIO Int

%foreign "C:idris_sdl_draw_point, libidris2_sdl3, sdl3.h"
export
prim__drawPoint : AnyPtr -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_draw_line, libidris2_sdl3, sdl3.h"
export
prim__drawLine : AnyPtr -> Double -> Double -> Double -> Double -> PrimIO Int

||| A zero presence flag passes NULL to SDL_RenderRect.
%foreign "C:idris_sdl_draw_rect, libidris2_sdl3, sdl3.h"
export
prim__drawRect : AnyPtr -> Int32 -> Double -> Double -> Double -> Double -> PrimIO Int

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

%foreign "C:idris_sdl_set_text_input_area, libidris2_sdl3, sdl3.h"
export
prim__setTextInputArea : AnyPtr -> Int32 -> Int32 -> Int32 -> Int32 -> Int32 -> PrimIO Int

%foreign "C:idris_sdl_clear_text_input_area, libidris2_sdl3, sdl3.h"
export
prim__clearTextInputArea : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_clear_composition, libidris2_sdl3, sdl3.h"
export
prim__clearComposition : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_event_new, libidris2_sdl3, sdl3.h"
export
prim__eventNew : PrimIO AnyPtr

%foreign "C:idris_sdl_event_free, libidris2_sdl3, sdl3.h"
export
prim__eventFree : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_poll, libidris2_sdl3, sdl3.h"
export
prim__poll : AnyPtr -> PrimIO Int

||| Requires a live event buffer. Returns 1 on success, 0 on failure.
%foreign "C:idris_sdl_wait_event, libidris2_sdl3, sdl3.h"
export
prim__waitEvent : AnyPtr -> PrimIO Int

||| Returns 1 for an event, 0 for timeout, or -1 for an error.
||| Clears SDL's error before waiting. Requires a live event buffer.
%foreign "C:idris_sdl_wait_event_timeout, libidris2_sdl3, sdl3.h"
export
prim__waitEventTimeout : AnyPtr -> Bits32 -> PrimIO Int

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
||| Requires a window event. For size events, data1 is width and data2 is height.
%foreign "C:idris_sdl_event_window_data1, libidris2_sdl3, sdl3.h"
export
prim__eventWindowData1 : AnyPtr -> PrimIO Int32

||| Requires a window event. For size events, data1 is width and data2 is height.
%foreign "C:idris_sdl_event_window_data2, libidris2_sdl3, sdl3.h"
export
prim__eventWindowData2 : AnyPtr -> PrimIO Int32

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

%foreign "C:SDL_GetTicksNS, libSDL3, SDL3/SDL.h"
export
prim__ticksNS : PrimIO Bits64

%foreign "C:SDL_GetPerformanceCounter, libSDL3, SDL3/SDL.h"
export
prim__performanceCounter : PrimIO Bits64

%foreign "C:SDL_GetPerformanceFrequency, libSDL3, SDL3/SDL.h"
export
prim__performanceFrequency : PrimIO Bits64

%foreign "C:SDL_DelayNS, libSDL3, SDL3/SDL.h"
export
prim__delayNS : Bits64 -> PrimIO ()

%foreign "C:SDL_DelayPrecise, libSDL3, SDL3/SDL.h"
export
prim__delayPrecise : Bits64 -> PrimIO ()

%foreign "C:SDL_Delay, libSDL3, SDL3/SDL.h"
export
prim__delay : Bits32 -> PrimIO ()
