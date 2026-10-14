||| Image decoding through SDL3_image. No separate initialization is required.
module SDL3.Image

import SDL3
import SDL3.Raw
import SDL3.Image.Raw
import SDL3.Internal.Handles

import System.FFI

%default total

loadedSurface : PrimIO AnyPtr -> IO (Either String Surface)
loadedSurface action = do
  ptr <- primIO action
  0 <- primIO (prim__isNull ptr) | _ => Left <$> getError
  pure (Right (unsafeWrapHandle ptr))

loadedTexture : PrimIO NativeTexture -> IO (Either String (Texture StaticAccess))
loadedTexture action = do
  ptr <- primIO action
  0 <- primIO (prim__textureIsNull ptr) | _ => Left <$> getError
  pure (Right (unsafeWrapHandle ptr))

||| Decode a whole file into an owned core Surface. Release with destroySurface.
||| Formats depend on the installed SDL3_image build. UTF-8 paths end at embedded NUL.
||| Can run on a worker thread. Do not share the resulting surface during modification or destruction.
export
loadSurface : String -> IO (Either String Surface)
loadSurface path = loadedSurface (prim__loadSurface path)

||| Load directly into an owned static texture. Main thread, with a live renderer.
||| Release with destroyTexture before destroying the renderer. No source file remains open.
export
loadTexture : Renderer -> String -> IO (Either String (Texture StaticAccess))
loadTexture renderer path = loadedTexture (prim__loadTexture (unsafeHandlePointer renderer) path)

||| Borrow an IOStream for this call. Never closes or retains it, including on failure.
||| The stream position can change. Serialize access and seek explicitly before decoding again.
export
loadSurfaceIO : IOStream -> IO (Either String Surface)
loadSurfaceIO stream = loadedSurface (prim__loadSurfaceIO (unsafeHandlePointer stream))

||| Main-thread texture loading from a borrowed stream. Never closes or retains the stream.
||| The returned texture owns its data and can outlive the stream, but not its renderer.
export
loadTextureIO : Renderer -> IOStream -> IO (Either String (Texture StaticAccess))
loadTextureIO renderer stream = loadedTexture $
  prim__loadTextureIO (unsafeHandlePointer renderer) (unsafeHandlePointer stream)
