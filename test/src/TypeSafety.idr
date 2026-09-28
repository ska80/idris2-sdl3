module TypeSafety

import SDL3
import SDL3.Scoped
import SDL3.Raw
import Data.Buffer

failing "Mismatch between"
  wrongHandle : Window -> IO Bool
  wrongHandle window = clear window

failing "Mismatch between"
  wrongFlags : IO Bool
  wrongFlags = SDL3.init resizable

failing "Mismatch between"
  wrongWindowFlags : IO (Either String Window)
  wrongWindowFlags = createWindow "wrong flags" 64 64 video

failing "Mismatch between"
  wrongKey : Scancode -> Keycode
  wrongKey scan = scan

failing "Mismatch between"
  wrongWindowID : WindowID -> IO ()
  wrongWindowID identifier = destroyWindow identifier

failing "Mismatch between"
  wrongMouseID : MouseID -> WindowID
  wrongMouseID identifier = identifier

failing "Mismatch between"
  wrongMouseButton : MouseButtons -> Bool
  wrongMouseButton buttons = buttonHeld buttons buttons

failing "Mismatch between"
  wrongWheelDirection : MouseAction -> WheelDirection
  wrongWheelDirection action = action

failing "Mismatch between"
  wrongTextWindow : Renderer -> IO Bool
  wrongTextWindow renderer = startTextInput renderer

failing "Mismatch between"
  wrongTextData : TextEditingData -> TextInputData
  wrongTextData composition = composition

failing "Mismatch between"
  wrongTextArea : Window -> TextEditingData -> IO Bool
  wrongTextArea window composition = setTextInputArea window (Just composition)

failing "Mismatch between"
  wrongCompositionWindow : Renderer -> IO Bool
  wrongCompositionWindow renderer = clearComposition renderer

failing "Mismatch between"
  wrongTexture : Renderer -> Window -> IO Bool
  wrongTexture renderer window = renderTexture renderer window Nothing

failing "Mismatch between"
  wrongTextureAccess : Renderer -> Texture StreamingAccess -> IO Bool
  wrongTextureAccess renderer texture = setRenderTarget renderer (Just texture)

failing "Mismatch between"
  staticRenderTarget : Renderer -> Texture StaticAccess -> IO Bool
  staticRenderTarget renderer texture = setRenderTarget renderer (Just texture)

failing "Mismatch between"
  wrongSurface : Renderer -> Window -> IO (Either String (Texture StaticAccess))
  wrongSurface renderer window = createTextureFromSurface renderer window

failing "Name SDL3.MkSurface is private"
  forgeSurface : AnyPtr -> Surface
  forgeSurface = MkSurface

failing "Mismatch between"
  wrongScaleMode : Texture StaticAccess -> IO Bool
  wrongScaleMode texture = setTextureScaleMode texture AlphaBlend

failing "Mismatch between"
  wrongBlendHandle : Renderer -> IO Bool
  wrongBlendHandle renderer = setTextureBlendMode renderer AlphaBlend

failing "Mismatch between"
  wrongViewportRect : Renderer -> FRect -> IO Bool
  wrongViewportRect renderer rect = setRenderViewport renderer (Just rect)

failing "Mismatch between"
  wrongClipHandle : Window -> IO Bool
  wrongClipHandle window = setRenderClipRect window Nothing

failing "Mismatch between"
  wrongDrawBlendHandle : Texture StaticAccess -> IO Bool
  wrongDrawBlendHandle texture = setDrawBlendMode texture AlphaBlend

failing "Mismatch between"
  wrongPresentation : Renderer -> IO Bool
  wrongPresentation renderer = setRenderLogicalPresentation renderer 320 240 LinearScale

failing "Mismatch between"
  wrongScaleHandle : Texture StaticAccess -> IO Bool
  wrongScaleHandle texture = setRenderScale texture 2 2

failing "Mismatch between"
  wrongPointSpace : Renderer -> CoordinateBuffer -> Point RenderSpace -> IO (Either String (Point RenderSpace))
  wrongPointSpace renderer buffer point = renderCoordinatesFromWindow renderer buffer point

