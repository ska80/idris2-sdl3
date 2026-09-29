module SDL3

import public SDL3.Events
import public SDL3.Flags
import SDL3.Raw

import Data.Buffer
import Data.Bits
import System.FFI

%default total

||| Owned window and reusable native size storage. Destroy after its renderer, before quit.
export
data Window = MkWindow AnyPtr NativeSize

||| Request or cancel a window's attention indication. Appearance and duration depend on the platform.
public export
data FlashOperation = CancelFlash | FlashBriefly | FlashUntilFocused

flashOperationCode : FlashOperation -> Int32
flashOperationCode CancelFlash = 0
flashOperationCode FlashBriefly = 1
flashOperationCode FlashUntilFocused = 2

||| Owned renderer. Its window must remain alive.
export
data Renderer = MkRenderer AnyPtr

||| Synchronize presentation with display refreshes, or disable synchronization.
||| VSyncInterval requires a value from 1 through 2147483647.
public export
data VSyncMode = VSyncDisabled
               | VSyncAdaptive
               | VSyncInterval Bits32

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
data BlendMode = NoBlend
               | AlphaBlend
               | PremultipliedAlphaBlend
               | AdditiveBlend
               | PremultipliedAdditiveBlend
               | ModulateBlend
               | MultiplyBlend
               | OtherBlendMode Bits32

blendBits : BlendMode -> Bits32
blendBits NoBlend = 0
blendBits AlphaBlend = 1
blendBits PremultipliedAlphaBlend = 0x10
blendBits AdditiveBlend = 2
blendBits PremultipliedAdditiveBlend = 0x20
blendBits ModulateBlend = 4
blendBits MultiplyBlend = 8
blendBits (OtherBlendMode code) = code

||| Compare SDL codes, including alternate representations of named modes.
export
Eq BlendMode where
  x == y = blendBits x == blendBits y

blendModeFromBits : Bits32 -> BlendMode
blendModeFromBits 0 = NoBlend
blendModeFromBits 1 = AlphaBlend
blendModeFromBits 2 = AdditiveBlend
blendModeFromBits 4 = ModulateBlend
blendModeFromBits 8 = MultiplyBlend
blendModeFromBits 0x10 = PremultipliedAlphaBlend
blendModeFromBits 0x20 = PremultipliedAdditiveBlend
blendModeFromBits other = OtherBlendMode other

||| Multiplier for a source or destination pixel component in a blend equation.
public export
data BlendFactor = ZeroFactor | OneFactor
                 | SourceColorFactor | OneMinusSourceColorFactor
                 | SourceAlphaFactor | OneMinusSourceAlphaFactor
                 | DestinationColorFactor | OneMinusDestinationColorFactor
                 | DestinationAlphaFactor | OneMinusDestinationAlphaFactor

factorValue : BlendFactor -> Int32
factorValue ZeroFactor = 1
factorValue OneFactor = 2
factorValue SourceColorFactor = 3
factorValue OneMinusSourceColorFactor = 4
factorValue SourceAlphaFactor = 5
factorValue OneMinusSourceAlphaFactor = 6
factorValue DestinationColorFactor = 7
factorValue OneMinusDestinationColorFactor = 8
factorValue DestinationAlphaFactor = 9
factorValue OneMinusDestinationAlphaFactor = 10

||| Combine the multiplied source and destination components. Subtract means source minus destination.
public export
data BlendOperation = BlendAdd | BlendSubtract | BlendReverseSubtract | BlendMinimum | BlendMaximum

operationValue : BlendOperation -> Int32
operationValue BlendAdd = 1
operationValue BlendSubtract = 2
operationValue BlendReverseSubtract = 3
operationValue BlendMinimum = 4
operationValue BlendMaximum = 5

||| One equation for RGB or alpha: operation(source * sourceFactor, destination * destinationFactor).
public export
record BlendEquation where
  constructor MkBlendEquation
  sourceFactor : BlendFactor
  destinationFactor : BlendFactor
  operation : BlendOperation

||| Compose RGB and alpha equations without creating resources or changing renderer state.
||| Safe on any thread. Composition does not test renderer support or premultiply pixel data.
||| Named SDL codes use their named constructors. Other codes use OtherBlendMode.
export
composeBlendMode : BlendEquation -> BlendEquation -> IO BlendMode
composeBlendMode (MkBlendEquation srcRGB dstRGB rgbOp) (MkBlendEquation srcA dstA alphaOp) = do
  code <- primIO (prim__composeBlendMode (factorValue srcRGB) (factorValue dstRGB) (operationValue rgbOp)
                                       (factorValue srcA) (factorValue dstA) (operationValue alphaOp))
  pure (blendModeFromBits code)

||| Nearest selects a source pixel. Linear interpolates neighboring pixels.
public export
data ScaleMode = NearestScale | LinearScale | OtherScaleMode Int32

scaleValue : ScaleMode -> Int
scaleValue NearestScale = 0
scaleValue LinearScale = 1
scaleValue (OtherScaleMode code) = cast code

||| Compare SDL mode codes, including alternate representations of named modes.
public export
Eq ScaleMode where
  NearestScale == NearestScale = True
  LinearScale == LinearScale = True
  OtherScaleMode x == OtherScaleMode y = x == y
  NearestScale == OtherScaleMode x = x == 0
  OtherScaleMode x == NearestScale = x == 0
  LinearScale == OtherScaleMode x = x == 1
  OtherScaleMode x == LinearScale = x == 1
  _ == _ = False

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
  MkTexture : NativeTexture -> Texture access

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

||| Caller-owned reusable storage for one texture lock. Free exactly once after its last use.
export
data TextureLockBuffer = MkTextureLockBuffer NativeTextureLock

||| Borrowed write-only RGBA view. Native access ends at unlock, and the storage must remain alive.
||| The generation rejects old views while storage is alive. It does not prevent use after storage destruction.
export
data LockedRGBA = MkLockedRGBA NativeTextureLock Bits64 (Size PixelUnits) Int32

||| Copied dimensions of the locked region, not necessarily the whole texture.
export
lockedRGBASize : LockedRGBA -> Size PixelUnits
lockedRGBASize (MkLockedRGBA _ _ size _) = size

||| Copied byte stride between locked rows. Do not assume width * 4 or writable row padding.
export
lockedRGBAPitch : LockedRGBA -> Int32
lockedRGBAPitch (MkLockedRGBA _ _ _ pitch) = pitch

||| Reusable output storage for coordinate conversion. Free exactly once.
export
data CoordinateBuffer = MkCoordinateBuffer NativePoint

||| Fixed-capacity native array of render-space points. Free exactly once.
export
data PointBuffer = MkPointBuffer AnyPtr

||| Fixed-capacity native array of floating-point drawing rectangles. Free exactly once.
export
data RectBuffer = MkRectBuffer AnyPtr

||| Reusable native event storage. Free exactly once.
export
data EventBuffer = MkEventBuffer AnyPtr

public export
data EventType = QuitRequested
               | WindowCloseRequested
               | WindowResized
               | WindowPixelSizeChanged
               | WindowDisplayScaleChanged
               | WindowFocusGained
               | WindowFocusLost
               | WindowMouseEnter
               | WindowMouseLeave
               | WindowMinimized
               | WindowMaximized
               | WindowRestored
               | WindowShown
               | WindowHidden
               | WindowExposed
               | WindowMoved
               | WindowEnterFullscreen
               | WindowLeaveFullscreen
               | GamepadAdded | GamepadRemoved | GamepadRemapped | GamepadAxisMotion
               | GamepadButtonDown | GamepadButtonUp
               | DropFile | DropText | DropBegin | DropComplete | DropPosition
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

