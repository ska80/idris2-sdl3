module TypeSafety

import SDL3
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

failing "Name SDL3.MkTexture is private"
  forgeTexture : AnyPtr -> Texture TargetAccess
  forgeTexture = MkTexture

failing "Name SDL3.MkWindow is private"
  forgeWindow : AnyPtr -> Window
  forgeWindow = MkWindow
