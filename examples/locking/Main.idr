module Main

import SDL3
import SDL3.Scoped

import System

%default covering

stopRequested : WindowID -> EventBuffer -> IO (Either String Bool)
stopRequested identifier events = do
  event <- pollEventData events
  case event of
    Nothing => pure (Right False)
    Just (QuitEvent _) => pure (Right True)
    Just (WindowCloseEvent _ target) =>
      if target == identifier then pure (Right True) else stopRequested identifier events
    Just (KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False)) =>
      if target == identifier && key == escapeKey then pure (Right True) else stopRequested identifier events
    Just (RenderDeviceResetEvent _ target) =>
      if target == identifier
        then pure (Left "Renderer device reset. Restart the example to recreate textures.")
        else stopRequested identifier events
    _ => stopRequested identifier events

frame : Renderer -> Texture StreamingAccess -> TextureLockBuffer -> Int32 -> IO (Either String ())
frame renderer texture storage x = do
  Right () <- withTextureLockRGBA storage texture Nothing (\view => do
    -- Always initialize every locked pixel. Old texture contents are not available.
    True <- fillLockedRGBA view 20 40 60 255 | False => Left <$> getError
    True <- setLockedPixelRGBA view x 32 255 220 80 255 | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  -- The scoped call unlocked the texture before drawing uses it.
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture (Just (MkFRect 160 80 320 320)) | False => Left <$> getError
  True <- present renderer | False => Left <$> getError
  pure (Right ())

loop : WindowID -> Renderer -> Texture StreamingAccess -> TextureLockBuffer -> EventBuffer ->
       Bool -> Bits64 -> Maybe Nat -> IO (Either String ())
loop _ _ _ _ _ _ _ (Just Z) = pure (Right ())
loop identifier renderer texture storage events vsync origin budget = do
  start <- ticksNS
  Right stop <- stopRequested identifier events | Left err => pure (Left err)
  if stop then pure (Right ()) else do
    -- Move at about 60 pixels per second, independent of display refresh rate.
    let x : Int32 = cast (((start - origin) `div` 16666667) `mod` 64)
    Right () <- frame renderer texture storage x | Left err => pure (Left err)
    case vsync of
      True => pure ()
      False => do
        elapsed <- (\end => end - start) <$> ticksNS
        -- Include event handling and rendering. Guard unsigned subtraction.
        if elapsed < 16666667 then delayNS (16666667 - elapsed) else pure ()
    let next = case budget of
          Nothing => Nothing
          Just (S n) => Just n
          Just Z => Just Z
    loop identifier renderer texture storage events vsync origin next

run : Maybe Nat -> IO (Either String ())
run budget = withWindow "RGBA texture locking - Escape to close" 640 480 resizable $ \window => do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  withRenderer window $ \renderer => do
    True <- setRenderLogicalPresentation renderer 640 480 PresentationLetterbox | False => Left <$> getError
    -- Nothing in the frame loop changes this renderer's draw color.
    True <- setDrawColor renderer 8 12 20 255 | False => Left <$> getError
    vsync <- setRenderVSync renderer (VSyncInterval 1)
    case vsync of
      True => pure ()
      False => do
        err <- getError
        putStrLn ("VSync unavailable. Using timer pacing: " ++ err)
    withStreamingTexture renderer 64 64 $ \texture => do
      True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
      -- Allocate output storage once, not once per frame.
      withTextureLockBuffer $ \storage => withEventBuffer $ \events => do
        origin <- ticksNS
        loop identifier renderer texture storage events vsync origin budget

main : IO ()
main = do
  args <- getArgs
  budget <- case args of
    [_] => pure Nothing
    [_, "--smoke"] => pure (Just 3)
    _ => die "Usage: locking [--smoke]"
  ok <- init video
  result <- if ok then run budget else Left <$> getError
  quit
  either die pure result
