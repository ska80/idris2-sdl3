module Main

import SDL3
import SDL3.Scoped

import System

%default covering

prepareTexture : Renderer -> Texture TargetAccess -> IO (Either String ())
prepareTexture renderer texture = withRenderTarget renderer (Just texture) $ do
  True <- setDrawColor renderer 80 180 255 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  pure (Right ())

frame : Renderer -> Texture TargetAccess -> FRect -> IO (Either String ())
frame renderer texture bounds = do
  True <- setDrawColor renderer 24 28 40 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture (Just bounds) | False => Left <$> getError
  True <- setDrawColor renderer 230 240 255 255 | False => Left <$> getError
  True <- drawRect renderer (Just bounds) | False => Left <$> getError
  True <- present renderer | False => Left <$> getError
  pure (Right ())

clickedRectangle : Renderer -> CoordinateBuffer -> FRect -> Double -> Double -> IO (Either String Bool)
clickedRectangle renderer coordinates (MkFRect left top width height) windowX windowY = do
  Right (MkPoint x y) <- renderCoordinatesFromWindow renderer coordinates (MkPoint windowX windowY)
    | Left err => pure (Left err)
  pure (Right (x >= left && x < left + width && y >= top && y < top + height))

handleEvent : WindowID -> Renderer -> Texture TargetAccess -> FRect -> CoordinateBuffer ->
              Event -> IO (Either String Bool)
handleEvent identifier renderer texture bounds coordinates event = case event of
  QuitEvent _ => pure (Right True)
  WindowCloseEvent _ target => pure (Right (target == identifier))
  KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False) =>
    pure (Right (target == identifier && key == escapeKey))
  MouseButtonEvent _ (MkMouseButtonData target _ button ButtonPressed _ x y) =>
    if target == identifier && button == leftButton
      then clickedRectangle renderer coordinates bounds x y
      else pure (Right False)
  WindowShownEvent _ target => redraw target
  WindowExposedEvent _ target => redraw target
  WindowRestoredEvent _ target => redraw target
  WindowResizedEvent _ (MkWindowSizeData target _ _) => redraw target
  WindowPixelSizeChangedEvent _ (MkPixelSizeData target _ _) => redraw target
  WindowDisplayScaleChangedEvent _ target => redraw target
  RenderTargetsResetEvent _ target =>
    if target == identifier then do
      -- A target reset loses pixels, not the texture handle. Repaint before sampling it.
      Right () <- prepareTexture renderer texture | Left err => pure (Left err)
      redraw target
    else pure (Right False)
  RenderDeviceResetEvent _ target =>
    if target == identifier
      then pure (Left "Renderer device reset. Restart the example to recreate textures.")
      else pure (Right False)
  _ => pure (Right False)
  where
    redraw : WindowID -> IO (Either String Bool)
    redraw target = case target == identifier of
      True => do
        Right () <- frame renderer texture bounds | Left err => pure (Left err)
        pure (Right False)
      False => pure (Right False)

loop : WindowID -> Renderer -> Texture TargetAccess -> FRect -> CoordinateBuffer -> EventBuffer -> IO (Either String ())
loop identifier renderer texture bounds coordinates events = do
  -- This scene is static. Wait instead of redrawing unchanged frames on a timer.
  Right event <- waitEventData events | Left err => pure (Left err)
  Right stop <- handleEvent identifier renderer texture bounds coordinates event | Left err => pure (Left err)
  if stop then pure (Right ()) else loop identifier renderer texture bounds coordinates events

runRenderer : WindowID -> Renderer -> Bool -> IO (Either String ())
runRenderer identifier renderer smoke = do
  True <- setRenderLogicalPresentation renderer 640 480 PresentationLetterbox | False => Left <$> getError
  withTargetTexture renderer 200 180 $ \texture => do
    Right () <- prepareTexture renderer texture | Left err => pure (Left err)
    Right (MkSize width height) <- getTextureSize texture | Left err => pure (Left err)
    -- Query once. Reuse the same drawing and click bounds throughout the loop.
    let bounds = MkFRect 220 150 (cast width) (cast height)
    Right () <- frame renderer texture bounds | Left err => pure (Left err)
    if smoke then pure (Right ()) else
      withCoordinateBuffer $ \coordinates =>
        withEventBuffer $ \events => loop identifier renderer texture bounds coordinates events

run : Bool -> IO (Either String ())
run smoke = withWindow "Idris 2 + SDL3 - Escape or click the blue box to close" 640 480 resizable $ \window => do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  withRenderer window $ \renderer => runRenderer identifier renderer smoke

main : IO ()
main = do
  args <- getArgs
  smoke <- case args of
    [_] => pure False
    [_, "--smoke"] => pure True
    _ => die "Usage: basic [--smoke]"
  ok <- SDL3.init video
  result <- if ok then run smoke else Left <$> getError
  quit
  either die pure result