ownedTexture : PrimIO NativeTexture -> IO (Either String (Texture access))
ownedTexture action = do
  ptr <- primIO action
  null <- primIO (prim__textureIsNull ptr)
  if null /= 0 then Left <$> getError else pure (Right (MkTexture ptr))

newWindow : String -> Int -> Int -> WindowFlags -> IO (Either String Window)
newWindow title width height flags = do
  storage <- primIO prim__newSize
  0 <- primIO (prim__sizeIsNull storage) | _ => Left <$> getError
  ptr <- primIO (prim__createWindow title width height (windowBits flags))
  0 <- primIO (prim__isNull ptr) | _ => do
    err <- getError
    primIO (prim__freeSize storage)
    pure (Left err)
  pure (Right (MkWindow ptr storage))

||| Width and height must be positive C int values. Call on the main thread.
||| Allocates size storage once. Queries reuse it until window destruction.
export
createWindow : String -> Int -> Int -> WindowFlags -> IO (Either String Window)
createWindow title width height flags =
  if width <= 0 || height <= 0 || width > 2147483647 || height > 2147483647
     then pure (Left "Window dimensions must be positive 32-bit integers")
     else newWindow title width height flags

||| Request positive window-coordinate dimensions, not pixel dimensions, on the main thread.
||| The window system can delay, adjust, or deny the request. True does not guarantee the requested size.
||| Use syncWindow if you need to wait, then query the actual dimensions. Read getError after False.
export
setWindowSize : Window -> Size WindowUnits -> IO Bool
setWindowSize (MkWindow ptr _) (MkSize width height) =
  (/= 0) <$> primIO (prim__setWindowSize ptr width height)

||| Wait for pending window state on the main thread. This can block for window-system animations.
||| Does nothing when changes are immediate. False can indicate a timeout. Read getError after False.
||| Does not synchronize GPU work or guarantee that a size request was granted exactly.
export
syncWindow : Window -> IO Bool
syncWindow (MkWindow ptr _) = (/= 0) <$> primIO (prim__syncWindow ptr)

||| Do not use the window after this call. Destroy its renderer first.
export
destroyWindow : Window -> IO ()
destroyWindow (MkWindow ptr storage) = do
  primIO (prim__destroyWindow ptr)
  primIO (prim__freeSize storage)

||| Identifier for a live window. The identifier does not extend its lifetime.
||| Zero means failure. Call on the main thread.
export
getWindowID : Window -> IO (Either String WindowID)
getWindowID (MkWindow ptr _) = do
  value <- primIO (prim__getWindowID ptr)
  if value == 0 then Left <$> getError else pure (Right (MkWindowID value))

||| Copy the window's UTF-8 title on the main thread, while the window is alive.
||| An untitled window returns an empty string. The copy survives title changes and window destruction.
||| The direct foreign binding copies SDL's borrowed string into an Idris String.
export
getWindowTitle : Window -> IO String
getWindowTitle (MkWindow ptr _) = primIO (prim__getWindowTitle ptr)

||| Set a UTF-8 title on the main thread, while the window is alive. Empty text clears the title.
||| As with createWindow, do not include embedded NUL characters: C strings end at the first NUL.
||| SDL copies the supplied title. Returns False on failure. Read getError immediately after False.
export
setWindowTitle : Window -> String -> IO Bool
setWindowTitle (MkWindow ptr _) title = (/= 0) <$> primIO (prim__setWindowTitle ptr title)

||| Request minimization of a live window on the main thread. Read getError immediately after False.
||| Requests can be delayed or denied. In fullscreen this has no direct effect, but can affect later windowed state.
export
minimizeWindow : Window -> IO Bool
minimizeWindow (MkWindow ptr _) = (/= 0) <$> primIO (prim__minimizeWindow ptr)

||| Request maximization of a live, resizable window on the main thread.
||| Non-resizable windows cannot be maximized. Requests can be delayed or denied.
||| Read getError immediately after False. True alone does not prove a state change.
export
maximizeWindow : Window -> IO Bool
maximizeWindow (MkWindow ptr _) = (/= 0) <$> primIO (prim__maximizeWindow ptr)

||| Request restoration of a minimized or maximized window's size and position on the main thread.
||| Keep the window alive. Read getError immediately after False. Requests can be delayed or denied.
||| In fullscreen this has no direct effect, but can affect later windowed state. It does not leave fullscreen.
export
restoreWindow : Window -> IO Bool
restoreWindow (MkWindow ptr _) = (/= 0) <$> primIO (prim__restoreWindow ptr)

