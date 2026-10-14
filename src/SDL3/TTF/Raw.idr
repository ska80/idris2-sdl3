||| Unsafe SDL3_ttf boundary. Prefer SDL3.TTF.
module SDL3.TTF.Raw

import SDL3.Raw

import System.FFI

%default total

%foreign "C:idris_ttf_init, libidris2_sdl3_ttf, ttf.h"
export
prim__initTTF : PrimIO Int

%foreign "C:TTF_Quit, libSDL3_ttf"
export
prim__quitTTF : PrimIO ()

%foreign "C:idris_ttf_open_font, libidris2_sdl3_ttf, ttf.h"
export
prim__openFont : String -> Double -> PrimIO AnyPtr

%foreign "C:TTF_CloseFont, libSDL3_ttf"
export
prim__closeFont : AnyPtr -> PrimIO ()

%foreign "C:TTF_CreateRendererTextEngine, libSDL3_ttf"
export
prim__createTextEngine : AnyPtr -> PrimIO AnyPtr

%foreign "C:TTF_DestroyRendererTextEngine, libSDL3_ttf"
export
prim__destroyTextEngine : AnyPtr -> PrimIO ()

%foreign "C:idris_ttf_create_text, libidris2_sdl3_ttf, ttf.h"
export
prim__createText : AnyPtr -> AnyPtr -> String -> PrimIO AnyPtr

%foreign "C:TTF_DestroyText, libSDL3_ttf"
export
prim__destroyText : AnyPtr -> PrimIO ()

%foreign "C:idris_ttf_set_text, libidris2_sdl3_ttf, ttf.h"
export
prim__setTextString : AnyPtr -> String -> PrimIO Int

%foreign "C:idris_ttf_wrap, libidris2_sdl3_ttf, ttf.h"
export
prim__setTextWrapWidth : AnyPtr -> Bits32 -> PrimIO Int

%foreign "C:idris_ttf_color, libidris2_sdl3_ttf, ttf.h"
export
prim__setTextColor : AnyPtr -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_ttf_draw, libidris2_sdl3_ttf, ttf.h"
export
prim__drawText : AnyPtr -> Double -> Double -> PrimIO Int

%foreign "C:idris_ttf_size_new, libidris2_sdl3_ttf, ttf.h"
export
prim__newTextSize : PrimIO NativeSize
%foreign "C:idris_ttf_size, libidris2_sdl3_ttf, ttf.h"
export
prim__textSize : AnyPtr -> NativeSize -> PrimIO Int
