module SDL3.TTF.Scoped

import SDL3
import SDL3.TTF

%default total

withOwned : IO (Either String resource) -> (resource -> IO ()) ->
            (resource -> IO (Either String a)) -> IO (Either String a)
withOwned acquire release action = do
  Right resource <- acquire | Left err => pure (Left err)
  result <- action resource
  release resource
  pure result

||| Main thread. Balance one successful init on ordinary return. All child scopes must finish first.
||| Exceptions, process exit, and nonreturning callbacks do not guarantee cleanup.
export
withTTF : IO (Either String a) -> IO (Either String a)
withTTF action = do
  True <- initTTF | False => Left <$> getError
  result <- action
  quitTTF
  pure result

||| Own a font on the main thread. Destroy its text objects before returning.
||| Do not close or retain the font. Failed acquisition skips the action. Ordinary-return cleanup only.
export
withFont : String -> Double -> (Font -> IO (Either String a)) -> IO (Either String a)
withFont path size = withOwned (openFont path size) closeFont

||| Own an engine on the main thread. Keep the renderer alive and destroy all text before returning.
||| Do not destroy or retain the engine. Ordinary-return cleanup only.
export
withRendererTextEngine : Renderer -> (RendererTextEngine -> IO (Either String a)) -> IO (Either String a)
withRendererTextEngine renderer = withOwned (createRendererTextEngine renderer) destroyRendererTextEngine

||| Own reusable text on the main thread. Keep its font, engine, and renderer alive through cleanup.
||| Do not destroy or retain the text. Ordinary-return cleanup only.
export
withText : RendererTextEngine -> Font -> String -> (Text -> IO (Either String a)) -> IO (Either String a)
withText engine font value = withOwned (createText engine font value) destroyText