failing "Mismatch between"
  wrongCoordinateBuffer : Renderer -> EventBuffer -> IO (Either String (Point RenderSpace))
  wrongCoordinateBuffer renderer buffer = renderCoordinatesFromWindow renderer buffer (MkPoint 0 0)

failing "Name SDL3.MkCoordinateBuffer is private"
  forgeCoordinateBuffer : AnyPtr -> CoordinateBuffer
  forgeCoordinateBuffer = MkCoordinateBuffer

failing "Mismatch between"
  wrongUploadAccess : Texture StaticAccess -> Buffer -> IO Bool
  wrongUploadAccess texture buffer = updateTextureRGBA texture buffer 8

failing "Mismatch between"
  wrongUploadBuffer : Texture StreamingAccess -> CoordinateBuffer -> IO Bool
  wrongUploadBuffer texture buffer = updateTextureRGBA texture buffer 8

failing "Mismatch between"
  wrongPartialAccess : Texture TargetAccess -> Buffer -> IO Bool
  wrongPartialAccess texture buffer = updateTextureRegionRGBA texture (MkRect 0 0 1 1) buffer 4

failing "Mismatch between"
  wrongPartialRect : Texture StreamingAccess -> Buffer -> IO Bool
  wrongPartialRect texture buffer = updateTextureRegionRGBA texture (MkFRect 0 0 1 1) buffer 4

failing "Mismatch between"
  wrongNanoDelayWidth : Bits32 -> IO ()
  wrongNanoDelayWidth = delayNS

failing "Mismatch between"
  signedPreciseDelay : Int64 -> IO ()
  signedPreciseDelay = delayPrecise

failing "Mismatch between"
  wrongVSyncMode : Renderer -> IO Bool
  wrongVSyncMode renderer = setRenderVSync renderer AlphaBlend

failing "Mismatch between"
  wrongVSyncHandle : Window -> IO (Either String VSyncMode)
  wrongVSyncHandle window = getRenderVSync window

failing "Mismatch between"
  wrongWaitBuffer : CoordinateBuffer -> IO (Either String Event)
  wrongWaitBuffer buffer = waitEventData buffer

failing "Mismatch between"
  signedWaitTimeout : EventBuffer -> Int32 -> IO (Either String (Maybe Event))
  signedWaitTimeout buffer timeout = waitEventDataTimeout buffer timeout

failing "Mismatch between"
  wrongScopedCallback : IO (Either String WindowID)
  wrongScopedCallback = withEventBuffer getWindowID

failing "Mismatch between"
  wrongScopedResult : IO (Either String Bits64)
  wrongScopedResult = withEventBuffer (\_ => ticks)

failing "Mismatch between"
  wrongScopedTarget : Renderer -> Texture StaticAccess -> IO (Either String ())
  wrongScopedTarget renderer texture = withRenderTarget renderer (Just texture) (pure (Right ()))

failing "Mismatch between"
  wrongScopedTextureAccess : Renderer -> IO (Either String ())
  wrongScopedTextureAccess renderer = withStreamingTexture renderer 1 1 $ \texture => do
    _ <- setRenderTarget renderer (Just texture)
    pure (Right ())

failing "Mismatch between"
  wrongTargetTextureCallback : Renderer -> Buffer -> IO (Either String ())
  wrongTargetTextureCallback renderer buffer = withTargetTexture renderer 8 8 $ \texture => do
    _ <- updateTextureRGBA texture buffer 32
    pure (Right ())

failing "Mismatch between"
  wrongTextureFlip : Renderer -> Texture StaticAccess -> IO Bool
  wrongTextureFlip renderer texture = renderTextureRotated renderer texture Nothing Nothing 0 Nothing AlphaBlend

failing "Mismatch between"
  wrongRotationCenter : Renderer -> Texture StaticAccess -> Point RenderSpace -> IO Bool
  wrongRotationCenter renderer texture center = renderTextureRotated renderer texture Nothing Nothing 0 (Just center) NoFlip

failing "Mismatch between"
  windowPointDrawing : Renderer -> Point WindowSpace -> IO Bool
  windowPointDrawing renderer point = drawPoint renderer point

failing "Mismatch between"
  windowLineDrawing : Renderer -> Point RenderSpace -> Point WindowSpace -> IO Bool
  windowLineDrawing renderer start end = drawLine renderer start end

