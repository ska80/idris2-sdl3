||| Unsafe SDL3_image boundary. Prefer SDL3.Image.
module SDL3.Image.Raw

import SDL3.Raw

import System.FFI

%default total

%foreign "C:IMG_Load, libSDL3_image"
export
prim__loadSurface : String -> PrimIO AnyPtr

%foreign "C:IMG_LoadTexture, libSDL3_image"
export
prim__loadTexture : AnyPtr -> String -> PrimIO NativeTexture

%foreign "C:idris_image_load_io, libidris2_sdl3_image, image.h"
export
prim__loadSurfaceIO : AnyPtr -> PrimIO AnyPtr

%foreign "C:idris_image_load_texture_io, libidris2_sdl3_image, image.h"
export
prim__loadTextureIO : AnyPtr -> AnyPtr -> PrimIO NativeTexture
