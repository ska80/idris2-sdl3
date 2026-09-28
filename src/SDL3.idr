module SDL3

import public SDL3.Events
import public SDL3.Flags
import SDL3.Raw
import Data.Buffer

%default total

||| Owned window. Destroy after its renderer, before quit.
export
data Window = MkWindow AnyPtr

||| Owned renderer. Its window must remain alive.
export
data Renderer = MkRenderer AnyPtr

||| Synchronize presentation with display refreshes, or disable synchronization.
||| VSyncInterval requires a value from 1 through 2147483647.
public export
data VSyncMode = VSyncDisabled | VSyncAdaptive | VSyncInterval Bits32

public export
Eq VSyncMode where
  VSyncDisabled == VSyncDisabled = True
  VSyncAdaptive == VSyncAdaptive = True
  VSyncInterval x == VSyncInterval y = x == y
  _ == _ = False

vsyncValue : VSyncMode -> Int64
vsyncValue VSyncDisabled = 0
vsyncValue VSyncAdaptive = -1
vsyncValue (VSyncInterval n) = if n == 0 then -2 else cast n

||| Owned CPU image data. Destroy exactly once after use.
export
data Surface = MkSurface AnyPtr

public export
data TextureAccess = StaticAccess | StreamingAccess | TargetAccess

||| How source pixels combine with destination pixels.
public export
data BlendMode = NoBlend | AlphaBlend | PremultipliedAlphaBlend
               | AdditiveBlend | PremultipliedAdditiveBlend | ModulateBlend | MultiplyBlend

blendBits : BlendMode -> Bits32
blendBits NoBlend = 0
blendBits AlphaBlend = 1
blendBits PremultipliedAlphaBlend = 0x10
blendBits AdditiveBlend = 2
blendBits PremultipliedAdditiveBlend = 0x20
blendBits ModulateBlend = 4
blendBits MultiplyBlend = 8

||| Nearest selects a source pixel. Linear interpolates neighboring pixels.
public export
data ScaleMode = NearestScale | LinearScale

scaleValue : ScaleMode -> Int
scaleValue NearestScale = 0
scaleValue LinearScale = 1

||| Mirror texture pixels horizontally, vertically, or on both axes.
public export
data TextureFlip = NoFlip | FlipHorizontal | FlipVertical | FlipBoth

flipValue : TextureFlip -> Bits32
flipValue NoFlip = 0
flipValue FlipHorizontal = 1
flipValue FlipVertical = 2
flipValue FlipBoth = 3

||| Rotation center relative to the destination rectangle's top-left corner.
||| Values use destination drawing units and convert to SDL float in C.
public export
record RotationCenter where
  constructor MkRotationCenter
  x : Double
  y : Double

||| How a fixed logical resolution fits the current render target.
public export
data LogicalPresentation = PresentationDisabled | PresentationStretch
                         | PresentationLetterbox | PresentationOverscan | PresentationIntegerScale

presentationValue : LogicalPresentation -> Int
presentationValue PresentationDisabled = 0
presentationValue PresentationStretch = 1
presentationValue PresentationLetterbox = 2
presentationValue PresentationOverscan = 3
presentationValue PresentationIntegerScale = 4

||| Owned texture. Its creating renderer must remain alive.
||| The access parameter prevents non-target textures from becoming render targets.
export
data Texture : TextureAccess -> Type where
  MkTexture : AnyPtr -> Texture access

||| SDL integer rectangle, used for viewports and clipping.
public export
record Rect where
  constructor MkRect
  x : Int32
  y : Int32
  width : Int32
  height : Int32

||| SDL floating-point rectangle. Values convert to single precision in C.
public export
record FRect where
  constructor MkFRect
  x : Double
  y : Double
  width : Double
  height : Double

public export
data CoordinateSpace = WindowSpace | RenderSpace

||| A point tagged with its coordinate space. SDL conversions use single precision.
public export
record Point (space : CoordinateSpace) where
  constructor MkPoint
  x : Double
  y : Double

||| Distinguish window-coordinate dimensions from physical pixel dimensions.
public export
data SizeUnit = WindowUnits | PixelUnits

||| Copied dimensions. Units do not track window or renderer identity.
public export
record Size (unit : SizeUnit) where
  constructor MkSize
  width : Int32
  height : Int32

||| Reusable output storage for coordinate conversion. Free exactly once.
export
data CoordinateBuffer = MkCoordinateBuffer AnyPtr

||| Reusable native event storage. Free exactly once.
export
data EventBuffer = MkEventBuffer AnyPtr