||| Read SDL_WINDOW_MINIMIZED on the main thread, while the window is alive.
||| This is a state, not a success indicator or a hidden-state query.
export
isWindowMinimized : Window -> IO Bool
isWindowMinimized (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  pure ((flags .&. 0x40) /= 0)

||| Read SDL_WINDOW_MAXIMIZED on the main thread, while the window is alive.
||| This is a state, not a success indicator or a fullscreen-state query.
export
isWindowMaximized : Window -> IO Bool
isWindowMaximized (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  pure ((flags .&. 0x80) /= 0)

||| Request cursor confinement (True) or release (False) for a live window on the main thread.
||| Read getError immediately after False. Actual confinement depends on focus and platform support.
||| This is mouse grab, not mouse capture or relative mouse mode. Provide a release or exit action.
export
setWindowMouseGrab : Window -> Bool -> IO Bool
setWindowMouseGrab (MkWindow ptr _) grabbed =
  (/= 0) <$> primIO (prim__setWindowMouseGrab ptr (if grabbed then 1 else 0))

||| Query SDL's mouse grab state on the main thread, while the window is alive.
||| False is a state, not failure. This calls SDL_GetWindowMouseGrab rather than reading a creation flag.
||| The result does not prove physical cursor confinement. Focus changes can change the reported state.
export
getWindowMouseGrab : Window -> IO Bool
getWindowMouseGrab (MkWindow ptr _) = (/= 0) <$> primIO (prim__getWindowMouseGrab ptr)

||| Set a live window's opacity on the main thread. Zero is transparent, one is opaque.
||| Clamps to 0..1 before conversion to SDL float, including infinities. Rejects NaN without changing state.
||| Unsupported setters can fail. Read getError immediately after False. This is not texture alpha modulation.
export
setWindowOpacity : Window -> Double -> IO Bool
setWindowOpacity (MkWindow ptr _) opacity = (/= 0) <$> primIO (prim__setWindowOpacity ptr opacity)

||| Query a live window's opacity on the main thread. Copies the SDL error on failure.
||| Unsupported transparency returns Right 1.0, not an error. SDL float precision is widened to Double.
||| The copied value survives window destruction but does not track later changes.
export
getWindowOpacity : Window -> IO (Either String Double)
getWindowOpacity (MkWindow ptr _) = do
  value <- primIO (prim__getWindowOpacity ptr)
  if value == -1.0 then Left <$> getError else pure (Right value)

||| Request or cancel user attention for a live window on the main thread.
||| Read getError immediately after False. Unsupported platforms can reject every operation, including cancellation.
||| Does not request keyboard focus, raise the window, or wait for the indication to finish.
export
flashWindow : Window -> FlashOperation -> IO Bool
flashWindow (MkWindow ptr _) operation =
  (/= 0) <$> primIO (prim__flashWindow ptr (flashOperationCode operation))

||| Request always-on-top placement (True) or remove it (False) on the main thread.
||| Keep the window alive. Read getError immediately after False.
||| Some backends accept requests without changing the flag. Actual stacking depends on the window system.
export
setWindowAlwaysOnTop : Window -> Bool -> IO Bool
setWindowAlwaysOnTop (MkWindow ptr _) enabled =
  (/= 0) <$> primIO (prim__setWindowAlwaysOnTop ptr (if enabled then 1 else 0))

||| Read SDL_WINDOW_ALWAYS_ON_TOP on the main thread, while the window is alive.
||| Returns a state, not a success indicator or a guarantee of visibility or focus.
export
isWindowAlwaysOnTop : Window -> IO Bool
isWindowAlwaysOnTop (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  pure ((flags .&. windowBits alwaysOnTop) /= 0)

||| Request that a live window be raised and gain keyboard focus on the main thread.
||| Window-manager policy can deny focus. True does not prove that focus changed.
||| Read getError immediately after False. Use showWindow separately for a hidden window.
export
raiseWindow : Window -> IO Bool
raiseWindow (MkWindow ptr _) = (/= 0) <$> primIO (prim__raiseWindow ptr)

||| Read SDL_WINDOW_INPUT_FOCUS on the main thread, while the window is alive.
||| Returns a state, not a success indicator. This is keyboard focus, not mouse focus or visibility.
export
hasKeyboardFocus : Window -> IO Bool
hasKeyboardFocus (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  -- The native build checks this SDL mask. It is not a window creation flag.
  pure ((flags .&. 0x200) /= 0)

||| Request fullscreen (True) or windowed mode (False) on the main thread.
||| Keep the window alive. Read getError immediately after False.
||| A successful request can be delayed or denied. Use events or syncWindow to observe completion.
||| SDL defaults to desktop fullscreen unless an exclusive display mode was selected outside this API.
export
setWindowFullscreen : Window -> Bool -> IO Bool
setWindowFullscreen (MkWindow ptr _) enabled =
  (/= 0) <$> primIO (prim__setWindowFullscreen ptr (if enabled then 1 else 0))

||| Read SDL_WINDOW_FULLSCREEN on the main thread, while the window is alive.
||| Reports SDL's flag, not physical visibility, display mode, or completion of GPU work.
export
isWindowFullscreen : Window -> IO Bool
isWindowFullscreen (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  pure ((flags .&. windowBits fullscreen) /= 0)

||| Request a window border change on the main thread. True requests a border.
||| SDL cannot change fullscreen window borders. Repeating the current state does nothing.
||| Some backends accept requests without changing the flags. Query the reported state afterward.
||| Keep the window alive. Read getError immediately after a False result.
export
setWindowBordered : Window -> Bool -> IO Bool
setWindowBordered (MkWindow ptr _) bordered =
  (/= 0) <$> primIO (prim__setWindowBordered ptr (if bordered then 1 else 0))

||| Read the absence of SDL_WINDOW_BORDERLESS on the main thread, while the window is alive.
||| This reports SDL state, not whether the window manager draws visible decorations.
export
isWindowBordered : Window -> IO Bool
isWindowBordered (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  pure ((flags .&. windowBits borderless) == 0)

||| Request user resizing on the main thread. True allows it. Does not request a new size.
||| SDL cannot change fullscreen window resizability. Repeating the current state does nothing.
||| Some backends accept requests without changing the flags. Query the reported state afterward.
||| Keep the window alive. Read getError immediately after a False result.
export
setWindowResizable : Window -> Bool -> IO Bool
setWindowResizable (MkWindow ptr _) enabled =
  (/= 0) <$> primIO (prim__setWindowResizable ptr (if enabled then 1 else 0))

||| Read SDL_WINDOW_RESIZABLE on the main thread, while the window is alive.
||| This reports user-resizing policy, not the ability to call setWindowSize.
export
isWindowResizable : Window -> IO Bool
isWindowResizable (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  pure ((flags .&. windowBits resizable) /= 0)

||| Show a live window on the main thread. Read getError immediately after False.
||| Does not guarantee keyboard focus or that other windows will not cover it.
export
showWindow : Window -> IO Bool
showWindow (MkWindow ptr _) = (/= 0) <$> primIO (prim__showWindow ptr)

||| Hide a live window on the main thread, without destroying it or its renderer.
||| Read getError immediately after False. Show it again with showWindow.
export
hideWindow : Window -> IO Bool
hideWindow (MkWindow ptr _) = (/= 0) <$> primIO (prim__hideWindow ptr)

||| Read SDL_WINDOW_HIDDEN on the main thread, while the window is alive.
||| False does not imply visibility: the window can be minimized or covered by another window.
export
isWindowHidden : Window -> IO Bool
isWindowHidden (MkWindow ptr _) = do
  flags <- primIO (prim__getWindowFlags ptr)
  pure ((flags .&. windowBits hidden) /= 0)

||| Select SDL's default renderer. Call on the main thread.
export
createRenderer : Window -> IO (Either String Renderer)
createRenderer (MkWindow ptr _) = owned MkRenderer (prim__createRenderer ptr)

export
destroyRenderer : Renderer -> IO ()
destroyRenderer (MkRenderer ptr) = primIO (prim__destroyRenderer ptr)

queriedSize : NativeSize -> PrimIO Int -> IO (Either String (Size unit))
queriedSize storage action = do
  1 <- primIO action | _ => Left <$> getError
  -- Read inside the successful IO continuation. No borrowed view escapes.
  pure (Right (MkSize (getField storage "width") (getField storage "height")))

||| Query window-coordinate dimensions on the main thread. Copies errors on failure.
export
getWindowSize : Window -> IO (Either String (Size WindowUnits))
getWindowSize (MkWindow ptr storage) = queriedSize storage (prim__getWindowSize ptr storage)

||| Query physical pixel dimensions on the main thread, which can differ from window coordinates.
export
getWindowSizeInPixels : Window -> IO (Either String (Size PixelUnits))
getWindowSizeInPixels (MkWindow ptr storage) = queriedSize storage (prim__getWindowSizeInPixels ptr storage)

queriedWindowScale : PrimIO Double -> IO (Either String Double)
queriedWindowScale action = do
  value <- primIO action
  if value == 0 then Left <$> getError else pure (Right value)

||| Query the ratio of backing pixels to window coordinates on the main thread.
||| Keep the window alive. Copies SDL errors on failure. Renderer scale and targets do not define this ratio.
||| SDL returns float precision, widened to Double for the foreign ABI without native output storage.
export
getWindowPixelDensity : Window -> IO (Either String Double)
getWindowPixelDensity (MkWindow ptr _) = queriedWindowScale (prim__getWindowPixelDensity ptr)

||| Query the expected content scale relative to window pixels on the main thread.
||| Combines pixel density with display content scale. This is not necessarily the pixel density.
||| Keep the window alive. Copies SDL errors on failure. Re-query after display scale changes or monitor moves.
||| SDL float precision is widened to Double. This does not change rendering state.
export
getWindowDisplayScale : Window -> IO (Either String Double)
getWindowDisplayScale (MkWindow ptr _) = queriedWindowScale (prim__getWindowDisplayScale ptr)

||| Allocate reusable lock output storage once, outside the frame loop.
export
newTextureLockBuffer : IO (Either String TextureLockBuffer)
newTextureLockBuffer = do
  ptr <- primIO prim__textureLockNew
  0 <- primIO (prim__textureLockIsNull ptr) | _ => Left <$> getError
  pure (Right (MkTextureLockBuffer ptr))

||| Free storage on the main thread. An outstanding lock is unlocked first.
||| Keep any locked texture and its renderer alive. Do not free storage inside a lock callback.
||| After this call, do not use this storage or any borrowed view derived from it.
export
freeTextureLockBuffer : TextureLockBuffer -> IO ()
freeTextureLockBuffer (MkTextureLockBuffer ptr) = primIO (prim__textureLockFree ptr)

||| Lock an RGBA32 streaming texture on the main thread. Nothing locks the whole texture.
||| A region must be positive and wholly inside the texture. Coordinates are texture pixels.
||| Keep storage, texture, and renderer alive. Do not lock an already locked texture, even with other storage.
||| Initialize EVERY pixel in the region before unlocking, including error paths. Old contents are undefined.
||| Prefer SDL3.Scoped.withTextureLockRGBA for cleanup on ordinary Right or Left returns.
export
lockTextureRGBA : TextureLockBuffer -> Texture StreamingAccess -> Maybe Rect -> IO (Either String LockedRGBA)
lockTextureRGBA (MkTextureLockBuffer storage) (MkTexture texture) region = do
  result <- primIO $ case region of
    Nothing => prim__lockTextureRGBA storage texture 0 0 0 0 0
    Just (MkRect x y w h) => prim__lockTextureRGBA storage texture 1 x y w h
  if result == the Int 0 then Left <$> getError else
    pure (Right (MkLockedRGBA storage (getField storage "generation")
                 (MkSize (getField storage "width") (getField storage "height")) (getField storage "pitch")))

||| Unlock and submit changes on the main thread. Does not roll back changes or report GPU completion.
||| Inactive or stale views return False. Read getError immediately after False.
||| SDL_UnlockTexture returns void. True means the call was made, not that a GPU upload succeeded.
export
unlockTextureRGBA : LockedRGBA -> IO Bool
unlockTextureRGBA (MkLockedRGBA storage generation _ _) =
  (/= 0) <$> primIO (prim__unlockTextureRGBA storage generation)

||| Write one RGBA pixel at coordinates relative to the locked region, with bounds checks.
||| Requires an active view and live storage on the main thread. Read getError after False.
||| This alone does not initialize the rest of the region. No reads of old pixel contents are provided.
export
setLockedPixelRGBA : LockedRGBA -> Int32 -> Int32 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO Bool
setLockedPixelRGBA (MkLockedRGBA storage generation _ _) x y r g b a =
  (/= 0) <$> primIO (prim__lockedPixelRGBA storage generation x y r g b a)

||| Initialize the whole locked region to one RGBA color, excluding row padding.
||| Requires an active view and live storage on the main thread. Read getError after False.
export
fillLockedRGBA : LockedRGBA -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO Bool
fillLockedRGBA (MkLockedRGBA storage generation _ _) r g b a =
  (/= 0) <$> primIO (prim__lockedFillRGBA storage generation r g b a)

||| Copy the whole locked region from a caller-owned RGBA byte buffer. Source byte zero is the region origin.
||| Source pitch must cover width * 4 bytes, and capacity must cover pitch * height, including final-row padding.
||| Requires an active view and live storage on the main thread. Do not modify the source during this call.
||| Invalid input fails before copying. The source can be reused after return. Read getError after False.
export
copyLockedRGBA : LockedRGBA -> Buffer -> Int32 -> IO Bool
copyLockedRGBA (MkLockedRGBA storage generation _ _) buffer pitch = do
  size <- rawSize buffer
  (/= 0) <$> primIO (prim__lockedCopyRGBA storage generation buffer (cast size) pitch)

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
  ownedTexture (prim__createTextureFromSurface renderer surface)

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
     else ownedTexture (prim__createTargetTexture ptr width height)

||| Create an RGBA32 texture for repeated uploads on the main thread.
||| Pixel bytes use R, G, B, A order. Contents are undefined until uploaded.
export
createStreamingTexture : Renderer -> Int -> Int -> IO (Either String (Texture StreamingAccess))
createStreamingTexture (MkRenderer ptr) width height =
  if width <= 0 || height <= 0 || width > 2147483647 || height > 2147483647
     then pure (Left "Texture dimensions must be positive 32-bit integers")
     else ownedTexture (prim__createStreamingTexture ptr width height)

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

||| Copy the texture's pixel dimensions on the main thread. Applies to every access type.
||| SDL validates the handle before Chez reads its public integer fields.
||| Allocates no native output storage. The copied size survives texture destruction.
||| Keep the texture and its renderer alive throughout the query.
export
getTextureSize : Texture access -> IO (Either String (Size PixelUnits))
getTextureSize (MkTexture ptr) = do
  1 <- primIO (prim__getTextureSize ptr) | _ => Left <$> getError
  pure (Right (MkSize (getField ptr "w") (getField ptr "h")))

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

||| Copy the texture's additional alpha multiplier as a byte, not its pixel alpha values.
||| Call on the main thread, with the texture and renderer alive. Copies SDL errors on failure.
||| The adapter uses one stack byte, with no native heap allocation for output storage.
export
getTextureAlphaMod : Texture access -> IO (Either String Bits8)
getTextureAlphaMod (MkTexture ptr) = do
  value <- primIO (prim__getTextureAlphaMod ptr)
  if value == -1 then Left <$> getError else pure (Right (cast value))

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

queriedBlendMode : PrimIO Int64 -> IO (Either String BlendMode)
queriedBlendMode action = do
  value <- primIO action
  if value == -1 then Left <$> getError else pure (Right (blendModeFromBits (cast value)))

||| Copy the texture blend mode on the main thread. Keep the texture and renderer alive.
||| Preserve custom or unknown SDL codes as OtherBlendMode. Copies SDL errors on failure.
export
getTextureBlendMode : Texture access -> IO (Either String BlendMode)
getTextureBlendMode (MkTexture ptr) = queriedBlendMode (prim__getTextureBlendMode ptr)

||| Copy the current texture filtering mode on the main thread. Keep the texture and renderer alive.
||| Unknown SDL codes are preserved as OtherScaleMode, not treated as query failures.
export
getTextureScaleMode : Texture access -> IO (Either String ScaleMode)
getTextureScaleMode (MkTexture ptr) = do
  value <- primIO (prim__getTextureScaleMode ptr)
  if value == -2147483649 then Left <$> getError else
    pure (Right (case value of
      0 => NearestScale
      1 => LinearScale
      other => OtherScaleMode (cast other)))

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

rotatedTexture : AnyPtr -> NativeTexture -> Int32 -> Double -> Double -> Double -> Double ->
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
newCoordinateBuffer = do
  ptr <- primIO prim__coordinateNew
  0 <- primIO (prim__coordinateIsNull ptr) | _ => Left <$> getError
  pure (Right (MkCoordinateBuffer ptr))

||| Do not use the buffer after this call. Copied points remain valid.
export
freeCoordinateBuffer : CoordinateBuffer -> IO ()
freeCoordinateBuffer (MkCoordinateBuffer ptr) = primIO (prim__coordinateFree ptr)

convertedPoint : NativePoint -> PrimIO Int -> IO (Either String (Point space))
convertedPoint buffer action = do
  1 <- primIO action | _ => Left <$> getError
  pure (Right (MkPoint (getField buffer "x") (getField buffer "y")))

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

||| Copy blending for shapes, not textures. Call on the main thread with a live renderer.
||| This state belongs to the renderer, not to individual render targets.
||| Preserves custom or unknown SDL codes as OtherBlendMode. Copies SDL errors on failure.
export
getDrawBlendMode : Renderer -> IO (Either String BlendMode)
getDrawBlendMode (MkRenderer ptr) = queriedBlendMode (prim__getDrawBlendMode ptr)

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

||| Allocate once for repeated batches. Capacity is 1 through 2147483647, subject to memory limits.
||| All entries start at (0, 0). Do not share the buffer between threads.
export
newPointBuffer : Bits32 -> IO (Either String PointBuffer)
newPointBuffer capacity = owned MkPointBuffer (prim__pointsNew capacity)

||| Free after all draws using this buffer return. Do not use it afterward.
export
freePointBuffer : PointBuffer -> IO ()
freePointBuffer (MkPointBuffer ptr) = primIO (prim__pointsFree ptr)

||| Replace a zero-based entry. Out-of-range indices fail without changing entries.
||| Reuses the native array. Values narrow to SDL floats.
export
setPoint : PointBuffer -> Bits32 -> Point RenderSpace -> IO Bool
setPoint (MkPointBuffer ptr) index (MkPoint x y) = (/= 0) <$> primIO (prim__pointsSet ptr index x y)

||| Draw the first count entries. Count cannot exceed capacity. Zero draws nothing.
||| Call on the main thread. The buffer can be reused after this call returns.
||| Uses current target, color, blending, viewport, clip, scale, and logical presentation.
export
drawPoints : Renderer -> PointBuffer -> Bits32 -> IO Bool
drawPoints (MkRenderer renderer) (MkPointBuffer points) count =
  (/= 0) <$> primIO (prim__drawPoints renderer points count)

||| Join consecutive entries in the first count points. Does not close the path automatically.
||| Counts below two draw nothing. Count cannot exceed capacity. Call on the main thread.
||| Uses current rendering state. The buffer can be reused after this call returns.
export
drawLines : Renderer -> PointBuffer -> Bits32 -> IO Bool
drawLines (MkRenderer renderer) (MkPointBuffer points) count =
  (/= 0) <$> primIO (prim__drawLines renderer points count)

||| Allocate once for repeated batches. Capacity is 1 through 2147483647, subject to memory limits.
||| All rectangle fields start at zero. Do not share the buffer between threads.
export
newRectBuffer : Bits32 -> IO (Either String RectBuffer)
newRectBuffer capacity = owned MkRectBuffer (prim__rectsNew capacity)

||| Free after all draws using this buffer return. Do not use it afterward.
export
freeRectBuffer : RectBuffer -> IO ()
freeRectBuffer (MkRectBuffer ptr) = primIO (prim__rectsFree ptr)

||| Replace a zero-based entry. Out-of-range indices fail without changing entries.
||| Values narrow to SDL floats. Dimensions follow SDL semantics, without extra validation.
export
setRect : RectBuffer -> Bits32 -> FRect -> IO Bool
setRect (MkRectBuffer ptr) index (MkFRect x y width height) =
  (/= 0) <$> primIO (prim__rectsSet ptr index x y width height)

||| Outline the first count rectangles. Count cannot exceed capacity. Zero draws nothing.
||| Call on the main thread. Uses current target, color, blend, viewport, clip, scale, and logical presentation.
||| The buffer can be reused after this call returns. No implicit full-target rectangle is supplied.
export
drawRects : Renderer -> RectBuffer -> Bits32 -> IO Bool
drawRects (MkRenderer renderer) (MkRectBuffer rects) count =
  (/= 0) <$> primIO (prim__drawRects renderer rects count)

||| Fill the first count rectangles. Count cannot exceed capacity. Zero draws nothing.
||| Call on the main thread. Uses current rendering state. Reuse the buffer after this call returns.
export
fillRects : Renderer -> RectBuffer -> Bits32 -> IO Bool
fillRects (MkRenderer renderer) (MkRectBuffer rects) count =
  (/= 0) <$> primIO (prim__fillRects renderer rects count)

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
setTextInputArea (MkWindow ptr _) Nothing =
  (/= 0) <$> primIO (prim__clearTextInputArea ptr)
setTextInputArea (MkWindow ptr _) (Just (MkTextInputArea x y width height cursor)) =
  (/= 0) <$> primIO (prim__setTextInputArea ptr x y width height cursor)

||| Dismiss native composition without disabling text input. Call on the main thread.
||| Returns False on failure. Clear the application's composition display separately.
export
clearComposition : Window -> IO Bool
clearComposition (MkWindow ptr _) = (/= 0) <$> primIO (prim__clearComposition ptr)

||| Enable text input for a live window on the main thread. Disabled by default.
||| This can show a screen keyboard. Pair with stopTextInput.
export
startTextInput : Window -> IO Bool
startTextInput (MkWindow ptr _) = (/= 0) <$> primIO (prim__startTextInput ptr)

||| Disable text input on the main thread. Returns False on failure.
export
stopTextInput : Window -> IO Bool
stopTextInput (MkWindow ptr _) = (/= 0) <$> primIO (prim__stopTextInput ptr)

||| Query a live window on the main thread. False means input is inactive.
export
textInputActive : Window -> IO Bool
textInputActive (MkWindow ptr _) = (/= 0) <$> primIO (prim__textInputActive ptr)

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
      13 => pure WindowDisplayScaleChanged
      14 => pure WindowFocusGained
      15 => pure WindowFocusLost
      16 => pure WindowMouseEnter
      17 => pure WindowMouseLeave
      18 => pure WindowMinimized
      19 => pure WindowMaximized
      20 => pure WindowRestored
      21 => pure WindowShown
      22 => pure WindowHidden
      23 => pure WindowExposed
      24 => pure WindowMoved
      25 => pure WindowEnterFullscreen
      26 => pure WindowLeaveFullscreen
      27 => pure GamepadAdded
      28 => pure GamepadRemoved
      29 => pure GamepadRemapped
      30 => pure GamepadAxisMotion
      31 => pure GamepadButtonDown
      32 => pure GamepadButtonUp
      33 => pure DropFile
      34 => pure DropText
      35 => pure DropBegin
      36 => pure DropComplete
      37 => pure DropPosition
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

windowPositionData : AnyPtr -> IO WindowPositionData
windowPositionData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  x <- primIO (prim__eventWindowData1 ptr)
  y <- primIO (prim__eventWindowData2 ptr)
  pure (MkWindowPositionData window x y)

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

gamepadAxisData : AnyPtr -> IO GamepadAxisData
gamepadAxisData ptr = do
  identifier <- MkGamepadID <$> primIO (prim__eventGamepad ptr)
  axis <- MkGamepadAxis <$> primIO (prim__eventGamepadControl ptr)
  value <- primIO (prim__eventGamepadValue ptr)
  pure (MkGamepadAxisData identifier axis value)

gamepadButtonData : AnyPtr -> KeyAction -> IO GamepadButtonData
gamepadButtonData ptr action = do
  identifier <- MkGamepadID <$> primIO (prim__eventGamepad ptr)
  button <- MkGamepadButton <$> primIO (prim__eventGamepadControl ptr)
  pure (MkGamepadButtonData identifier button action)

dropData : AnyPtr -> IO DropData
dropData ptr = do
  window <- MkWindowID <$> primIO (prim__eventWindow ptr)
  x <- primIO (prim__eventDropX ptr)
  y <- primIO (prim__eventDropY ptr)
  source <- primIO (prim__eventDropSource ptr)
  text <- primIO (prim__eventDropData ptr)
  pure (MkDropData window x y source text)

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
    13 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowDisplayScaleChangedEvent timestamp window)
    14 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowFocusGainedEvent timestamp window)
    15 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowFocusLostEvent timestamp window)
    16 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowMouseEnterEvent timestamp window)
    17 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowMouseLeaveEvent timestamp window)
    18 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowMinimizedEvent timestamp window)
    19 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowMaximizedEvent timestamp window)
    20 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowRestoredEvent timestamp window)
    21 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowShownEvent timestamp window)
    22 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowHiddenEvent timestamp window)
    23 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowExposedEvent timestamp window)
    24 => WindowMovedEvent timestamp <$> windowPositionData ptr
    25 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowEnterFullscreenEvent timestamp window)
    26 => do
      window <- MkWindowID <$> primIO (prim__eventWindow ptr)
      pure (WindowLeaveFullscreenEvent timestamp window)
    27 => GamepadAddedEvent timestamp . MkGamepadID <$> primIO (prim__eventGamepad ptr)
    28 => GamepadRemovedEvent timestamp . MkGamepadID <$> primIO (prim__eventGamepad ptr)
    29 => GamepadRemappedEvent timestamp . MkGamepadID <$> primIO (prim__eventGamepad ptr)
    30 => GamepadAxisEvent timestamp <$> gamepadAxisData ptr
    31 => GamepadButtonEvent timestamp <$> gamepadButtonData ptr Pressed
    32 => GamepadButtonEvent timestamp <$> gamepadButtonData ptr Released
    33 => DropFileEvent timestamp <$> dropData ptr
    34 => DropTextEvent timestamp <$> dropData ptr
    35 => DropBeginEvent timestamp . MkWindowID <$> primIO (prim__eventWindow ptr)
    36 => DropCompleteEvent timestamp . MkWindowID <$> primIO (prim__eventWindow ptr)
    37 => DropPositionEvent timestamp <$> dropData ptr
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

