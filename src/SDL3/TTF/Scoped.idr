||| Main-thread text ownership scopes. Shared cleanup contract: docs/resources.md.
module SDL3.TTF.Scoped

import SDL3
import SDL3.TTF
import SDL3.Internal.Resource

%default total

||| Balance one successful initialization. Finish all child scopes first.
export
withTTF : IO (Either String a) -> IO (Either String a)
withTTF = withLibrary initTTF quitTTF

||| Destroy dependent text objects before returning.
export
withFont : String -> Double -> (Font -> IO (Either String a)) -> IO (Either String a)
withFont path size = withResource (openFont path size) closeFont

||| Keep the renderer alive and destroy dependent text objects before returning.
export
withRendererTextEngine : Renderer -> (RendererTextEngine -> IO (Either String a)) -> IO (Either String a)
withRendererTextEngine renderer = withResource (createRendererTextEngine renderer) destroyRendererTextEngine

||| Keep the font, engine, and renderer alive through text cleanup.
export
withText : RendererTextEngine -> Font -> String -> (Text -> IO (Either String a)) -> IO (Either String a)
withText engine font value = withResource (createText engine font value) destroyText
