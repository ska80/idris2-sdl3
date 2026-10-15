||| Resource and state scopes. See docs/resources.md for the shared contract.
||| Acquisition failure skips the callback. Cleanup follows ordinary Right/Left returns only.
||| Do not manually release supplied resources or retain them beyond their scopes.
module SDL3.Scoped

import SDL3
import SDL3.Internal.Resource

import Data.Buffer

%default total

||| Own one open gamepad reference, including after removal.
export
withGamepad : GamepadID -> (Gamepad -> IO (Either String a)) -> IO (Either String a)
withGamepad identifier = withResource (openGamepad identifier) closeGamepad

||| Main thread. Select another cursor before returning. Does not restore the previous selection.
export
withSystemCursor : SystemCursor -> (Cursor -> IO (Either String a)) -> IO (Either String a)
withSystemCursor shape = withResource (createSystemCursor shape) destroyCursor

||| Close failure invalidates the stream. Callback errors precede close errors.
export
withFileIO : String -> FileIOMode -> (IOStream -> IO (Either String a)) -> IO (Either String a)
withFileIO path mode = withCheckedResource (openFileIO path mode) closeIO

||| Copies source bytes. Close failure invalidates the stream; callback errors take precedence.
export
withMemoryIO : Buffer -> (IOStream -> IO (Either String a)) -> IO (Either String a)
withMemoryIO buffer = withCheckedResource (openMemoryIO buffer) closeIO

||| Initialize SDL audio first. Owns a paused stream and its logical device.
export
withPlaybackStream : AudioSpec -> (PlaybackStream -> IO (Either String a)) -> IO (Either String a)
withPlaybackStream spec = withResource (openPlaybackStream spec) destroyPlaybackStream

||| Owns decoded samples. Previously queued audio survives cleanup.
export
withWAV : String -> (WAV -> IO (Either String a)) -> IO (Either String a)
withWAV path = withResource (loadWAV path) freeWAV

||| Main thread. Destroy dependent renderers before returning.
export
withWindow : String -> Int -> Int -> WindowFlags ->
             (Window -> IO (Either String a)) -> IO (Either String a)
withWindow title width height flags =
  withResource (createWindow title width height flags) destroyWindow

||| Main thread. Keep the window alive and destroy dependent textures before returning.
export
withRenderer : Window -> (Renderer -> IO (Either String a)) -> IO (Either String a)
withRenderer window = withResource (createRenderer window) destroyRenderer

||| Main thread. Keep the renderer alive through texture cleanup.
export
withStreamingTexture : Renderer -> Int -> Int ->
                       (Texture StreamingAccess -> IO (Either String a)) -> IO (Either String a)
withStreamingTexture renderer width height =
  withResource (createStreamingTexture renderer width height) destroyTexture

||| Allocate around the frame loop. Keep any outstanding locked texture alive through cleanup.
export
withTextureLockBuffer : (TextureLockBuffer -> IO (Either String a)) -> IO (Either String a)
withTextureLockBuffer = withResource newTextureLockBuffer freeTextureLockBuffer

||| Main thread. Initialize the entire write-only region, including on Left returns.
||| Unlock submits writes without rollback. Action errors precede unlock errors.
||| Keep storage and texture alive. Do not unlock, retain, update, render, destroy, or re-lock the borrowed region.
export
withTextureLockRGBA : TextureLockBuffer -> Texture StreamingAccess -> Maybe Rect ->
                      (LockedRGBA -> IO (Either String a)) -> IO (Either String a)
withTextureLockRGBA storage texture region =
  withCheckedResource (lockTextureRGBA storage texture region) unlockTextureRGBA

||| Owns the texture, not target selection. Nest withRenderTarget inside this main-thread scope.
export
withTargetTexture : Renderer -> Int -> Int ->
                    (Texture TargetAccess -> IO (Either String a)) -> IO (Either String a)
withTargetTexture renderer width height =
  withResource (createTargetTexture renderer width height) destroyTexture

||| Main thread. Copies pixels without consuming the caller's surface. Keep the renderer alive.
export
withTextureFromSurface : Renderer -> Surface ->
                         (Texture StaticAccess -> IO (Either String a)) -> IO (Either String a)
withTextureFromSurface renderer surface =
  withResource (createTextureFromSurface renderer surface) destroyTexture

||| Restore byte alpha only, not color, blending, or external float precision. Main thread.
export
withTextureAlphaMod : Texture access -> Bits8 -> IO (Either String a) -> IO (Either String a)
withTextureAlphaMod texture = withState (getTextureAlphaMod texture) (setTextureAlphaMod texture)

