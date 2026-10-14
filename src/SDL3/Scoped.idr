module SDL3.Scoped

import SDL3

import Data.Buffer

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

||| Own one open reference, including after removal. Do not close or retain the supplied handle.
export
withGamepad : GamepadID -> (Gamepad -> IO (Either String a)) -> IO (Either String a)
withGamepad identifier = withResource (openGamepad identifier) closeGamepad

||| Own a system cursor on the main thread. Select another cursor before returning.
||| Does not restore the previous cursor. Do not destroy or retain the supplied handle.
export
withSystemCursor : SystemCursor -> (Cursor -> IO (Either String a)) -> IO (Either String a)
withSystemCursor shape = withResource (createSystemCursor shape) destroyCursor

withIOResource : IO (Either String IOStream) -> (IOStream -> IO (Either String a)) -> IO (Either String a)
withIOResource acquire action = do
  Right stream <- acquire | Left err => pure (Left err)
  result <- action stream
  closed <- closeIO stream
  case result of
    Left err => pure (Left err)
    Right value => if closed then pure (Right value) else Left <$> getError

||| Close on ordinary return, even after callback failure. Callback errors precede close errors.
||| Do not close or retain the stream. Close failure still invalidates it. No exception guarantee.
export
withFileIO : String -> FileIOMode -> (IOStream -> IO (Either String a)) -> IO (Either String a)
withFileIO path mode = withIOResource (openFileIO path mode)

||| Copy source bytes into owned memory and close on ordinary return. Source need not remain alive.
||| Do not close or retain the stream. Callback errors precede close errors. No exception guarantee.
export
withMemoryIO : Buffer -> (IOStream -> IO (Either String a)) -> IO (Either String a)
withMemoryIO buffer = withIOResource (openMemoryIO buffer)

||| Open paused playback, then destroy its stream and owned device on ordinary callback return.
||| Initialize SDL audio first. Do not destroy or retain the stream. Runtime exceptions do not guarantee cleanup.
export
withPlaybackStream : AudioSpec -> (PlaybackStream -> IO (Either String a)) -> IO (Either String a)
withPlaybackStream spec = withResource (openPlaybackStream spec) destroyPlaybackStream

||| Load an entire WAV, then free its decoded samples on ordinary callback return.
||| Queue operations copy samples, so playback can continue after this scope. Do not free or retain this WAV.
||| Runtime exceptions, process exit, and non-returning callbacks do not guarantee cleanup.
export
withWAV : String -> (WAV -> IO (Either String a)) -> IO (Either String a)
withWAV path = withResource (loadWAV path) freeWAV

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

||| Create a streaming texture for the callback and destroy it on Right or Left.
||| Call on the main thread. Keep the renderer alive throughout the callback.
||| Do not destroy or retain the texture. Creation failure skips the callback.
||| Runtime exceptions and process exit do not guarantee cleanup.
export
withStreamingTexture : Renderer -> Int -> Int ->
                       (Texture StreamingAccess -> IO (Either String a)) -> IO (Either String a)
withStreamingTexture renderer width height =
  withResource (createStreamingTexture renderer width height) destroyTexture

||| Allocate reusable lock storage around the frame loop, then free it on ordinary return.
||| Keep any outstanding locked texture alive through cleanup. Do not free or retain this storage.
||| Runtime exceptions, process exit, and non-returning callbacks do not guarantee cleanup.
export
withTextureLockBuffer : (TextureLockBuffer -> IO (Either String a)) -> IO (Either String a)
withTextureLockBuffer = withResource newTextureLockBuffer freeTextureLockBuffer

||| Borrow write-only pixels and unlock after an ordinary Right or Left callback return.
||| Acquisition failure skips the callback. An action error takes precedence over an unlock error.
||| Initialize the whole region before returning, including Left. Filling first makes later errors safer.
||| Unlock submits writes, not rollback. Keep storage, texture, renderer, and window alive on the main thread.
||| Do not unlock manually, retain the view, or destroy, update, render, or re-lock the texture during this callback.
||| Other storage does not make a second lock of the same texture safe. Runtime exceptions do not guarantee unlock.
export
withTextureLockRGBA : TextureLockBuffer -> Texture StreamingAccess -> Maybe Rect ->
                      (LockedRGBA -> IO (Either String a)) -> IO (Either String a)
withTextureLockRGBA storage texture region action = do
  Right view <- lockTextureRGBA storage texture region | Left err => pure (Left err)
  result <- action view
  released <- unlockTextureRGBA view
  case result of
    Left err => pure (Left err)
    Right value => if released then pure (Right value) else Left <$> getError

||| Create a target texture for the callback and destroy it on Right or Left.
||| Call on the main thread. Keep the renderer alive. Creation failure skips the callback.
||| This owns the texture, not target selection. Use withRenderTarget inside the callback.
||| Restore target selection before returning. Do not destroy or retain the texture.
||| Runtime exceptions, process exit, and non-returning callbacks do not guarantee cleanup.
export
withTargetTexture : Renderer -> Int -> Int ->
                    (Texture TargetAccess -> IO (Either String a)) -> IO (Either String a)
