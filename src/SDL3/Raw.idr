||| Unsafe C boundary. Prefer SDL3 for typed handles and null checks.
module SDL3.Raw

%default total

%foreign "C:idris_sdl_init, libidris2_sdl3, sdl3.h"
export
primInit : Bits32 -> PrimIO Int

%foreign "C:SDL_Quit, libSDL3, SDL3/SDL.h"
export
primQuit : PrimIO ()

%foreign "C:idris_sdl_get_error, libidris2_sdl3, sdl3.h"
export
primGetError : PrimIO String

%foreign "C:idris_sdl_is_null, libidris2_sdl3, sdl3.h"
export
primIsNull : AnyPtr -> PrimIO Int

%foreign "C:SDL_CreateWindow, libSDL3, SDL3/SDL.h"
export
primCreateWindow : String -> Int -> Int -> Bits64 -> PrimIO AnyPtr

%foreign "C:SDL_DestroyWindow, libSDL3, SDL3/SDL.h"
export
primDestroyWindow : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_create_renderer, libidris2_sdl3, sdl3.h"
export
primCreateRenderer : AnyPtr -> PrimIO AnyPtr

%foreign "C:SDL_DestroyRenderer, libSDL3, SDL3/SDL.h"
export
primDestroyRenderer : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_draw_color, libidris2_sdl3, sdl3.h"
export
primDrawColor : AnyPtr -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_sdl_clear, libidris2_sdl3, sdl3.h"
export
primClear : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_present, libidris2_sdl3, sdl3.h"
export
primPresent : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_fill_rect, libidris2_sdl3, sdl3.h"
export
primFillRect : AnyPtr -> Double -> Double -> Double -> Double -> PrimIO Int

%foreign "C:idris_sdl_event_new, libidris2_sdl3, sdl3.h"
export
primEventNew : PrimIO AnyPtr

%foreign "C:idris_sdl_event_free, libidris2_sdl3, sdl3.h"
export
primEventFree : AnyPtr -> PrimIO ()

%foreign "C:idris_sdl_poll, libidris2_sdl3, sdl3.h"
export
primPoll : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_event_kind, libidris2_sdl3, sdl3.h"
export
primEventKind : AnyPtr -> PrimIO Int

%foreign "C:idris_sdl_event_type, libidris2_sdl3, sdl3.h"
export
primEventType : AnyPtr -> PrimIO Bits32

%foreign "C:SDL_GetTicks, libSDL3, SDL3/SDL.h"
export
primTicks : PrimIO Bits64

%foreign "C:SDL_Delay, libSDL3, SDL3/SDL.h"
export
primDelay : Bits32 -> PrimIO ()