failing "Mismatch between"
  windowPointBatch : PointBuffer -> Point WindowSpace -> IO Bool
  windowPointBatch buffer point = setPoint buffer 0 point

failing "Mismatch between"
  wrongPointBuffer : Renderer -> CoordinateBuffer -> IO Bool
  wrongPointBuffer renderer buffer = drawPoints renderer buffer 1

failing "Mismatch between"
  signedPointCount : Renderer -> PointBuffer -> Int32 -> IO Bool
  signedPointCount renderer buffer count = drawLines renderer buffer count

failing "Mismatch between"
  integerBatchRectangle : RectBuffer -> Rect -> IO Bool
  integerBatchRectangle buffer rect = setRect buffer 0 rect

failing "Mismatch between"
  pointArrayRectangles : Renderer -> PointBuffer -> IO Bool
  pointArrayRectangles renderer buffer = drawRects renderer buffer 1

failing "Mismatch between"
  rectangleArrayPoints : Renderer -> RectBuffer -> IO Bool
  rectangleArrayPoints renderer buffer = drawPoints renderer buffer 1

failing "Mismatch between"
  signedRectCount : Renderer -> RectBuffer -> Int32 -> IO Bool
  signedRectCount renderer buffer count = fillRects renderer buffer count

failing "Mismatch between"
  integerOutline : Renderer -> Rect -> IO Bool
  integerOutline renderer rect = drawRect renderer (Just rect)

failing "Mismatch between"
  mixedSizeUnits : Bits64 -> PixelSizeData -> Event
  mixedSizeUnits timestamp dimensions = WindowResizedEvent timestamp dimensions

failing "Mismatch between"
  mixedPixelUnits : Bits64 -> WindowSizeData -> Event
  mixedPixelUnits timestamp dimensions = WindowPixelSizeChangedEvent timestamp dimensions

failing "Mismatch between"
  windowAsFullscreenIdentifier : Bits64 -> Window -> Event
  windowAsFullscreenIdentifier timestamp window = WindowEnterFullscreenEvent timestamp window

failing "Mismatch between"
  sizeAsFullscreenExitIdentifier : Bits64 -> PixelSizeData -> Event
  sizeAsFullscreenExitIdentifier timestamp size = WindowLeaveFullscreenEvent timestamp size

failing "Mismatch between"
  sizeAsWindowPosition : Bits64 -> WindowSizeData -> Event
  sizeAsWindowPosition timestamp size = WindowMovedEvent timestamp size

failing "Mismatch between"
  motionAsWindowPosition : Bits64 -> MouseMotionData -> Event
  motionAsWindowPosition timestamp motion = WindowMovedEvent timestamp motion

failing "Mismatch between"
  windowPositionAsLocalPoint : WindowPositionData -> Point WindowSpace
  windowPositionAsLocalPoint position = position

failing "Mismatch between"
  ownedWindowAsPositionIdentifier : Window -> WindowPositionData
  ownedWindowAsPositionIdentifier window = MkWindowPositionData window 0 0

failing "Mismatch between"
  windowAsShownIdentifier : Bits64 -> Window -> Event
  windowAsShownIdentifier timestamp window = WindowShownEvent timestamp window

failing "Mismatch between"
  flagsAsHiddenIdentifier : Bits64 -> WindowFlags -> Event
  flagsAsHiddenIdentifier timestamp flags = WindowHiddenEvent timestamp flags

failing "Mismatch between"
  rectAsExposedIdentifier : Bits64 -> Rect -> Event
  rectAsExposedIdentifier timestamp rect = WindowExposedEvent timestamp rect

failing "Mismatch between"
  windowAsMinimizedIdentifier : Bits64 -> Window -> Event
  windowAsMinimizedIdentifier timestamp window = WindowMinimizedEvent timestamp window

failing "Mismatch between"
  sizeAsMaximizedIdentifier : Bits64 -> PixelSizeData -> Event
  sizeAsMaximizedIdentifier timestamp size = WindowMaximizedEvent timestamp size

failing "Mismatch between"
  rendererAsRestoredIdentifier : Bits64 -> Renderer -> Event
  rendererAsRestoredIdentifier timestamp renderer = WindowRestoredEvent timestamp renderer