public export
data EventType = QuitRequested
               | WindowCloseRequested
               | WindowResized
               | WindowPixelSizeChanged
               | KeyDown
               | KeyUp
               | MouseMotion
               | MouseButtonDown
               | MouseButtonUp
               | MouseWheel
               | TextInput
               | TextEditing
               | OtherEvent Bits32

||| Copy the current thread's SDL error. Read only after a failed call.
export
getError : IO String
getError = primIO prim__getError

||| Initialize on the main thread. Video also enables events.
export
init : InitFlags -> IO Bool
init flags = (/= 0) <$> primIO (prim__init (initBits flags))

||| Destroy all owned resources before this call.
export
quit : IO ()
quit = primIO prim__quit

owned : (AnyPtr -> a) -> PrimIO AnyPtr -> IO (Either String a)
owned wrap action = do
  ptr <- primIO action
  null <- primIO (prim__isNull ptr)
  if null /= 0 then Left <$> getError else pure (Right (wrap ptr))

||| Width and height must be positive C int values. Call on the main thread.
export
createWindow : String -> Int -> Int -> WindowFlags -> IO (Either String Window)
createWindow title width height flags =
  if width <= 0 || height <= 0 || width > 2147483647 || height > 2147483647
     then pure (Left "Window dimensions must be positive 32-bit integers")
     else owned MkWindow (prim__createWindow title width height (windowBits flags))

||| Do not use the window after this call. Destroy its renderer first.
export
destroyWindow : Window -> IO ()
destroyWindow (MkWindow ptr) = primIO (prim__destroyWindow ptr)

||| Identifier for a live window. The identifier does not extend its lifetime.
||| Zero means failure. Call on the main thread.
export
getWindowID : Window -> IO (Either String WindowID)
getWindowID (MkWindow ptr) = do
  value <- primIO (prim__getWindowID ptr)
  if value == 0 then Left <$> getError else pure (Right (MkWindowID value))

||| Select SDL's default renderer. Call on the main thread.
export
createRenderer : Window -> IO (Either String Renderer)
createRenderer (MkWindow ptr) = owned MkRenderer (prim__createRenderer ptr)

export
destroyRenderer : Renderer -> IO ()
destroyRenderer (MkRenderer ptr) = primIO (prim__destroyRenderer ptr)

queriedSize : PrimIO Bits64 -> IO (Either String (Size unit))
queriedSize action = do
  packed <- primIO action
  if packed == 0xffffffffffffffff then Left <$> getError
     else pure (Right (MkSize (cast (packed `div` 4294967296)) (cast (packed `mod` 4294967296))))

||| Query window-coordinate dimensions on the main thread. Copies errors on failure.
export
getWindowSize : Window -> IO (Either String (Size WindowUnits))
getWindowSize (MkWindow ptr) = queriedSize (prim__getWindowSize ptr)

||| Query physical pixel dimensions on the main thread, which can differ from window coordinates.
export
getWindowSizeInPixels : Window -> IO (Either String (Size PixelUnits))
getWindowSizeInPixels (MkWindow ptr) = queriedSize (prim__getWindowSizeInPixels ptr)

||| Load a BMP file into CPU memory. Does not require a renderer.
||| Destroy the returned surface when no longer needed.
export
loadBMP : String -> IO (Either String Surface)
loadBMP path = owned MkSurface (prim__loadBMP path)

||| Do not use the surface after this call. Avoid concurrent access to the surface.
export
destroySurface : Surface -> IO ()
destroySurface (MkSurface ptr) = primIO (prim__destroySurface ptr)

||| Copy a surface into a static texture on the main thread.
||| The surface remains owned by the caller and can be destroyed after this call.
export
createTextureFromSurface : Renderer -> Surface -> IO (Either String (Texture StaticAccess))
createTextureFromSurface (MkRenderer renderer) (MkSurface surface) =
  owned MkTexture (prim__createTextureFromSurface renderer surface)

||| Configure presentation synchronization on the main thread.
||| Interval 1 requests every refresh, 2 every second refresh, and so on.
||| Not all modes or intervals are supported. Read getError after False.
||| This state belongs to the renderer, not to individual render targets.
export
setRenderVSync : Renderer -> VSyncMode -> IO Bool
setRenderVSync (MkRenderer ptr) mode = (/= 0) <$> primIO (prim__setRenderVSync ptr (vsyncValue mode))

