module Main

import SDL3
import System

%default covering

require : IO Bool -> IO (Either String ())
require action = do
  True <- action | False => Left <$> getError
  pure (Right ())

frame : Renderer -> IO (Either String ())
frame renderer = do
  Right () <- require (setDrawColor renderer 24 28 40 255) | Left err => pure (Left err)
  Right () <- require (clear renderer) | Left err => pure (Left err)
  Right () <- require (setDrawColor renderer 80 180 255 255) | Left err => pure (Left err)
  Right () <- require (fillRect renderer 220 150 200 180) | Left err => pure (Left err)
  require (present renderer)

drain : EventBuffer -> IO Bool
drain buffer = do
  event <- pollEvent buffer
  case event of
    Nothing => pure False
    Just QuitRequested => pure True
    Just WindowCloseRequested => pure True
    _ => drain buffer

loop : Renderer -> EventBuffer -> IO (Either String ())
loop renderer buffer = do
  False <- drain buffer | True => pure (Right ())
  Right () <- frame renderer | Left err => pure (Left err)
  delay 16
  loop renderer buffer

runWindow : Window -> IO (Either String ())
runWindow window = do
  Right renderer <- createRenderer window | Left err => pure (Left err)
  result <- do
    Right buffer <- newEventBuffer | Left err => pure (Left err)
    result <- loop renderer buffer
    freeEventBuffer buffer
    pure result
  destroyRenderer renderer
  pure result

run : IO (Either String ())
run = do
  Right window <- createWindow "Idris 2 + SDL3" 640 480 resizable
    | Left err => pure (Left err)
  result <- runWindow window
  destroyWindow window
  pure result

main : IO ()
main = do
  ok <- SDL3.init video
  result <- the (IO (Either String ())) (if ok then run else Left <$> SDL3.getError)
  quit
  case result of
    Right () => pure ()
    Left err => do
      putStrLn err
      exitFailure