failing "Mismatch between"
  windowAsMouseEntryIdentifier : Bits64 -> Window -> Event
  windowAsMouseEntryIdentifier timestamp window = WindowMouseEnterEvent timestamp window

failing "Mismatch between"
  motionAsMouseDepartureIdentifier : Bits64 -> MouseMotionData -> Event
  motionAsMouseDepartureIdentifier timestamp motion = WindowMouseLeaveEvent timestamp motion

failing "Mismatch between"
  windowAsFocusIdentifier : Bits64 -> Window -> Event
  windowAsFocusIdentifier timestamp window = WindowFocusGainedEvent timestamp window

failing "Mismatch between"
  keyAsFocusIdentifier : Bits64 -> Keycode -> Event
  keyAsFocusIdentifier timestamp key = WindowFocusLostEvent timestamp key

failing "Mismatch between"
  sizeAsScaleNotification : Bits64 -> PixelSizeData -> Event
  sizeAsScaleNotification timestamp dimensions = WindowDisplayScaleChangedEvent timestamp dimensions

failing "Mismatch between"
  windowAsScaleIdentifier : Bits64 -> Window -> Event
  windowAsScaleIdentifier timestamp window = WindowDisplayScaleChangedEvent timestamp window

failing "Mismatch between"
  rendererPixelDensity : Renderer -> IO (Either String Double)
  rendererPixelDensity renderer = getWindowPixelDensity renderer

failing "Mismatch between"
  textureDisplayScale : Texture access -> IO (Either String Double)
  textureDisplayScale texture = getWindowDisplayScale texture

failing "Mismatch between"
  densityAsDimensions : Window -> IO (Either String (Size PixelUnits))
  densityAsDimensions window = getWindowPixelDensity window

failing "Mismatch between"
  rendererBorderControl : Renderer -> IO Bool
  rendererBorderControl renderer = setWindowBordered renderer True

failing "Mismatch between"
  flagsAsResizableState : Window -> WindowFlags -> IO Bool
  flagsAsResizableState window flags = setWindowResizable window flags

failing "Mismatch between"
  textureBorderQuery : Texture access -> IO Bool
  textureBorderQuery texture = isWindowBordered texture

failing "Mismatch between"
  rendererResizableQuery : Renderer -> IO Bool
  rendererResizableQuery renderer = isWindowResizable renderer

failing "Mismatch between"
  rendererShowWindow : Renderer -> IO Bool
  rendererShowWindow renderer = showWindow renderer

failing "Mismatch between"
  textureHideWindow : Texture access -> IO Bool
  textureHideWindow texture = hideWindow texture

failing "Mismatch between"
  flagsHiddenQuery : WindowFlags -> IO Bool
  flagsHiddenQuery flags = isWindowHidden flags

failing "Mismatch between"
  rendererTitleQuery : Renderer -> IO String
  rendererTitleQuery renderer = getWindowTitle renderer

failing "Mismatch between"
  rendererTitleUpdate : Renderer -> IO Bool
  rendererTitleUpdate renderer = setWindowTitle renderer "wrong handle"

failing "Mismatch between"
  textureTitleQuery : Texture access -> IO String
  textureTitleQuery texture = getWindowTitle texture

failing "Mismatch between"
  pixelResize : Window -> Size PixelUnits -> IO Bool
  pixelResize window dimensions = setWindowSize window dimensions

failing "Mismatch between"
  rendererResize : Renderer -> Size WindowUnits -> IO Bool
  rendererResize renderer dimensions = setWindowSize renderer dimensions

failing "Mismatch between"
  rendererWindowSync : Renderer -> IO Bool
  rendererWindowSync renderer = syncWindow renderer

failing "Mismatch between"
  wrongSizeUnits : Window -> IO (Either String (Size PixelUnits))
  wrongSizeUnits window = getWindowSize window

failing "Mismatch between"
  wrongSizeHandle : Renderer -> IO (Either String (Size PixelUnits))
  wrongSizeHandle renderer = getWindowSizeInPixels renderer

failing "Mismatch between"
  wrongNativeSizeStorage : AnyPtr -> NativePoint -> PrimIO Int
  wrongNativeSizeStorage window storage = prim__getWindowSize window storage

