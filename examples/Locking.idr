module Locking

import SDL3
import SDL3.Scoped
import System

%default covering

stopRequested : WindowID -> EventBuffer -> IO Bool
stopRequested identifier events = do
  event <- pollEventData events
  case event of
    Nothing => pure False
    Just (QuitEvent _) => pure True
    Just (WindowCloseEvent _ target) =>
      if target == identifier then pure True else stopRequested identifier events
    Just (KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False)) =>
      if target == identifier && key == escapeKey then pure True else stopRequested identifier events
    _ => stopRequested identifier events

frame : Renderer -> Texture StreamingAccess -> TextureLockBuffer -> Int32 -> IO (Either String ())
frame renderer texture storage x = do
  Right () <- withTextureLockRGBA storage texture Nothing (\view => do
    -- Always initialize every locked pixel. Old texture contents are not available.
    True <- fillLockedRGBA view 20 40 60 255 | False => Left <$> getError
    True <- setLockedPixelRGBA view x 32 255 220 80 255 | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  -- The scoped call unlocked the texture before drawing uses it.
  True <- setDrawColor renderer 8 12 20 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture (Just (MkFRect 160 80 320 320)) | False => Left <$> getError
  True <- present renderer | False => Left <$> getError
  pure (Right ())

loop : WindowID -> Renderer -> Texture StreamingAccess -> TextureLockBuffer -> EventBuffer ->
       Int32 -> Maybe Nat -> IO (Either String ())
loop identifier renderer texture storage events x (Just Z) = pure (Right ())
loop identifier renderer texture storage events x budget = do
  stop <- stopRequested identifier events
  if stop then pure (Right ()) else do
    start <- ticksNS
    Right () <- frame renderer texture storage x | Left err => pure (Left err)
    elapsed <- (\end => end - start) <$> ticksNS
    if elapsed < 16666667 then delayNS (16666667 - elapsed) else pure ()
    let next = case budget of
          Nothing => Nothing
          Just (S n) => Just n
          Just Z => Just Z
    loop identifier renderer texture storage events (if x == 63 then 0 else x + 1) next

run : Maybe Nat -> IO (Either String ())
run budget = withWindow "RGBA texture locking - Escape to close" 640 480 resizable $ \window => do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  withRenderer window $ \renderer => do
    True <- setRenderLogicalPresentation renderer 640 480 PresentationLetterbox | False => Left <$> getError
    withStreamingTexture renderer 64 64 $ \texture => do
      True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
      -- Allocate output storage once, not once per frame.
      withTextureLockBuffer $ \storage =>
        withEventBuffer $ \events => loop identifier renderer texture storage events 0 budget

main : IO ()
main = do
  True <- init video | False => do
    err <- getError
    putStrLn err
    exitFailure
  args <- getArgs
  result <- run (if elem "--smoke" args then Just 3 else Nothing)
  quit
  case result of
    Right () => pure ()
    Left err => do
      putStrLn err
      exitFailure