||| Read the renderer's presentation synchronization mode on the main thread.
||| New renderers default to VSyncDisabled. Failure returns a copied SDL error.
export
getRenderVSync : Renderer -> IO (Either String VSyncMode)
getRenderVSync (MkRenderer ptr) = do
  value <- primIO (prim__getRenderVSync ptr)
  if value == -2 then Left <$> getError
     else pure (Right (if value == -1 then VSyncAdaptive
                          else if value == 0 then VSyncDisabled
                                  else VSyncInterval (cast value)))

||| Create an RGBA32 texture for off-screen drawing on the main thread.
||| Contents are undefined until drawn. Width and height must be positive C ints.
export
createTargetTexture : Renderer -> Int -> Int -> IO (Either String (Texture TargetAccess))
createTargetTexture (MkRenderer ptr) width height =
  if width <= 0 || height <= 0 || width > 2147483647 || height > 2147483647
     then pure (Left "Texture dimensions must be positive 32-bit integers")
     else owned MkTexture (prim__createTargetTexture ptr width height)

||| Create an RGBA32 texture for repeated uploads on the main thread.
||| Pixel bytes use R, G, B, A order. Contents are undefined until uploaded.
export
createStreamingTexture : Renderer -> Int -> Int -> IO (Either String (Texture StreamingAccess))
createStreamingTexture (MkRenderer ptr) width height =
  if width <= 0 || height <= 0 || width > 2147483647 || height > 2147483647
     then pure (Left "Texture dimensions must be positive 32-bit integers")
     else owned MkTexture (prim__createStreamingTexture ptr width height)

||| Upload the entire RGBA32 texture. Pitch is the byte distance between rows.
||| Requires pitch >= width * 4 and buffer size >= pitch * height.
||| Reuse the Buffer. SDL consumes the bytes during this main-thread call.
||| Do not modify the buffer concurrently. Returns False on failure.
export
updateTextureRGBA : Texture StreamingAccess -> Buffer -> Int32 -> IO Bool
updateTextureRGBA (MkTexture ptr) buffer pitch = do
  size <- rawSize buffer
  (/= 0) <$> primIO (prim__updateTextureRGBA ptr buffer (cast size) pitch)

||| Upload a positive rectangle entirely inside the texture, in texture pixels.
||| Buffer byte zero is the region's top-left pixel, not the texture's origin.
||| Requires pitch >= region width * 4 and buffer size >= pitch * region height.
||| Includes final-row padding. No clipping or source offset is applied.
||| Call on the main thread. Do not modify the buffer concurrently.
||| SDL consumes the bytes during the call. Returns False on failure.
export
updateTextureRegionRGBA : Texture StreamingAccess -> Rect -> Buffer -> Int32 -> IO Bool
updateTextureRegionRGBA (MkTexture ptr) (MkRect x y width height) buffer pitch = do
  size <- rawSize buffer
  (/= 0) <$> primIO (prim__updateTextureRegionRGBA ptr x y width height buffer (cast size) pitch)

||| Destroy on the main thread, before the creating renderer.
||| Switch away from this texture as a render target first. Do not reuse the handle.
export
destroyTexture : Texture access -> IO ()
destroyTexture (MkTexture ptr) = primIO (prim__destroyTexture ptr)

||| Multiply source RGB channels by r/255, g/255, and b/255 when drawing.
||| 255 preserves a channel. Call on the main thread. Returns False on failure.
export
setTextureColorMod : Texture access -> Bits8 -> Bits8 -> Bits8 -> IO Bool
setTextureColorMod (MkTexture ptr) r g b =
  (/= 0) <$> primIO (prim__setTextureColorMod ptr r g b)

||| Multiply source alpha by alpha/255 when drawing. Does not change stored pixels.
||| Call on the main thread. Returns False on failure.
export
setTextureAlphaMod : Texture access -> Bits8 -> IO Bool
setTextureAlphaMod (MkTexture ptr) alpha =
  (/= 0) <$> primIO (prim__setTextureAlphaMod ptr alpha)

||| Select texture blending on the main thread. Returns False on failure.
||| SDL can select the closest supported mode when the requested mode fails.
export
setTextureBlendMode : Texture access -> BlendMode -> IO Bool
setTextureBlendMode (MkTexture ptr) mode =
  (/= 0) <$> primIO (prim__setTextureBlendMode ptr (blendBits mode))

||| Select texture filtering on the main thread. Returns False on failure.
||| SDL can select the closest supported mode. SDL's default is linear filtering.
export
setTextureScaleMode : Texture access -> ScaleMode -> IO Bool
setTextureScaleMode (MkTexture ptr) mode =
  (/= 0) <$> primIO (prim__setTextureScaleMode ptr (scaleValue mode))