failing "Mismatch between"
  wrongNativeCoordinateStorage : AnyPtr -> NativeSize -> PrimIO Int
  wrongNativeCoordinateStorage renderer storage = prim__renderCoordinatesFromWindow renderer 1 2 storage

failing "Mismatch between"
  operationAsFactor : BlendEquation
  operationAsFactor = MkBlendEquation BlendAdd OneFactor BlendAdd

failing "Mismatch between"
  factorAsOperation : BlendEquation
  factorAsOperation = MkBlendEquation OneFactor ZeroFactor OneFactor

failing "Mismatch between"
  filteringAsEquation : BlendEquation -> IO BlendMode
  filteringAsEquation alpha = composeBlendMode LinearScale alpha

failing "Mismatch between"
  textureDrawBlendQuery : Texture access -> IO (Either String BlendMode)
  textureDrawBlendQuery texture = getDrawBlendMode texture

failing "Mismatch between"
  filteringAsDrawBlend : Renderer -> ScaleMode -> IO (Either String ())
  filteringAsDrawBlend renderer mode = withDrawBlendMode renderer mode (pure (Right ()))

failing "Mismatch between"
  textureDrawBlendScope : Texture access -> IO (Either String ())
  textureDrawBlendScope texture = withDrawBlendMode texture AlphaBlend (pure (Right ()))

failing "Mismatch between"
  wrongBlendQueryHandle : Renderer -> IO (Either String BlendMode)
  wrongBlendQueryHandle renderer = getTextureBlendMode renderer

failing "Mismatch between"
  wrongScopedBlend : Texture access -> ScaleMode -> IO (Either String ())
  wrongScopedBlend texture mode = withTextureBlendMode texture mode (pure (Right ()))

failing "Mismatch between"
  wrongBlendQueryResult : Texture access -> IO (Either String Bits32)
  wrongBlendQueryResult texture = getTextureBlendMode texture

failing "Mismatch between"
  wrongScaleHandle : Renderer -> IO (Either String ScaleMode)
  wrongScaleHandle renderer = getTextureScaleMode renderer

failing "Mismatch between"
  wrongScopedScale : Texture access -> BlendMode -> IO (Either String ())
  wrongScopedScale texture mode = withTextureScaleMode texture mode (pure (Right ()))

failing "Mismatch between"
  wrongScaleResult : Texture access -> IO (Either String Bits8)
  wrongScaleResult texture = getTextureScaleMode texture

failing "Mismatch between"
  wrongAlphaHandle : Renderer -> IO (Either String Bits8)
  wrongAlphaHandle renderer = getTextureAlphaMod renderer

failing "Mismatch between"
  wideScopedAlpha : Texture access -> Bits32 -> IO (Either String ())
  wideScopedAlpha texture alpha = withTextureAlphaMod texture alpha (pure (Right ()))

failing "Mismatch between"
  wrongAlphaResult : Texture access -> IO (Either String Int32)
  wrongAlphaResult texture = getTextureAlphaMod texture

failing "Mismatch between"
  wrongTextureSizeUnits : Texture access -> IO (Either String (Size WindowUnits))
  wrongTextureSizeUnits texture = getTextureSize texture

failing "Mismatch between"
  wrongTextureSizeHandle : Renderer -> IO (Either String (Size PixelUnits))
  wrongTextureSizeHandle renderer = getTextureSize renderer

failing "Mismatch between"
  wrongNativeTexture : NativePoint -> PrimIO Int
  wrongNativeTexture point = prim__getTextureSize point

failing "Mismatch between"
  untypedNativeTexture : AnyPtr -> PrimIO ()
  untypedNativeTexture ptr = prim__destroyTexture ptr

failing "Name SDL3.MkTexture is private"
  forgeTexture : NativeTexture -> Texture TargetAccess
  forgeTexture = MkTexture

failing "Name SDL3.MkRectBuffer is private"
  forgeRectBuffer : AnyPtr -> RectBuffer
  forgeRectBuffer = MkRectBuffer

failing "Name SDL3.MkPointBuffer is private"
  forgePointBuffer : AnyPtr -> PointBuffer
  forgePointBuffer = MkPointBuffer

failing "Name SDL3.MkWindow is private"
  forgeWindow : AnyPtr -> Window
  forgeWindow = MkWindow