withTargetTexture renderer width height =
  withResource (createTargetTexture renderer width height) destroyTexture

||| Copy a surface into a static texture, then destroy the texture on Right or Left.
||| Call on the main thread. The caller still owns the surface.
||| Keep the renderer alive. Do not destroy or retain the supplied texture.
||| Creation failure skips the callback. Runtime exceptions do not guarantee cleanup.
export
withTextureFromSurface : Renderer -> Surface ->
                         (Texture StaticAccess -> IO (Either String a)) -> IO (Either String a)
withTextureFromSurface renderer surface =
  withResource (createTextureFromSurface renderer surface) destroyTexture

||| Temporarily set byte alpha modulation, then attempt to restore its previous value.
||| Keep the texture and renderer alive on the main thread. This does not own either resource.
||| Query or setting failure skips the action. A failed setting still triggers restoration.
||| Setting or action errors take precedence over restoration errors. Left does not guarantee restoration.
||| Only byte alpha is restored, not color modulation, blending, or floating-point alpha precision.
||| Runtime exceptions, process exit, and non-returning actions do not guarantee restoration.
export
withTextureAlphaMod : Texture access -> Bits8 -> IO (Either String a) -> IO (Either String a)
withTextureAlphaMod {a} texture alpha action = do
  Right previous <- getTextureAlphaMod texture | Left err => pure (Left err)
  changed <- setTextureAlphaMod texture alpha
  result <- the (IO (Either String a)) (if changed then action else Left <$> getError)
  restored <- setTextureAlphaMod texture previous
  case result of
    Left err => pure (Left err)
    Right value => if restored then pure (Right value) else Left <$> getError

||| Temporarily set texture filtering, then attempt to restore the previous mode.
||| Keep the texture and renderer alive on the main thread. This does not own either resource.
||| Query or setting failure skips the action. A failed setting still triggers restoration.
||| Setting or action errors take precedence over restoration errors. Left does not guarantee restoration.
||| Restores only filtering, including unknown saved codes. SDL can select the closest supported mode.
||| Runtime exceptions, process exit, and non-returning actions do not guarantee restoration.
export
withTextureScaleMode : Texture access -> ScaleMode -> IO (Either String a) -> IO (Either String a)
withTextureScaleMode {a} texture mode action = do
  Right previous <- getTextureScaleMode texture | Left err => pure (Left err)
  changed <- setTextureScaleMode texture mode
  result <- the (IO (Either String a)) (if changed then action else Left <$> getError)
  restored <- setTextureScaleMode texture previous
  case result of
    Left err => pure (Left err)
    Right value => if restored then pure (Right value) else Left <$> getError

||| Temporarily set texture blending, then attempt to restore the previous SDL code.
||| Keep the texture and renderer alive on the main thread. This does not own either resource.
||| Query or setting failure skips the action. A failed setting still triggers restoration.
||| Setting or action errors take precedence over restoration errors. Left does not guarantee restoration.
||| Restores only texture blending, not alpha, color, filtering, draw blending, or target selection.
||| Runtime exceptions, process exit, and non-returning actions do not guarantee restoration.
export
withTextureBlendMode : Texture access -> BlendMode -> IO (Either String a) -> IO (Either String a)
withTextureBlendMode {a} texture mode action = do
  Right previous <- getTextureBlendMode texture | Left err => pure (Left err)
  changed <- setTextureBlendMode texture mode
  result <- the (IO (Either String a)) (if changed then action else Left <$> getError)
  restored <- setTextureBlendMode texture previous
  case result of
    Left err => pure (Left err)
    Right value => if restored then pure (Right value) else Left <$> getError

||| Temporarily set blending for renderer shapes, then attempt to restore the previous SDL code.
||| Keep the renderer and its window alive on the main thread. This does not own either resource.
||| Query or setting failure skips the action. A failed setting still triggers restoration.
||| Setting or action errors take precedence over restoration errors. Left does not guarantee restoration.
||| Restores only renderer draw blending, not draw color, texture state, or target selection.
||| Runtime exceptions, process exit, and non-returning actions do not guarantee restoration.
export
withDrawBlendMode : Renderer -> BlendMode -> IO (Either String a) -> IO (Either String a)
withDrawBlendMode {a} renderer mode action = do
  Right previous <- getDrawBlendMode renderer | Left err => pure (Left err)
  changed <- setDrawBlendMode renderer mode
  result <- the (IO (Either String a)) (if changed then action else Left <$> getError)
  restored <- setDrawBlendMode renderer previous
  case result of
    Left err => pure (Left err)
    Right value => if restored then pure (Right value) else Left <$> getError

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

||| Allocate a point array for the callback and free it on Right or Left.
||| Allocate outside the frame loop. Do not share, free, or retain the buffer.
||| Draw on the main thread. Allocation failure skips the callback.
||| Runtime exceptions and process exit do not guarantee cleanup.
export
withPointBuffer : Bits32 -> (PointBuffer -> IO (Either String a)) -> IO (Either String a)
withPointBuffer capacity = withResource (newPointBuffer capacity) freePointBuffer