||| Select an off-screen target. Nothing restores drawing to the window.
||| The texture must belong to this renderer. Call on the main thread.
export
setRenderTarget : Renderer -> Maybe (Texture TargetAccess) -> IO Bool
setRenderTarget (MkRenderer renderer) Nothing =
  (/= 0) <$> primIO (prim__resetRenderTarget renderer)
setRenderTarget (MkRenderer renderer) (Just (MkTexture texture)) =
  (/= 0) <$> primIO (prim__setRenderTarget renderer texture)

||| Select a target for an action, then attempt to restore the previous target.
||| Call on the main thread. Keep the renderer and both targets alive throughout.
||| Selection failure skips the action. Right and Left returns both trigger restoration.
||| Selection or action errors take precedence over restoration errors.
||| If restoration alone fails, return its copied SDL error. State is then uncertain.
||| Only the selected target is restored, not draw color or changes to target state.
||| Runtime exceptions, process exit, and non-returning actions do not guarantee restoration.
export
withRenderTarget : Renderer -> Maybe (Texture TargetAccess) ->
                   IO (Either String a) -> IO (Either String a)
withRenderTarget {a} renderer@(MkRenderer ptr) target action = do
  previous <- primIO (prim__getRenderTarget ptr)
  selected <- setRenderTarget renderer target
  result <- the (IO (Either String a)) (if selected then action else Left <$> getError)
  restored <- primIO (prim__setRenderTarget ptr previous)
  case result of
    Left err => pure (Left err)
    Right value => if restored /= 0 then pure (Right value) else Left <$> getError

||| Draw the whole texture into the destination rectangle, or the whole target.
||| The texture must belong to this renderer and must not be the current target.
||| Call on the main thread. Nothing uses SDL's default destination rectangle.
export
renderTexture : Renderer -> Texture access -> Maybe FRect -> IO Bool
renderTexture (MkRenderer renderer) (MkTexture texture) Nothing =
  (/= 0) <$> primIO (prim__renderTexture renderer texture)
renderTexture (MkRenderer renderer) (MkTexture texture) (Just (MkFRect x y width height)) =
  (/= 0) <$> primIO (prim__renderTextureRect renderer texture x y width height)

||| Draw a source rectangle from a texture. Source coordinates use texture pixels.
||| Nothing uses the whole current target as the destination.
||| Ownership and thread rules are the same as for renderTexture.
export
renderTextureRegion : Renderer -> Texture access -> FRect -> Maybe FRect -> IO Bool
renderTextureRegion (MkRenderer renderer) (MkTexture texture) (MkFRect sx sy sw sh) Nothing =
  (/= 0) <$> primIO (prim__renderTextureSource renderer texture sx sy sw sh)
renderTextureRegion (MkRenderer renderer) (MkTexture texture) (MkFRect sx sy sw sh)
                    (Just (MkFRect dx dy dw dh)) =
  (/= 0) <$> primIO (prim__renderTextureRegion renderer texture sx sy sw sh dx dy dw dh)

rotatedTexture : AnyPtr -> AnyPtr -> Int32 -> Double -> Double -> Double -> Double ->
                 Int32 -> Double -> Double -> Double -> Double -> Double ->
                 Maybe RotationCenter -> TextureFlip -> IO Bool
rotatedTexture renderer texture source sx sy sw sh destination dx dy dw dh angle Nothing flip =
  (/= 0) <$> primIO (prim__renderTextureRotated renderer texture
                     (cast source + 2 * cast destination + 8 * flipValue flip)
                     sx sy sw sh dx dy dw dh angle 0 0)
rotatedTexture renderer texture source sx sy sw sh destination dx dy dw dh angle (Just (MkRotationCenter cx cy)) flip =
  (/= 0) <$> primIO (prim__renderTextureRotated renderer texture
                     (cast source + 2 * cast destination + 4 + 8 * flipValue flip)
                     sx sy sw sh dx dy dw dh angle cx cy)

||| Draw with clockwise rotation in degrees and optional mirroring, on the main thread.
||| Source uses texture pixels. Nothing selects the whole texture.
||| Destination uses drawing coordinates. Nothing fills the current target.
||| The center is relative to the destination's top-left corner. Nothing uses its midpoint.
||| Rectangles and center convert to float. The angle remains double precision.
||| Use the creating renderer, keep both handles alive, and do not draw a target into itself.
||| Returns False on failure. Read getError immediately after failure.
export
renderTextureRotated : Renderer -> Texture access -> Maybe FRect -> Maybe FRect ->
                       Double -> Maybe RotationCenter -> TextureFlip -> IO Bool
