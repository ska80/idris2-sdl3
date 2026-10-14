module SDL3.Image.Scoped

import SDL3
import SDL3.Image

%default total

withOwned : IO (Either String resource) -> (resource -> IO ()) ->
            (resource -> IO (Either String a)) -> IO (Either String a)
withOwned acquire release action = do
  Right resource <- acquire | Left err => pure (Left err)
  result <- action resource
  release resource
  pure result

||| Destroy the surface after ordinary Right or Left returns. Do not destroy or retain it yourself.
||| Failed loading skips the callback. Exceptions and nonreturning callbacks do not guarantee cleanup.
export
withSurface : String -> (Surface -> IO (Either String a)) -> IO (Either String a)
withSurface path = withOwned (loadSurface path) destroySurface

||| Main thread. Keep the renderer alive through cleanup. Do not destroy or retain the texture.
||| Ordinary-return cleanup only. Failed loading skips the callback.
export
withTexture : Renderer -> String -> (Texture StaticAccess -> IO (Either String a)) -> IO (Either String a)
withTexture renderer path = withOwned (loadTexture renderer path) destroyTexture

||| Own only the decoded surface. The caller owns the stream, even after loading fails.
||| Do not destroy or retain the surface. Ordinary-return cleanup only.
export
withSurfaceIO : IOStream -> (Surface -> IO (Either String a)) -> IO (Either String a)
withSurfaceIO stream = withOwned (loadSurfaceIO stream) destroySurface

||| Own only the decoded texture. The caller owns the stream and renderer.
||| Do not destroy or retain the texture. Main thread, ordinary-return cleanup only.
export
withTextureIO : Renderer -> IOStream -> (Texture StaticAccess -> IO (Either String a)) -> IO (Either String a)
withTextureIO renderer stream = withOwned (loadTextureIO renderer stream) destroyTexture