||| Restore filtering only, including unknown saved codes. Main thread.
export
withTextureScaleMode : Texture access -> ScaleMode -> IO (Either String a) -> IO (Either String a)
withTextureScaleMode texture = withState (getTextureScaleMode texture) (setTextureScaleMode texture)

||| Restore texture blending only. Main thread.
export
withTextureBlendMode : Texture access -> BlendMode -> IO (Either String a) -> IO (Either String a)
withTextureBlendMode texture = withState (getTextureBlendMode texture) (setTextureBlendMode texture)

||| Restore renderer-wide draw blending only, not target selection. Main thread.
export
withDrawBlendMode : Renderer -> BlendMode -> IO (Either String a) -> IO (Either String a)
withDrawBlendMode renderer = withState (getDrawBlendMode renderer) (setDrawBlendMode renderer)

||| Main-thread polling and waits. Copied events survive cleanup.
export
withEventBuffer : (EventBuffer -> IO (Either String a)) -> IO (Either String a)
withEventBuffer = withResource newEventBuffer freeEventBuffer

||| Main-thread conversion. Copied points survive cleanup.
export
withCoordinateBuffer : (CoordinateBuffer -> IO (Either String a)) -> IO (Either String a)
withCoordinateBuffer = withResource newCoordinateBuffer freeCoordinateBuffer

||| Allocate outside the frame loop. Draw on the main thread.
export
withPointBuffer : Bits32 -> (PointBuffer -> IO (Either String a)) -> IO (Either String a)
withPointBuffer capacity = withResource (newPointBuffer capacity) freePointBuffer

||| Allocate outside the frame loop. Draw on the main thread.
export
withRectBuffer : Bits32 -> (RectBuffer -> IO (Either String a)) -> IO (Either String a)
withRectBuffer capacity = withResource (newRectBuffer capacity) freeRectBuffer

||| Surface loading can run on a worker thread. Texture conversion still requires the main thread.
export
withBMP : String -> (Surface -> IO (Either String a)) -> IO (Either String a)
withBMP path = withResource (loadBMP path) destroySurface

||| Allocate outside the frame loop. Draw on the main thread.
export
withGeometryBuffer : Bits32 -> Bits32 -> (GeometryBuffer -> IO (Either String a)) -> IO (Either String a)
withGeometryBuffer vertices indices = withResource (newGeometryBuffer vertices indices) freeGeometryBuffer

||| Main-thread snapshot ownership.
export
withKeyboardSnapshot : (KeyboardSnapshot -> IO (Either String a)) -> IO (Either String a)
withKeyboardSnapshot = withResource newKeyboardSnapshot freeKeyboardSnapshot

||| Main-thread query storage. Copied mouse results survive cleanup.
export
withMouseStateBuffer : (MouseStateBuffer -> IO (Either String a)) -> IO (Either String a)
withMouseStateBuffer = withResource newMouseStateBuffer freeMouseStateBuffer

||| Allocate around main-thread render queries and state scopes.
export
withRenderStateBuffer : (RenderStateBuffer -> IO (Either String a)) -> IO (Either String a)
withRenderStateBuffer = withResource newRenderStateBuffer freeRenderStateBuffer

||| Restore explicit or automatic viewport state. Keep the same target selected throughout.
export
withRenderViewport : Renderer -> RenderStateBuffer -> Maybe Rect -> IO (Either String a) -> IO (Either String a)
withRenderViewport renderer buffer = withState (getRenderViewport renderer buffer) (setRenderViewport renderer)

||| Restore disabled or explicit clipping. Keep the same target selected throughout.
export
withRenderClipRect : Renderer -> RenderStateBuffer -> Maybe Rect -> IO (Either String a) -> IO (Either String a)
withRenderClipRect renderer buffer = withState (getRenderClipRect renderer buffer) (setRenderClipRect renderer)

||| Restore x/y scale only. Keep the same target selected throughout.
export
withRenderScale : Renderer -> RenderStateBuffer -> Double -> Double -> IO (Either String a) -> IO (Either String a)
withRenderScale renderer buffer x y = withState (getRenderScale renderer buffer)
  (\(sx, sy) => setRenderScale renderer sx sy) (x, y)

||| Restore byte draw color only, not blend mode or external float/HDR precision.
export
withDrawColor : Renderer -> RenderStateBuffer -> Color -> IO (Either String a) -> IO (Either String a)
withDrawColor renderer buffer = withState (getDrawColor renderer buffer)
  (\(MkColor r g b a) => setDrawColor renderer r g b a)

||| Restore byte RGB modulation only, not alpha or external float/HDR precision.
export
withTextureColorMod : Texture access -> RGBColor -> IO (Either String a) -> IO (Either String a)
withTextureColorMod texture = withState (getTextureColorMod texture)
  (\(MkRGB r g b) => setTextureColorMod texture r g b)