renderTextureRotated (MkRenderer renderer) (MkTexture texture) Nothing Nothing angle center flip =
  rotatedTexture renderer texture 0 0 0 0 0 0 0 0 0 0 angle center flip
renderTextureRotated (MkRenderer renderer) (MkTexture texture) (Just (MkFRect sx sy sw sh)) Nothing angle center flip =
  rotatedTexture renderer texture 1 sx sy sw sh 0 0 0 0 0 angle center flip
renderTextureRotated (MkRenderer renderer) (MkTexture texture) Nothing (Just (MkFRect dx dy dw dh)) angle center flip =
  rotatedTexture renderer texture 0 0 0 0 0 1 dx dy dw dh angle center flip
renderTextureRotated (MkRenderer renderer) (MkTexture texture) (Just (MkFRect sx sy sw sh)) (Just (MkFRect dx dy dw dh)) angle center flip =
  rotatedTexture renderer texture 1 sx sy sw sh 1 dx dy dw dh angle center flip

||| Allocate once and reuse for coordinate conversions. Do not share between threads.
export
newCoordinateBuffer : IO (Either String CoordinateBuffer)
newCoordinateBuffer = owned MkCoordinateBuffer prim__coordinateNew

||| Do not use the buffer after this call. Copied points remain valid.
export
freeCoordinateBuffer : CoordinateBuffer -> IO ()
freeCoordinateBuffer (MkCoordinateBuffer ptr) = primIO (prim__coordinateFree ptr)

convertedPoint : AnyPtr -> PrimIO Int -> IO (Either String (Point space))
convertedPoint buffer action = do
  ok <- primIO action
  if ok == 0 then Left <$> getError else do
    x <- primIO (prim__coordinateX buffer)
    y <- primIO (prim__coordinateY buffer)
    pure (Right (MkPoint x y))

||| Convert a window point using the renderer's current target, viewport, and scales.
||| Call on the main thread. Match the renderer to the event's window first.
||| This does not clip points outside the drawing area or modify input events.
export
renderCoordinatesFromWindow : Renderer -> CoordinateBuffer -> Point WindowSpace ->
                              IO (Either String (Point RenderSpace))
renderCoordinatesFromWindow (MkRenderer renderer) (MkCoordinateBuffer buffer) (MkPoint x y) =
  convertedPoint buffer (prim__renderCoordinatesFromWindow renderer x y buffer)

||| Convert a render point to window coordinates on the main thread.
||| Returned points own their values and survive buffer reuse or destruction.
export
renderCoordinatesToWindow : Renderer -> CoordinateBuffer -> Point RenderSpace ->
                            IO (Either String (Point WindowSpace))
renderCoordinatesToWindow (MkRenderer renderer) (MkCoordinateBuffer buffer) (MkPoint x y) =
  convertedPoint buffer (prim__renderCoordinatesToWindow renderer x y buffer)

||| Scale drawing coordinates on the current target. Use 1 and 1 to reset.
||| Values convert to SDL floats. Call on the main thread. Returns False on failure.
export
setRenderScale : Renderer -> Double -> Double -> IO Bool
setRenderScale (MkRenderer ptr) x y = (/= 0) <$> primIO (prim__setRenderScale ptr x y)

||| Set a fixed logical resolution on the current target, using positive dimensions.
||| Pass 0, 0, and PresentationDisabled to restore the target's pixel resolution.
||| Does not convert input event coordinates. Call on the main thread.
export
setRenderLogicalPresentation : Renderer -> Int32 -> Int32 -> LogicalPresentation -> IO Bool
setRenderLogicalPresentation (MkRenderer ptr) width height mode =
  (/= 0) <$> primIO (prim__setRenderLogicalPresentation ptr width height (presentationValue mode))

||| Set the current target's drawing area and coordinate origin.
||| Nothing selects the whole target. Width and height must be nonnegative.
||| Call on the main thread. Returns False on failure.
export
setRenderViewport : Renderer -> Maybe Rect -> IO Bool
setRenderViewport (MkRenderer ptr) Nothing =
  (/= 0) <$> primIO (prim__resetRenderViewport ptr)
setRenderViewport (MkRenderer ptr) (Just (MkRect x y width height)) =
  (/= 0) <$> primIO (prim__setRenderViewport ptr x y width height)

||| Set clipping relative to the current viewport. Nothing disables clipping.
||| An empty rectangle clips all drawing. Each target keeps its own clip state.
||| Call on the main thread. Returns False on failure.
export
setRenderClipRect : Renderer -> Maybe Rect -> IO Bool
setRenderClipRect (MkRenderer ptr) Nothing =
  (/= 0) <$> primIO (prim__resetRenderClipRect ptr)
