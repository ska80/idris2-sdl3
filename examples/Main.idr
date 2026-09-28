module Main

import SDL3
import SDL3.Scoped
import System

%default covering

require : IO Bool -> IO (Either String ())
require action = do
  True <- action | False => Left <$> getError
  pure (Right ())

prepareTexture : Renderer -> Texture TargetAccess -> IO (Either String ())
prepareTexture renderer texture = withRenderTarget renderer (Just texture) $ do
  Right () <- require (setDrawColor renderer 80 180 255 255) | Left err => pure (Left err)
  require (clear renderer)

frame : Renderer -> Texture TargetAccess -> FRect -> IO (Either String ())
frame renderer texture bounds = do
  Right () <- require (setDrawColor renderer 24 28 40 255) | Left err => pure (Left err)
  Right () <- require (clear renderer) | Left err => pure (Left err)
  Right () <- require (renderTexture renderer texture (Just bounds))
    | Left err => pure (Left err)
  Right () <- require (setDrawColor renderer 230 240 255 255) | Left err => pure (Left err)
  Right () <- require (drawRect renderer (Just bounds)) | Left err => pure (Left err)
  require (present renderer)

clickedRectangle : Renderer -> CoordinateBuffer -> FRect -> Double -> Double -> IO (Either String Bool)
clickedRectangle renderer coordinates (MkFRect left top width height) windowX windowY = do
  Right (MkPoint x y) <- renderCoordinatesFromWindow renderer coordinates (MkPoint windowX windowY)
    | Left err => pure (Left err)
  pure (Right (x >= left && x < left + width && y >= top && y < top + height))

drain : WindowID -> Renderer -> FRect -> CoordinateBuffer -> EventBuffer -> IO (Either String Bool)
drain window renderer bounds coordinates buffer = do
  event <- pollEventData buffer
  case event of
    Nothing => pure (Right False)
    Just (QuitEvent _) => pure (Right True)
    Just (WindowCloseEvent _ target) =>
      if target == window then pure (Right True) else drain window renderer bounds coordinates buffer
    Just (KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False)) =>
      if target == window && key == escapeKey then pure (Right True) else drain window renderer bounds coordinates buffer
    Just (MouseButtonEvent _ (MkMouseButtonData target _ button ButtonPressed _ x y)) =>
      if target == window && button == leftButton then do
        Right hit <- clickedRectangle renderer coordinates bounds x y | Left err => pure (Left err)
        if hit then pure (Right True) else drain window renderer bounds coordinates buffer
      else drain window renderer bounds coordinates buffer
    _ => drain window renderer bounds coordinates buffer

loop : WindowID -> Renderer -> Texture TargetAccess -> FRect -> CoordinateBuffer -> EventBuffer -> IO (Either String ())
loop window renderer texture bounds coordinates buffer = do
  start <- ticksNS
  Right stop <- drain window renderer bounds coordinates buffer | Left err => pure (Left err)
  if stop then pure (Right ()) else do
    Right () <- frame renderer texture bounds | Left err => pure (Left err)
    end <- ticksNS
    let elapsed = end - start
    -- Target roughly 60 frames per second, including event and drawing work.
    -- Guard subtraction: Bits64 would wrap if this frame exceeded its budget.
    if elapsed < 16666667 then delayNS (16666667 - elapsed) else pure ()
    loop window renderer texture bounds coordinates buffer

runRenderer : WindowID -> Renderer -> IO (Either String ())
runRenderer identifier renderer = do
  Right () <- require (setRenderLogicalPresentation renderer 640 480 PresentationLetterbox)
    | Left err => pure (Left err)
  withTargetTexture renderer 200 180 $ \texture => do
    Right () <- prepareTexture renderer texture | Left err => pure (Left err)
    Right (MkSize width height) <- getTextureSize texture | Left err => pure (Left err)
    -- Query once. Reuse the same drawing and click bounds throughout the loop.
    let bounds = MkFRect 220 150 (cast width) (cast height)
    withCoordinateBuffer $ \coordinates =>
      withEventBuffer $ \buffer =>
        loop identifier renderer texture bounds coordinates buffer

runWindow : Window -> IO (Either String ())
runWindow window = do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  withRenderer window (runRenderer identifier)

run : IO (Either String ())
run = withWindow "Idris 2 + SDL3" 640 480 resizable runWindow

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
