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

%foreign "C:SDL_GetTicks, libSDL3, SDL3/SDL.h"
export
prim__ticks : PrimIO Bits64

%foreign "C:SDL_Delay, libSDL3, SDL3/SDL.h"
export
prim__delay : Bits32 -> PrimIO ()