setRenderClipRect (MkRenderer ptr) (Just (MkRect x y width height)) =
  (/= 0) <$> primIO (prim__setRenderClipRect ptr x y width height)

||| Set blending for shapes, not textures. Call on the main thread.
||| SDL can select the closest supported mode. Returns False on failure.
export
setDrawBlendMode : Renderer -> BlendMode -> IO Bool
setDrawBlendMode (MkRenderer ptr) mode =
  (/= 0) <$> primIO (prim__setDrawBlendMode ptr (blendBits mode))

||| Rendering calls return False on failure. Call getError for details.
export
setDrawColor : Renderer -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO Bool
setDrawColor (MkRenderer ptr) r g b a =
  (/= 0) <$> primIO (prim__drawColor ptr r g b a)

||| Clear the entire current target, ignoring the viewport and clip rectangle.
export
clear : Renderer -> IO Bool
clear (MkRenderer ptr) = (/= 0) <$> primIO (prim__clear ptr)

export
present : Renderer -> IO Bool
present (MkRenderer ptr) = (/= 0) <$> primIO (prim__present ptr)

||| Coordinates convert to SDL's single-precision floats in the C adapter.
export
fillRect : Renderer -> Double -> Double -> Double -> Double -> IO Bool
fillRect (MkRenderer ptr) x y w h = (/= 0) <$> primIO (prim__fillRect ptr x y w h)

||| Draw a point in render coordinates using the current drawing color and blend mode.
||| Call on the main thread. Coordinates convert to SDL float. False means failure.
export
drawPoint : Renderer -> Point RenderSpace -> IO Bool
drawPoint (MkRenderer ptr) (MkPoint x y) = (/= 0) <$> primIO (prim__drawPoint ptr x y)

||| Draw a line between render-coordinate points using the current color and blend mode.
||| Call on the main thread. Coordinates convert to SDL float. False means failure.
export
drawLine : Renderer -> Point RenderSpace -> Point RenderSpace -> IO Bool
drawLine (MkRenderer ptr) (MkPoint x1 y1) (MkPoint x2 y2) =
  (/= 0) <$> primIO (prim__drawLine ptr x1 y1 x2 y2)

||| Draw a rectangle outline using the current drawing color and blend mode.
||| Nothing outlines the entire current target. Just uses an FRect in drawing coordinates.
||| Call on the main thread. Coordinates convert to SDL float. False means failure.
export
drawRect : Renderer -> Maybe FRect -> IO Bool
drawRect (MkRenderer ptr) Nothing = (/= 0) <$> primIO (prim__drawRect ptr 0 0 0 0 0)
drawRect (MkRenderer ptr) (Just (MkFRect x y width height)) =
  (/= 0) <$> primIO (prim__drawRect ptr 1 x y width height)

||| Text field bounds in window coordinates. The cursor offset is relative to x.
||| The cursor offset is a coordinate, not a character or byte index.
public export
record TextInputArea where
  constructor MkTextInputArea
  x : Int32
  y : Int32
  width : Int32
  height : Int32
  cursorOffset : Int32

||| Set the area and cursor used to position native input method windows.
||| Nothing clears the area. Call on the main thread. Returns False on failure.
||| The C adapter uses a stack rectangle and does not retain this value.
export
setTextInputArea : Window -> Maybe TextInputArea -> IO Bool
setTextInputArea (MkWindow ptr) Nothing =
  (/= 0) <$> primIO (prim__clearTextInputArea ptr)
setTextInputArea (MkWindow ptr) (Just (MkTextInputArea x y width height cursor)) =
  (/= 0) <$> primIO (prim__setTextInputArea ptr x y width height cursor)

||| Dismiss native composition without disabling text input. Call on the main thread.
||| Returns False on failure. Clear the application's composition display separately.
export
clearComposition : Window -> IO Bool
clearComposition (MkWindow ptr) = (/= 0) <$> primIO (prim__clearComposition ptr)

||| Enable text input for a live window on the main thread. Disabled by default.
||| This can show a screen keyboard. Pair with stopTextInput.
export
startTextInput : Window -> IO Bool
startTextInput (MkWindow ptr) = (/= 0) <$> primIO (prim__startTextInput ptr)

||| Disable text input on the main thread. Returns False on failure.
export
stopTextInput : Window -> IO Bool
stopTextInput (MkWindow ptr) = (/= 0) <$> primIO (prim__stopTextInput ptr)