||| PCM sample representation and byte order. Channels are interleaved.
public export
data AudioFormat = AudioU8 | AudioS8 | AudioS16LE | AudioS16BE
                 | AudioS32LE | AudioS32BE | AudioF32LE | AudioF32BE

formatCode : AudioFormat -> Bits32
formatCode AudioU8 = 0x0008
formatCode AudioS8 = 0x8008
formatCode AudioS16LE = 0x8010
formatCode AudioS16BE = 0x9010
formatCode AudioS32LE = 0x8020
formatCode AudioS32BE = 0x9020
formatCode AudioF32LE = 0x8120
formatCode AudioF32BE = 0x9120

formatFromCode : Bits32 -> Maybe AudioFormat
formatFromCode 0x0008 = Just AudioU8
formatFromCode 0x8008 = Just AudioS8
formatFromCode 0x8010 = Just AudioS16LE
formatFromCode 0x9010 = Just AudioS16BE
formatFromCode 0x8020 = Just AudioS32LE
formatFromCode 0x9020 = Just AudioS32BE
formatFromCode 0x8120 = Just AudioF32LE
formatFromCode 0x9120 = Just AudioF32BE
formatFromCode _ = Nothing

public export
Eq AudioFormat where
  x == y = formatCode x == formatCode y

||| Input format, channel count (1..8), and sample frames per second (positive).
||| This is the application's format. SDL converts to the device format as needed.
public export
record AudioSpec where
  constructor MkAudioSpec
  format : AudioFormat
  channels : Int32
  frequency : Int32

