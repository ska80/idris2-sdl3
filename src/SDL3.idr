module SDL3

import public SDL3.Events
import public SDL3.Flags
import SDL3.Raw

%default total

||| Owned window. Destroy after its renderer, before quit.
export
data Window = MkWindow AnyPtr

||| Owned renderer. Its window must remain alive.
export
data Renderer = MkRenderer AnyPtr

||| Owned CPU image data. Destroy exactly once after use.
export
data Surface = MkSurface AnyPtr

public export
data TextureAccess = StaticAccess | StreamingAccess | TargetAccess

||| Owned texture. Its creating renderer must remain alive.
||| The access parameter prevents non-target textures from becoming render targets.
export
data Texture : TextureAccess -> Type where
  MkTexture : AnyPtr -> Texture access

||| SDL floating-point rectangle. Values convert to single precision in C.
public export
record FRect where
  constructor MkFRect
  x : Double
  y : Double
  width : Double
  height : Double

||| Reusable native event storage. Free exactly once.
export
data EventBuffer = MkEventBuffer AnyPtr

public export
data EventType = QuitRequested
               | WindowCloseRequested
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

||| Create an RGBA32 texture for off-screen drawing on the main thread.
||| Contents are undefined until drawn. Width and height must be positive C ints.
export
createTargetTexture : Renderer -> Int -> Int -> IO (Either String (Texture TargetAccess))
createTargetTexture (MkRenderer ptr) width height =
  if width <= 0 || height <= 0 || width > 2147483647 || height > 2147483647
     then pure (Left "Texture dimensions must be positive 32-bit integers")
     else owned MkTexture (prim__createTargetTexture ptr width height)

||| Destroy on the main thread, before the creating renderer.
||| Switch away from this texture as a render target first. Do not reuse the handle.
export
destroyTexture : Texture access -> IO ()
destroyTexture (MkTexture ptr) = primIO (prim__destroyTexture ptr)

||| Select an off-screen target. Nothing restores drawing to the window.
||| The texture must belong to this renderer. Call on the main thread.
export
setRenderTarget : Renderer -> Maybe (Texture TargetAccess) -> IO Bool
setRenderTarget (MkRenderer renderer) Nothing =
  (/= 0) <$> primIO (prim__resetRenderTarget renderer)
setRenderTarget (MkRenderer renderer) (Just (MkTexture texture)) =
  (/= 0) <$> primIO (prim__setRenderTarget renderer texture)

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

||| Rendering calls return False on failure. Call getError for details.
export
setDrawColor : Renderer -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO Bool
setDrawColor (MkRenderer ptr) r g b a =
  (/= 0) <$> primIO (prim__drawColor ptr r g b a)

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

||| Consume one event on the main thread. Nothing means the queue is empty.
||| Returned values remain valid after buffer reuse or destruction.
||| Do not call pollEvent first: each poll consumes a separate event.
export
pollEventData : EventBuffer -> IO (Maybe Event)
pollEventData (MkEventBuffer ptr) = do
  ready <- primIO (prim__poll ptr)
  if ready == 0 then pure Nothing else do
    kind <- primIO (prim__eventKind ptr)
    timestamp <- primIO (prim__eventTimestamp ptr)
    event <- case kind of
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
      _ => UnknownEvent timestamp <$> primIO (prim__eventType ptr)
    pure (Just event)

||| Milliseconds since SDL initialization.
export
ticks : IO Bits64
ticks = primIO prim__ticks

export
delay : Bits32 -> IO ()
delay ms = primIO (prim__delay ms)