||| Query a live window on the main thread. False means input is inactive.
export
textInputActive : Window -> IO Bool
textInputActive (MkWindow ptr) = (/= 0) <$> primIO (prim__textInputActive ptr)

export
newEventBuffer : IO (Either String EventBuffer)
newEventBuffer = owned MkEventBuffer prim__eventNew

export
freeEventBuffer : EventBuffer -> IO ()
freeEventBuffer (MkEventBuffer ptr) = primIO (prim__eventFree ptr)

||| Poll on the main thread. Nothing means the queue is empty.
||| Returns only the type. Use pollEventData when you need event data.
export
pollEvent : EventBuffer -> IO (Maybe EventType)
pollEvent (MkEventBuffer ptr) = do
  ready <- primIO (prim__poll ptr)
  if ready == 0 then pure Nothing else do
    kind <- primIO (prim__eventKind ptr)
    event <- case kind of
      1 => pure QuitRequested
      2 => pure WindowCloseRequested
      3 => pure KeyDown
      4 => pure KeyUp
      5 => pure MouseMotion
      6 => pure MouseButtonDown
      7 => pure MouseButtonUp
      8 => pure MouseWheel
      9 => pure TextInput
      10 => pure TextEditing
      11 => pure WindowResized
      12 => pure WindowPixelSizeChanged
      _ => OtherEvent <$> primIO (prim__eventType ptr)
    pure (Just event)

keyboardData : AnyPtr -> KeyAction -> IO KeyboardData
keyboardData ptr action = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  scan <- MkScancode <$> primIO (prim__eventScancode ptr)
  key <- MkKeycode <$> primIO (prim__eventKeycode ptr)
  mods <- MkKeyModifiers <$> primIO (prim__eventModifiers ptr)
  repeated <- (/= 0) <$> primIO (prim__eventRepeat ptr)
  pure (MkKeyboardData window action scan key mods repeated)

mouseMotionData : AnyPtr -> IO MouseMotionData
mouseMotionData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  mouse <- MkMouseID <$> primIO (prim__eventMouseID ptr)
  buttons <- MkMouseButtons <$> primIO (prim__eventMouseButtons ptr)
  x <- primIO (prim__eventMouseX ptr)
  y <- primIO (prim__eventMouseY ptr)
  dx <- primIO (prim__eventMouseDX ptr)
  dy <- primIO (prim__eventMouseDY ptr)
  pure (MkMouseMotionData window mouse buttons x y dx dy)

mouseButtonData : AnyPtr -> MouseAction -> IO MouseButtonData
mouseButtonData ptr action = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  mouse <- MkMouseID <$> primIO (prim__eventMouseID ptr)
  button <- MkMouseButton <$> primIO (prim__eventMouseButton ptr)
  clicks <- primIO (prim__eventMouseClicks ptr)
  x <- primIO (prim__eventMouseX ptr)
  y <- primIO (prim__eventMouseY ptr)
  pure (MkMouseButtonData window mouse button action clicks x y)

mouseWheelData : AnyPtr -> IO MouseWheelData
mouseWheelData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  mouse <- MkMouseID <$> primIO (prim__eventMouseID ptr)
  x <- primIO (prim__eventWheelX ptr)
  y <- primIO (prim__eventWheelY ptr)
  rawDirection <- primIO (prim__eventWheelDirection ptr)
  let direction = case rawDirection of
        0 => WheelNormal
        1 => WheelFlipped
        other => OtherWheelDirection other
  mouseX <- primIO (prim__eventMouseX ptr)
  mouseY <- primIO (prim__eventMouseY ptr)
  integerX <- primIO (prim__eventWheelIntegerX ptr)
  integerY <- primIO (prim__eventWheelIntegerY ptr)
  pure (MkMouseWheelData window mouse x y direction mouseX mouseY integerX integerY)

textInputData : AnyPtr -> IO TextInputData
textInputData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  text <- primIO (prim__eventText ptr)
  pure (MkTextInputData window text)

textEditingData : AnyPtr -> IO TextEditingData
textEditingData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  text <- primIO (prim__eventText ptr)
  start <- primIO (prim__eventEditStart ptr)
  length <- primIO (prim__eventEditLength ptr)
  pure (MkTextEditingData window text start length)

windowSizeData : AnyPtr -> IO WindowSizeData
windowSizeData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  width <- primIO (prim__eventWindowData1 ptr)
  height <- primIO (prim__eventWindowData2 ptr)
  pure (MkWindowSizeData window width height)