public export
Eq AudioSpec where
  MkAudioSpec f c r == MkAudioSpec g d s = f == g && c == d && r == s

||| Owns one stream and its logical playback device. Destroy before SDL quit.
||| No callback enters Idris from an audio thread. Do not rebind or reformat it through raw SDL calls.
export
data PlaybackStream = MkPlaybackStream AnyPtr AudioSpec

||| Owned decoded WAV samples. Free exactly once. Queue calls copy samples before returning.
export
data WAV = MkWAV NativeWAV AudioSpec Bits32

||| Copied application-side format. Does not query the physical device.
export
playbackSpec : PlaybackStream -> AudioSpec
playbackSpec (MkPlaybackStream _ spec) = spec

||| Copied format and length remain valid after WAV cleanup.
export
wavSpec : WAV -> AudioSpec
wavSpec (MkWAV _ spec _) = spec

export
wavByteLength : WAV -> Bits32
wavByteLength (MkWAV _ _ length) = length

||| Open default playback, initially paused. Initialize SDL's audio subsystem first.
||| Each call owns a separate logical device. Destroying the stream closes that device too.
export
openPlaybackStream : AudioSpec -> IO (Either String PlaybackStream)
openPlaybackStream spec@(MkAudioSpec format channels frequency) = do
  ptr <- primIO (prim__openPlayback (formatCode format) channels frequency)
  0 <- primIO (prim__isNull ptr) | _ => Left <$> getError
  pure (Right (MkPlaybackStream ptr spec))

