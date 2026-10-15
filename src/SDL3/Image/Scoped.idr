||| Image ownership scopes. Shared cleanup contract: docs/resources.md.
module SDL3.Image.Scoped

import SDL3
import SDL3.Image
import SDL3.Internal.Resource

%default total

export
withSurface : String -> (Surface -> IO (Either String a)) -> IO (Either String a)
withSurface path = withResource (loadSurface path) destroySurface

||| Main thread. Keep the renderer alive through cleanup.
export
withTexture : Renderer -> String -> (Texture StaticAccess -> IO (Either String a)) -> IO (Either String a)
withTexture renderer path = withResource (loadTexture renderer path) destroyTexture

||| Own only the decoded surface. Never closes or retains the caller's stream.
export
withSurfaceIO : IOStream -> (Surface -> IO (Either String a)) -> IO (Either String a)
withSurfaceIO stream = withResource (loadSurfaceIO stream) destroySurface

||| Main thread. Own only the texture, not the stream or renderer.
export
withTextureIO : Renderer -> IOStream -> (Texture StaticAccess -> IO (Either String a)) -> IO (Either String a)
withTextureIO renderer stream = withResource (loadTextureIO renderer stream) destroyTexture
