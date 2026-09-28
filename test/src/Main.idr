module Main

import SDL3
import System
import TypeSafety
import EventTests
import TextureTests
import TextureSizeTests
import TextureAlphaTests
import TextureScaleTests
import TextureBlendTests
import DrawBlendTests
import BlendCompositionTests
import RenderTests
import ScalingTests
import CoordinateTests
import StreamingTests
import TimerTests
import VSyncTests
import WaitTests
import ScopedTests
import TargetScopeTests
import TargetTextureScopeTests
import RotationTests
import ShapeTests
import BatchTests
import RectBatchTests
import SizeTests
import WindowTitleTests
import WindowVisibilityTests
import WindowStyleTests
import WindowScaleTests
import FullscreenTests
import WindowFocusTests
import WindowStateControlTests

%default covering

require : String -> Bool -> IO (Either String ())
require label True = pure (Right ())
require label False = pure (Left label)

render : Renderer -> IO (Either String ())
render renderer = do
  True <- setDrawColor renderer 0 127 255 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- fillRect renderer 1.5 2.5 16 16 | False => Left <$> getError
  True <- present renderer | False => Left <$> getError
  start <- ticks
  delay 2
  end <- ticks
  require "Timer moved backward" (end >= start)

%foreign "C:idris_test_text_input_area, libidris2_sdl3_test, fixtures.h"
prim__textInputAreaMatches : Bits32 -> Int32 -> Int32 -> Int32 -> Int32 -> Int32 -> PrimIO Int

textInputControls : Window -> IO (Either String ())
textInputControls window = do
  False <- textInputActive window | True => pure (Left "Text input was active by default")
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  True <- setTextInputArea window (Just (MkTextInputArea (-10) 12 48 16 7))
    | False => Left <$> getError
  areaOK <- (== 1) <$> primIO (prim__textInputAreaMatches identifier (-10) 12 48 16 7)
  True <- startTextInput window | False => Left <$> getError
  active <- textInputActive window
  moved <- setTextInputArea window (Just (MkTextInputArea 14 (-8) 50 18 11))
  movedOK <- (== 1) <$> primIO (prim__textInputAreaMatches identifier 14 (-8) 50 18 11)
  cleared <- clearComposition window
  stillActive <- textInputActive window
  reset <- setTextInputArea window Nothing
  resetOK <- (== 1) <$> primIO (prim__textInputAreaMatches identifier 0 0 0 0 0)
  activeAfterReset <- textInputActive window
  -- Stop even if an earlier query or control did not return the expected result.
  True <- stopTextInput window | False => Left <$> getError
  inactive <- not <$> textInputActive window
  require "Text input controls or area values were incorrect"
          (areaOK && active && moved && movedOK && cleared && stillActive &&
           reset && resetOK && activeAfterReset && inactive)

resources : Window -> IO (Either String ())
resources window = do
  Right () <- textInputControls window | Left err => pure (Left err)
  Right (MkWindowID identifier) <- getWindowID window
    | Left err => pure (Left err)
  Right () <- require "Window identifier was zero" (identifier /= 0)
    | Left err => pure (Left err)
  Right renderer <- createRenderer window | Left err => pure (Left err)
  result <- do
    Right buffer <- newEventBuffer | Left err => pure (Left err)
    result <- do
      Right () <- eventTests buffer | Left err => pure (Left err)
      Right () <- waitTests | Left err => pure (Left err)
      Right () <- textureTests window renderer | Left err => pure (Left err)
      Right () <- textureSizeTests renderer | Left err => pure (Left err)
      Right () <- textureAlphaTests window renderer | Left err => pure (Left err)
      Right () <- textureScaleTests window renderer | Left err => pure (Left err)
      Right () <- textureBlendTests window renderer | Left err => pure (Left err)
      Right () <- drawBlendTests window renderer | Left err => pure (Left err)
      Right () <- blendCompositionTests renderer | Left err => pure (Left err)
      Right () <- renderTests window renderer | Left err => pure (Left err)
      Right () <- shapeTests window renderer | Left err => pure (Left err)
      Right () <- batchTests window renderer | Left err => pure (Left err)
      Right () <- rectBatchTests window renderer | Left err => pure (Left err)
      Right () <- sizeTests window renderer | Left err => pure (Left err)
      Right () <- targetScopeTests window renderer | Left err => pure (Left err)
      Right () <- targetTextureScopeTests window renderer | Left err => pure (Left err)
      Right () <- scalingTests window renderer | Left err => pure (Left err)
      Right () <- coordinateTests renderer | Left err => pure (Left err)
      Right () <- streamingTests window renderer | Left err => pure (Left err)
      Right () <- rotationTests window renderer | Left err => pure (Left err)
      Right () <- vsyncTests renderer | Left err => pure (Left err)
      render renderer
    freeEventBuffer buffer
    pure result
  destroyRenderer renderer
  pure result

smoke : IO (Either String ())
smoke = do
  Right () <- timerTests | Left err => pure (Left err)
  Right () <- scopedTests | Left err => pure (Left err)
  Right () <- windowTitleTests | Left err => pure (Left err)
  Right () <- windowVisibilityTests | Left err => pure (Left err)
  Right () <- windowStyleTests | Left err => pure (Left err)
  Right () <- windowScaleTests | Left err => pure (Left err)
  Right () <- fullscreenTests | Left err => pure (Left err)
  Right () <- windowFocusTests | Left err => pure (Left err)
  Right () <- windowStateControlTests | Left err => pure (Left err)
  Right () <- require "Init flags lost bits" (initBits (video <+> audio) == 0x30)
    | Left err => pure (Left err)
  Right () <- require "Window flags lost bits" (windowBits (hidden <+> resizable) == 0x28)
    | Left err => pure (Left err)
  Left _ <- createWindow "invalid" 0 64 neutral
    | Right window => do
        destroyWindow window
        pure (Left "Zero width was accepted")
  Right window <- createWindow "smoke" 64 64 hidden | Left err => pure (Left err)
  result <- resources window
  destroyWindow window
  pure result

main : IO ()
main = do
  ok <- SDL3.init video
  result <- the (IO (Either String ())) (if ok then smoke else Left <$> SDL3.getError)
  quit
  case result of
    Right () => putStrLn "SDL3 smoke test passed"
    Left err => do
      putStrLn err
      exitFailure