||| Drop queued audio and close the owned device. Do not use the stream afterward.
||| Serialize destruction with all users. Destroy before SDL quit.
export
destroyPlaybackStream : PlaybackStream -> IO ()
destroyPlaybackStream (MkPlaybackStream ptr _) = primIO (prim__destroyPlayback ptr)

||| Queue copied PCM bytes without starting playback. Offset and count must contain aligned whole frames.
||| The count must fit a positive C int or be zero. Bounds are checked before SDL copies.
||| Do not modify the source during this call. It can be reused afterward. Read getError after False.
export
queueAudio : PlaybackStream -> Buffer -> Bits32 -> Bits32 -> IO Bool
queueAudio (MkPlaybackStream ptr _) buffer offset length = do
  size <- rawSize buffer
  (/= 0) <$> primIO (prim__queueAudio ptr buffer (cast size) offset length)

||| Pause the owned device, retaining queued audio. Read getError after False.
export
pausePlayback : PlaybackStream -> IO Bool
pausePlayback (MkPlaybackStream ptr _) = (/= 0) <$> primIO (prim__pausePlayback ptr)

||| Resume the owned device. An empty stream stays silent until data is queued.
export
resumePlayback : PlaybackStream -> IO Bool
resumePlayback (MkPlaybackStream ptr _) = (/= 0) <$> primIO (prim__resumePlayback ptr)

||| State, not a success indicator. Requires a live stream. Does not mean samples are queued or audible.
export
isPlaybackPaused : PlaybackStream -> IO Bool
isPlaybackPaused (MkPlaybackStream ptr _) = (/= 0) <$> primIO (prim__playbackPaused ptr)

||| Discard pending stream data without pausing the device. Already submitted device audio cannot be recalled.
export
clearPlayback : PlaybackStream -> IO Bool
clearPlayback (MkPlaybackStream ptr _) = (/= 0) <$> primIO (prim__clearPlayback ptr)

||| End the current input sequence so SDL can emit buffered conversion data. This does not discard samples.
||| More input is allowed later, but flushing between continuous chunks can introduce gaps.
export
flushPlayback : PlaybackStream -> IO Bool
flushPlayback (MkPlaybackStream ptr _) = (/= 0) <$> primIO (prim__flushPlayback ptr)

||| Pause, then discard queued samples. This is not an atomic operation or a fade.
||| On failure, stop immediately and leave the partial state. Read getError after False.
export
stopPlayback : PlaybackStream -> IO Bool
stopPlayback stream = do
  True <- pausePlayback stream | False => pure False
  clearPlayback stream

