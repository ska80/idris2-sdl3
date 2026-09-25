module Main

import SDL3
import System

%default covering

require : IO Bool -> IO (Either String ())
require action = do
  True <- action | False => Left <$> getError
  pure (Right ())

prepareTexture : Renderer -> Texture TargetAccess -> IO (Either String ())
prepareTexture renderer texture = do
  Right () <- require (setRenderTarget renderer (Just texture)) | Left err => pure (Left err)
  result <- do
    Right () <- require (setDrawColor renderer 80 180 255 255) | Left err => pure (Left err)
    require (clear renderer)
  restored <- require (setRenderTarget renderer Nothing)
  case result of
    Left err => pure (Left err)
    Right () => pure restored

frame : Renderer -> Texture TargetAccess -> IO (Either String ())
frame renderer texture = do
  Right () <- require (setDrawColor renderer 24 28 40 255) | Left err => pure (Left err)
  Right () <- require (clear renderer) | Left err => pure (Left err)
  Right () <- require (renderTexture renderer texture (Just (MkFRect 220 150 200 180)))
    | Left err => pure (Left err)
  require (present renderer)

clickedRectangle : Renderer -> CoordinateBuffer -> Double -> Double -> IO (Either String Bool)
clickedRectangle renderer coordinates windowX windowY = do
  Right (MkPoint x y) <- renderCoordinatesFromWindow renderer coordinates (MkPoint windowX windowY)
    | Left err => pure (Left err)
  pure (Right (x >= 220 && x < 420 && y >= 150 && y < 330))

drain : WindowID -> Renderer -> CoordinateBuffer -> EventBuffer -> IO (Either String Bool)
drain window renderer coordinates buffer = do
  event <- pollEventData buffer
  case event of
    Nothing => pure (Right False)
    Just (QuitEvent _) => pure (Right True)
    Just (WindowCloseEvent _ target) =>
      if target == window then pure (Right True) else drain window renderer coordinates buffer
    Just (KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False)) =>
      if target == window && key == escapeKey then pure (Right True) else drain window renderer coordinates buffer
    Just (MouseButtonEvent _ (MkMouseButtonData target _ button ButtonPressed _ x y)) =>
      if target == window && button == leftButton then do
        Right hit <- clickedRectangle renderer coordinates x y | Left err => pure (Left err)
        if hit then pure (Right True) else drain window renderer coordinates buffer
      else drain window renderer coordinates buffer
    _ => drain window renderer coordinates buffer

loop : WindowID -> Renderer -> Texture TargetAccess -> CoordinateBuffer -> EventBuffer -> IO (Either String ())
loop window renderer texture coordinates buffer = do
  Right stop <- drain window renderer coordinates buffer | Left err => pure (Left err)
  if stop then pure (Right ()) else do
    Right () <- frame renderer texture | Left err => pure (Left err)
    delay 16
    loop window renderer texture coordinates buffer

runRenderer : WindowID -> Renderer -> IO (Either String ())
runRenderer identifier renderer = do
  Right () <- require (setRenderLogicalPresentation renderer 640 480 PresentationLetterbox)
    | Left err => pure (Left err)
  Right texture <- createTargetTexture renderer 200 180 | Left err => pure (Left err)
  result <- do
    Right () <- prepareTexture renderer texture | Left err => pure (Left err)
    Right coordinates <- newCoordinateBuffer | Left err => pure (Left err)
    result <- do
      Right buffer <- newEventBuffer | Left err => pure (Left err)
      result <- loop identifier renderer texture coordinates buffer
      freeEventBuffer buffer
      pure result
    freeCoordinateBuffer coordinates
    pure result
  destroyTexture texture
  pure result

runWindow : Window -> IO (Either String ())
runWindow window = do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  Right renderer <- createRenderer window | Left err => pure (Left err)
  result <- runRenderer identifier renderer
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