||| Allocate a rectangle array for the callback and free it on Right or Left.
||| Allocate outside the frame loop. Do not share, free, or retain the buffer.
||| Draw on the main thread. Allocation failure skips the callback.
||| Runtime exceptions and process exit do not guarantee cleanup.
export
withRectBuffer : Bits32 -> (RectBuffer -> IO (Either String a)) -> IO (Either String a)
withRectBuffer capacity = withResource (newRectBuffer capacity) freeRectBuffer

||| Load a BMP surface for the callback and destroy it on Right or Left.
||| Loading failure skips the callback. Do not destroy, share, or retain the surface.
||| A texture copied from the surface can outlive this callback, but not its renderer.
||| Loading can run on a worker thread. Texture creation still requires the main thread.
||| Runtime exceptions and process exit do not guarantee cleanup.
export
withBMP : String -> (Surface -> IO (Either String a)) -> IO (Either String a)
withBMP path = withResource (loadBMP path) destroySurface

||| Own reusable triangle storage. Do not free or retain it. Ordinary-return cleanup only.
export
withGeometryBuffer : Bits32 -> Bits32 -> (GeometryBuffer -> IO (Either String a)) -> IO (Either String a)
withGeometryBuffer vertices indices = withResource (newGeometryBuffer vertices indices) freeGeometryBuffer

||| Main-thread snapshot ownership. Do not free or retain it. Ordinary-return cleanup only.
export
withKeyboardSnapshot : (KeyboardSnapshot -> IO (Either String a)) -> IO (Either String a)
withKeyboardSnapshot = withResource newKeyboardSnapshot freeKeyboardSnapshot

||| Main-thread query storage. Do not free or retain it. Ordinary-return cleanup only.
export
withMouseStateBuffer : (MouseStateBuffer -> IO (Either String a)) -> IO (Either String a)
withMouseStateBuffer = withResource newMouseStateBuffer freeMouseStateBuffer

||| Allocate once around render queries and state scopes. Do not free or retain it.
||| All operations require the main thread. Ordinary-return cleanup only.
export
withRenderStateBuffer : (RenderStateBuffer -> IO (Either String a)) -> IO (Either String a)
withRenderStateBuffer = withResource newRenderStateBuffer freeRenderStateBuffer

withState : IO (Either String state) -> (state -> IO Bool) -> state -> IO (Either String a) -> IO (Either String a)
withState {a} query set temporary action = do
  Right previous <- query | Left err => pure (Left err)
  changed <- set temporary
  result <- the (IO (Either String a)) (if changed then action else Left <$> getError)
  restored <- set previous
  case result of
    Left err => pure (Left err)
    Right value => if restored then pure (Right value) else Left <$> getError

||| Restore the explicit rectangle or automatic full-target viewport on ordinary return.
||| Keep the same render target selected throughout this scope. Restore target changes in an inner scope.
||| Query failure skips the action. Setting/action errors precede restoration errors. No exception guarantee.
export
withRenderViewport : Renderer -> RenderStateBuffer -> Maybe Rect -> IO (Either String a) -> IO (Either String a)
withRenderViewport renderer buffer = withState (getRenderViewport renderer buffer) (setRenderViewport renderer)

||| Restore disabled clipping distinctly from an enabled empty clip rectangle.
||| Keep the same target selected. Shares the failure and cleanup rules of withRenderViewport.
export
withRenderClipRect : Renderer -> RenderStateBuffer -> Maybe Rect -> IO (Either String a) -> IO (Either String a)
withRenderClipRect renderer buffer = withState (getRenderClipRect renderer buffer) (setRenderClipRect renderer)

||| Restore x/y scale only. Keep the same target selected. Ordinary-return restoration only.
export
withRenderScale : Renderer -> RenderStateBuffer -> Double -> Double -> IO (Either String a) -> IO (Either String a)
withRenderScale renderer buffer x y = withState (getRenderScale renderer buffer)
  (\(sx, sy) => setRenderScale renderer sx sy) (x, y)

||| Restore byte draw color only, not blend mode or external float/HDR precision.
||| Keep renderer and buffer alive. Ordinary-return restoration only.
export
withDrawColor : Renderer -> RenderStateBuffer -> Color -> IO (Either String a) -> IO (Either String a)
withDrawColor renderer buffer = withState (getDrawColor renderer buffer)
  (\(MkColor r g b a) => setDrawColor renderer r g b a)

||| Restore byte RGB modulation only, not alpha or external float/HDR precision.
||| Keep texture and renderer alive on the main thread. Ordinary-return restoration only.
export
withTextureColorMod : Texture access -> RGBColor -> IO (Either String a) -> IO (Either String a)
withTextureColorMod texture = withState (getTextureColorMod texture)
  (\(MkRGB r g b) => setTextureColorMod texture r g b)
