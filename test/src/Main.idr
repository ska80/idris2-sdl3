module Main

import SDL3
import System
import TypeSafety
import EventTests

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

textInputControls : Window -> IO (Either String ())
textInputControls window = do
  False <- textInputActive window | True => pure (Left "Text input was active by default")
  True <- startTextInput window | False => Left <$> getError
  active <- textInputActive window
  -- Stop even if the state query did not return the expected result.
  True <- stopTextInput window | False => Left <$> getError
  inactive <- not <$> textInputActive window
  require "Text input controls did not change the window state" (active && inactive)

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
      render renderer
    freeEventBuffer buffer
    pure result
  destroyRenderer renderer
  pure result

smoke : IO (Either String ())
smoke = do
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