pixelSizeData : AnyPtr -> IO PixelSizeData
pixelSizeData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  width <- primIO (prim__eventWindowData1 ptr)
  height <- primIO (prim__eventWindowData2 ptr)
  pure (MkPixelSizeData window width height)

eventData : AnyPtr -> IO Event
eventData ptr = do
  kind <- primIO (prim__eventKind ptr)
  timestamp <- primIO (prim__eventTimestamp ptr)
  case kind of
    1 => pure (QuitEvent timestamp)
    2 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowCloseEvent timestamp window)
    3 => KeyboardEvent timestamp <$> keyboardData ptr Pressed
    4 => KeyboardEvent timestamp <$> keyboardData ptr Released
    5 => MouseMotionEvent timestamp <$> mouseMotionData ptr
    6 => MouseButtonEvent timestamp <$> mouseButtonData ptr ButtonPressed
    7 => MouseButtonEvent timestamp <$> mouseButtonData ptr ButtonReleased
    8 => MouseWheelEvent timestamp <$> mouseWheelData ptr
    9 => TextInputEvent timestamp <$> textInputData ptr
    10 => TextEditingEvent timestamp <$> textEditingData ptr
    11 => WindowResizedEvent timestamp <$> windowSizeData ptr
    12 => WindowPixelSizeChangedEvent timestamp <$> pixelSizeData ptr
    _ => UnknownEvent timestamp <$> primIO (prim__eventType ptr)

||| Consume one event on the main thread. Nothing means the queue is empty.
||| Returned values remain valid after buffer reuse or destruction.
||| Do not call pollEvent first: each poll consumes a separate event.
export
pollEventData : EventBuffer -> IO (Maybe Event)
pollEventData (MkEventBuffer ptr) = do
  ready <- primIO (prim__poll ptr)
  if ready == 0 then pure Nothing else Just <$> eventData ptr

||| Wait indefinitely for one event on the main thread that initialized video.
||| Consumes that event and copies its data. Failure returns a copied SDL error.
||| Reuse the buffer. Returned data survives buffer reuse or destruction.
export
waitEventData : EventBuffer -> IO (Either String Event)
waitEventData (MkEventBuffer ptr) = do
  ready <- primIO (prim__waitEvent ptr)
  if ready == 0 then Left <$> getError else Right <$> eventData ptr

||| Wait up to timeoutMS milliseconds on the main thread that initialized video.
||| Valid timeouts range from 0 through 2147483647. Zero does not wait.
||| Clears SDL's error before waiting. No event and no error returns Right Nothing.
||| An SDL error without an event returns Left. Actual waits can exceed the timeout.
||| Consumes at most one event. Copied data survives buffer reuse or destruction.
export
waitEventDataTimeout : EventBuffer -> Bits32 -> IO (Either String (Maybe Event))
waitEventDataTimeout (MkEventBuffer ptr) timeoutMS = do
  status <- primIO (prim__waitEventTimeout ptr timeoutMS)
  if status < 0 then Left <$> getError
     else if status == 0 then pure (Right Nothing)
             else Right . Just <$> eventData ptr

||| Milliseconds since SDL initialization. Safe on any thread.
export
ticks : IO Bits64
ticks = primIO prim__ticks

||| Nanoseconds since SDL initialization. Safe on any thread.
||| The clock's actual resolution depends on the platform.
export
ticksNS : IO Bits64
ticksNS = primIO prim__ticksNS

||| High-resolution counter. Only differences between samples are meaningful.
||| Divide the difference by performanceFrequency to obtain seconds.
||| Safe on any thread. This is not a wall-clock timestamp.
export
performanceCounter : IO Bits64
performanceCounter = primIO prim__performanceCounter

||| Counter increments per second, not necessarily nanoseconds. Safe on any thread.
export
performanceFrequency : IO Bits64
performanceFrequency = primIO prim__performanceFrequency

||| Wait at least this many milliseconds on the calling thread.
||| The operating system can delay return beyond the requested time.
export
delay : Bits32 -> IO ()
delay ms = primIO (prim__delay ms)

||| Wait at least this many nanoseconds on the calling thread.
||| Nanosecond units do not guarantee nanosecond scheduling accuracy.
export
delayNS : Bits64 -> IO ()
delayNS ns = primIO (prim__delayNS ns)

||| Attempt a precise wait in nanoseconds on the calling thread.
||| SDL can busy-wait and consume CPU time. Return can still be late.
export
delayPrecise : Bits64 -> IO ()
delayPrecise ns = primIO (prim__delayPrecise ns)
