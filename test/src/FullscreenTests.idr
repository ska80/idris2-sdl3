module FullscreenTests

import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

findTransition : Nat -> Bool -> WindowID -> EventBuffer -> IO Bool
findTransition Z entered identifier buffer = pure False
findTransition (S budget) entered identifier buffer = do
  event <- pollEventData buffer
  case event of
    Just (WindowEnterFullscreenEvent _ target) =>
      if entered && target == identifier then pure True else findTransition budget entered identifier buffer
    Just (WindowLeaveFullscreenEvent _ target) =>
      if not entered && target == identifier then pure True else findTransition budget entered identifier buffer
    _ => findTransition budget entered identifier buffer

roundTrips : Window -> Window -> IO (Either String ())
roundTrips window other = withEventBuffer $ \buffer => do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  let enter = setWindowFullscreen window True
  let leave = setWindowFullscreen window False
  let query = isWindowFullscreen window
  False <- query | True => pure (Left "Windowed creation reported fullscreen")
  True <- enter | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  True <- query | False => pure (Left "Fullscreen request did not set the flag")
  True <- findTransition 256 True identifier buffer | False => pure (Left "Fullscreen entry notification was missing")
  True <- enter | False => Left <$> getError
  True <- query | False => pure (Left "Repeated fullscreen request cleared the flag")
  False <- isWindowFullscreen other | True => pure (Left "Fullscreen request changed another window")
  True <- leave | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  False <- query | True => pure (Left "Windowed request retained the fullscreen flag")
  True <- findTransition 256 False identifier buffer | False => pure (Left "Fullscreen exit notification was missing")
  True <- leave | False => Left <$> getError
  True <- enter | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  True <- query | False => pure (Left "Cached fullscreen request did not run again")
  True <- leave | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  False <- query | True => pure (Left "Cached windowed request did not run again")
  Right after <- getWindowID window | Left err => pure (Left err)
  title <- getWindowTitle window
  if after == identifier && title == "fullscreen tests" then pure (Right ())
     else pure (Left "Fullscreen transitions changed window identity or title")

retainedTarget : Window -> Renderer -> IO (Either String ())
retainedTarget window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    True <- setWindowFullscreen window True | False => Left <$> getError
    True <- syncWindow window | False => Left <$> getError
    True <- setWindowFullscreen window False | False => Left <$> getError
    True <- syncWindow window | False => Left <$> getError
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Fullscreen transitions changed target dimensions")
    1 <- primIO (prim__pixel identifier 2 2 20 180 60 255)
      | _ => pure (Left "Fullscreen transitions changed the selected target or its pixels")
    pure (Right ())

export
fullscreenTests : IO (Either String ())
fullscreenTests = do
  Right () <- withWindow "fullscreen tests" 37 23 neutral (\window =>
    withWindow "independent window" 16 16 hidden $ \other => do
      Right () <- roundTrips window other | Left err => pure (Left err)
      withRenderer window (retainedTarget window)) | Left err => pure (Left err)
  copied <- withWindow "hidden fullscreen" 16 16 (hidden <+> fullscreen) $ \window => do
    value <- isWindowFullscreen window
    True <- isWindowHidden window | False => pure (Left "Fullscreen creation unexpectedly showed a hidden window")
    True <- setWindowFullscreen window False | False => Left <$> getError
    True <- syncWindow window | False => Left <$> getError
    False <- isWindowFullscreen window | True => pure (Left "Hidden fullscreen window did not leave fullscreen")
    pure (Right value)
  Right True <- pure copied | _ => pure (Left "Copied fullscreen state changed after cleanup")
  pure (Right ())