||| Input bytes still queued, clamped by SDL at 2147483647. Not a playback-completion or audible-silence test.
export
getPlaybackQueued : PlaybackStream -> IO (Either String Bits32)
getPlaybackQueued (MkPlaybackStream ptr _) = do
  count <- primIO (prim__playbackQueued ptr)
  if count < 0 then Left <$> getError else pure (Right (cast count))

||| Set stream volume: zero is silent, one is unchanged, above one amplifies and can clip.
||| Requires finite, nonnegative gain representable as C float. Read getError after False.
export
setPlaybackGain : PlaybackStream -> Double -> IO Bool
setPlaybackGain (MkPlaybackStream ptr _) gain = (/= 0) <$> primIO (prim__setPlaybackGain ptr gain)

||| Copied SDL float widened to Double. Changes apply during consumption, not when data is queued.
export
getPlaybackGain : PlaybackStream -> IO (Either String Double)
getPlaybackGain (MkPlaybackStream ptr _) = do
  gain <- primIO (prim__getPlaybackGain ptr)
  if gain == -1.0 then Left <$> getError else pure (Right gain)

||| Load and decode an entire WAV into native memory. No MP3/OGG decoding or incremental file streaming.
||| Paths are UTF-8 C strings: embedded NUL ends the path. Allocation and format errors return Left.
export
loadWAV : String -> IO (Either String WAV)
loadWAV path = do
  ptr <- primIO (prim__loadWAV path)
  0 <- primIO (prim__wavIsNull ptr) | _ => Left <$> getError
  let Just format = formatFromCode (getField ptr "format") | Nothing => do
    primIO (prim__freeWAV ptr)
    pure (Left "Unsupported WAV audio format")
  pure (Right (MkWAV ptr (MkAudioSpec format (getField ptr "channels") (getField ptr "frequency"))
                    (getField ptr "length")))

export
freeWAV : WAV -> IO ()
freeWAV (MkWAV ptr _ _) = primIO (prim__freeWAV ptr)

||| Copy a range of WAV samples into a matching stream. Does not start playback.
||| Offset/count are bytes aligned to whole sample frames. The WAV must remain alive through this call.
export
queueWAVRange : PlaybackStream -> WAV -> Bits32 -> Bits32 -> IO Bool
queueWAVRange (MkPlaybackStream stream _) (MkWAV wav _ _) offset length =
  (/= 0) <$> primIO (prim__queueWAV stream wav offset length)

||| Queue the whole WAV. A single queue call is limited to 2147483647 bytes.
export
queueWAV : PlaybackStream -> WAV -> IO Bool
queueWAV stream wav = queueWAVRange stream wav 0 (wavByteLength wav)

||| Restart one WAV: pause/clear, queue, flush, resume. The WAV format must match the stream input.
||| This replaces pending playback, not other streams. It is not atomic and does not loop.
||| Failure stops the sequence and leaves partial state. Read getError after False.
export
playWAV : PlaybackStream -> WAV -> IO Bool
playWAV stream wav = do
  True <- stopPlayback stream | False => pure False
  True <- queueWAV stream wav | False => pure False
  True <- flushPlayback stream | False => pure False
  resumePlayback stream

||| Owned open reference. Close exactly once, including after device removal.
export
data Gamepad = MkGamepad AnyPtr

copyGamepadIDs : NativeGamepads -> Bits32 -> Nat -> IO (List GamepadID)
copyGamepadIDs list index Z = pure []
copyGamepadIDs list index (S count) = do
  identifier <- MkGamepadID <$> primIO (prim__gamepadsAt list index)
  rest <- copyGamepadIDs list (index + 1) count
  pure (identifier :: rest)

||| Snapshot of connected gamepad IDs, not open handles. Initialize gamepad first.
export
listGamepads : IO (Either String (List GamepadID))
listGamepads = do
  ptr <- primIO prim__gamepadsNew
  0 <- primIO (prim__gamepadsIsNull ptr) | _ => Left <$> getError
  let count : Int32 = getField ptr "count"
  identifiers <- copyGamepadIDs ptr 0 (cast count)
  primIO (prim__gamepadsFree ptr)
  pure (Right identifiers)

export
openGamepad : GamepadID -> IO (Either String Gamepad)
openGamepad (MkGamepadID identifier) = owned MkGamepad (prim__openGamepad identifier)

export
closeGamepad : Gamepad -> IO ()
closeGamepad (MkGamepad ptr) = primIO (prim__closeGamepad ptr)

export
getGamepadID : Gamepad -> IO (Either String GamepadID)
getGamepadID (MkGamepad ptr) = do
  identifier <- primIO (prim__gamepadID ptr)
  if identifier == 0 then Left <$> getError else pure (Right (MkGamepadID identifier))

||| Copied name. It remains valid after disconnect or close.
export
getGamepadName : Gamepad -> IO (Either String String)
getGamepadName (MkGamepad ptr) = do
  text <- primIO (prim__gamepadName ptr)
  0 <- primIO (prim__isNull text) | _ => Left <$> getError
  Right <$> primIO (prim__copyString text)

export
gamepadConnected : Gamepad -> IO Bool
gamepadConnected (MkGamepad ptr) = (/= 0) <$> primIO (prim__gamepadConnected ptr)

||| Signed stick range -32768..32767; triggers 0..32767. SDL returns zero on failure.
||| Poll events or call updateGamepads before querying. No dead zone is applied.
export
getGamepadAxis : Gamepad -> GamepadAxis -> IO Int16
getGamepadAxis (MkGamepad ptr) (MkGamepadAxis axis) = primIO (prim__gamepadAxis ptr (cast axis))

||| Button state, not a success indicator. SDL returns False for unavailable controls.
export
getGamepadButton : Gamepad -> GamepadButton -> IO Bool
getGamepadButton (MkGamepad ptr) (MkGamepadButton button) = (/= 0) <$> primIO (prim__gamepadButton ptr (cast button))

||| Intensities 0..65535, duration in milliseconds. Zero intensities stop rumble.
export
rumbleGamepad : Gamepad -> Bits16 -> Bits16 -> Bits32 -> IO Bool
rumbleGamepad (MkGamepad ptr) low high duration = (/= 0) <$> primIO (prim__gamepadRumble ptr low high duration)

||| Explicit update for applications not pumping events. SDL permits calls from any thread.
export
updateGamepads : IO ()
updateGamepads = primIO prim__updateGamepads

||| Main-thread request. Flushes pending mouse motion for this window.
export
setWindowRelativeMouseMode : Window -> Bool -> IO Bool
setWindowRelativeMouseMode (MkWindow ptr _) enabled =
  (/= 0) <$> primIO (prim__relativeMouse ptr (if enabled then 1 else 0))

export
getWindowRelativeMouseMode : Window -> IO Bool
getWindowRelativeMouseMode (MkWindow ptr _) = (/= 0) <$> primIO (prim__relativeMouseEnabled ptr)

||| Capture outside-window input without cursor confinement. Main thread, backend-dependent.
export
captureMouse : Bool -> IO Bool
captureMouse enabled = (/= 0) <$> primIO (prim__captureMouse (if enabled then 1 else 0))

public export
data SystemCursor = DefaultCursor | TextCursor | WaitCursor | CrosshairCursor | ProgressCursor
                  | NWSEResizeCursor | NESWResizeCursor | EWResizeCursor | NSResizeCursor
                  | MoveCursor | NotAllowedCursor | PointerCursor

