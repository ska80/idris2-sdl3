module TypeSafety

import SDL3

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

failing "Name SDL3.MkTexture is private"
  forgeTexture : AnyPtr -> Texture TargetAccess
  forgeTexture = MkTexture

failing "Name SDL3.MkWindow is private"
  forgeWindow : AnyPtr -> Window
  forgeWindow = MkWindow
