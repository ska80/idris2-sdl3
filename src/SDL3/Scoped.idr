module SDL3.Scoped

import SDL3

%default total

-- Cleanup runs after an ordinary callback return, including Left.
-- This does not catch runtime exceptions or prevent handles from escaping.
withResource : IO (Either String resource) -> (resource -> IO ()) ->
               (resource -> IO (Either String a)) -> IO (Either String a)
withResource acquire release action = do
  Right resource <- acquire | Left err => pure (Left err)
  result <- action resource
  release resource
  pure result

||| Create a window, run the callback, then destroy the window on Right or Left.
||| Call on the main thread. Creation failure skips the callback.
||| Destroy dependent renderers before the callback returns. Do not destroy the window yourself.
||| Do not retain the window or actions that use it after the callback returns.
||| Runtime exceptions, process exit, and non-returning callbacks do not guarantee cleanup.
export
withWindow : String -> Int -> Int -> WindowFlags ->
             (Window -> IO (Either String a)) -> IO (Either String a)
withWindow title width height flags =
  withResource (createWindow title width height flags) destroyWindow

||| Create a renderer, run the callback, then destroy it on Right or Left.
||| Call on the main thread. The window must remain alive throughout the callback.
||| Destroy dependent textures before returning. Do not destroy or retain the renderer yourself.
||| Only ordinary callback returns guarantee cleanup, not runtime exceptions or process exit.
export
withRenderer : Window -> (Renderer -> IO (Either String a)) -> IO (Either String a)
withRenderer window = withResource (createRenderer window) destroyRenderer

||| Allocate one event buffer for the callback and free it on Right or Left.
||| Poll or wait on the main thread. Do not share, free, or retain the buffer.
||| Copied events can outlive the callback. Runtime exceptions do not guarantee cleanup.
export
withEventBuffer : (EventBuffer -> IO (Either String a)) -> IO (Either String a)
withEventBuffer = withResource newEventBuffer freeEventBuffer

||| Allocate one coordinate buffer for the callback and free it on Right or Left.
||| Convert on the main thread. Do not share, free, or retain the buffer.
||| Copied points can outlive the callback. Runtime exceptions do not guarantee cleanup.
export
withCoordinateBuffer : (CoordinateBuffer -> IO (Either String a)) -> IO (Either String a)
withCoordinateBuffer = withResource newCoordinateBuffer freeCoordinateBuffer

||| Load a BMP surface for the callback and destroy it on Right or Left.
||| Loading failure skips the callback. Do not destroy, share, or retain the surface.
||| A texture copied from the surface can outlive this callback, but not its renderer.
||| Loading can run on a worker thread. Texture creation still requires the main thread.
||| Runtime exceptions and process exit do not guarantee cleanup.
export
withBMP : String -> (Surface -> IO (Either String a)) -> IO (Either String a)
withBMP path = withResource (loadBMP path) destroySurface