systemCursorCode : SystemCursor -> Int32
systemCursorCode DefaultCursor = 0
systemCursorCode TextCursor = 1
systemCursorCode WaitCursor = 2
systemCursorCode CrosshairCursor = 3
systemCursorCode ProgressCursor = 4
systemCursorCode NWSEResizeCursor = 5
systemCursorCode NESWResizeCursor = 6
systemCursorCode EWResizeCursor = 7
systemCursorCode NSResizeCursor = 8
systemCursorCode MoveCursor = 9
systemCursorCode NotAllowedCursor = 10
systemCursorCode PointerCursor = 11

||| Owned cursor. Create, select, and destroy on the main thread before quit.
export
data Cursor = MkCursor AnyPtr

export
createSystemCursor : SystemCursor -> IO (Either String Cursor)
createSystemCursor shape = owned MkCursor (prim__createSystemCursor (systemCursorCode shape))

export
destroyCursor : Cursor -> IO ()
destroyCursor (MkCursor ptr) = primIO (prim__destroyCursor ptr)

||| Nothing selects SDL's default cursor, not SDL_SetCursor(NULL)'s redraw behavior.
export
setCursor : Maybe Cursor -> IO Bool
setCursor Nothing = (/= 0) <$> primIO prim__defaultCursor
setCursor (Just (MkCursor ptr)) = (/= 0) <$> primIO (prim__setCursor ptr)

export
showCursor : IO Bool
showCursor = (/= 0) <$> primIO prim__showCursor

export
hideCursor : IO Bool
hideCursor = (/= 0) <$> primIO prim__hideCursor

export
cursorVisible : IO Bool
cursorVisible = (/= 0) <$> primIO prim__cursorVisible

||| Main thread. SDL copies UTF-8 text. Embedded NUL ends the text.
export
setClipboardText : String -> IO Bool
setClipboardText text = (/= 0) <$> primIO (prim__clipboardSet text)

||| Copies and frees SDL's result. Empty text is valid. Clears old SDL errors first.
export
getClipboardText : IO (Either String String)
getClipboardText = do
  ptr <- primIO prim__clipboardGet
  0 <- primIO (prim__isNull ptr) | _ => Left <$> getError
  text <- primIO (prim__copyString ptr)
  primIO (prim__freeSDL ptr)
  pure (Right text)

export
hasClipboardText : IO Bool
hasClipboardText = (/= 0) <$> primIO prim__clipboardHasText

||| Owned file or dynamic-memory stream. Serialize all access, including close.
export
data IOStream = MkIOStream AnyPtr

public export
data FileIOMode = ReadFile | WriteFile | AppendFile | ReadWriteFile | RewriteFile | AppendReadFile

fileIOMode : FileIOMode -> String
fileIOMode ReadFile = "rb"
fileIOMode WriteFile = "wb"
fileIOMode AppendFile = "ab"
fileIOMode ReadWriteFile = "r+b"
fileIOMode RewriteFile = "w+b"
fileIOMode AppendReadFile = "a+b"

||| WriteFile and RewriteFile truncate existing files. Paths are UTF-8 C strings.
export
openFileIO : String -> FileIOMode -> IO (Either String IOStream)
openFileIO path mode = owned MkIOStream (prim__ioFromFile path (fileIOMode mode))

||| Empty growable memory, owned by SDL until close. No borrowed managed pointers.
export
newMemoryIO : IO (Either String IOStream)
newMemoryIO = owned MkIOStream prim__ioDynamicMemory

||| The handle is invalid after return, even when close reports failure. Never retry close.
export
closeIO : IOStream -> IO Bool
closeIO (MkIOStream ptr) = (/= 0) <$> primIO (prim__ioClose ptr)

export
flushIO : IOStream -> IO Bool
flushIO (MkIOStream ptr) = (/= 0) <$> primIO (prim__ioFlush ptr)

ioPosition : PrimIO Int64 -> IO (Either String Bits64)
ioPosition action = do
  value <- primIO action
  if value < 0 then Left <$> getError else pure (Right (cast value))

export
getIOSize : IOStream -> IO (Either String Bits64)
getIOSize (MkIOStream ptr) = ioPosition (prim__ioSize ptr)

export
tellIO : IOStream -> IO (Either String Bits64)
tellIO (MkIOStream ptr) = ioPosition (prim__ioTell ptr)

public export
data IOOrigin = FromStart | FromCurrent | FromEnd

ioOrigin : IOOrigin -> Int32
ioOrigin FromStart = 0
ioOrigin FromCurrent = 1
ioOrigin FromEnd = 2

export
seekIO : IOStream -> Int64 -> IOOrigin -> IO (Either String Bits64)
seekIO (MkIOStream ptr) offset origin = ioPosition (prim__ioSeek ptr offset (ioOrigin origin))

public export
data IOStatus = IOReady | IOFailure | IOEndOfFile | IONotReady | IOReadOnly | IOWriteOnly | OtherIOStatus Int32

ioStatus : Int32 -> IOStatus
ioStatus 0 = IOReady
ioStatus 1 = IOFailure
ioStatus 2 = IOEndOfFile
ioStatus 3 = IONotReady
ioStatus 4 = IOReadOnly
ioStatus 5 = IOWriteOnly
ioStatus value = OtherIOStatus value

||| Preserves partial progress. A Right result alone does not mean a complete transfer.
public export
record IOTransfer where
  constructor MkIOTransfer
  transferred : Bits64
  status : IOStatus
  error : Maybe String

ioTransfer : AnyPtr -> Bits64 -> PrimIO Int64 -> IO (Either String IOTransfer)
ioTransfer ptr requested action = do
  count <- primIO action
  if count < 0 then Left <$> getError else do
    code <- primIO (prim__ioStatus ptr)
    err <- if requested /= 0 && (code == 1 || code == 4 || code == 5)
             then Just <$> getError else pure Nothing
    pure (Right (MkIOTransfer (cast count) (ioStatus code) err))

||| Checked destination byte range. Partial reads and EOF are returned with status.
export
readIO : IOStream -> Buffer -> Bits64 -> Bits64 -> IO (Either String IOTransfer)
readIO (MkIOStream ptr) buffer offset count = do
  capacity <- rawSize buffer
  ioTransfer ptr count (prim__ioRead ptr buffer (cast capacity) offset count)

||| Checked source byte range. Do not change the buffer during the call.
export
writeIO : IOStream -> Buffer -> Bits64 -> Bits64 -> IO (Either String IOTransfer)
writeIO (MkIOStream ptr) buffer offset count = do
  capacity <- rawSize buffer
  ioTransfer ptr count (prim__ioWrite ptr buffer (cast capacity) offset count)

||| Copy the complete buffer into owned growable memory and rewind. The source can then be reused.
export
openMemoryIO : Buffer -> IO (Either String IOStream)
openMemoryIO buffer = do
  Right stream <- newMemoryIO | Left err => pure (Left err)
  capacity <- rawSize buffer
  result <- writeIO stream buffer 0 (cast capacity)
  case result of
    Left err => do
      _ <- closeIO stream
      pure (Left err)
    Right transfer => case transfer.transferred == cast capacity of
      False => do
        let err = maybe "Cannot copy the complete source buffer" id transfer.error
        _ <- closeIO stream
        pure (Left err)
      True => do
        Right _ <- seekIO stream 0 FromStart | Left err => do
          _ <- closeIO stream
          pure (Left err)
        pure (Right stream)
