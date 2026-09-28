module WindowVisibilityTests

import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

roundTrips : Window -> Window -> IO (Either String ())
roundTrips window other = do
  let query = isWindowHidden window
  let show = showWindow window
  let hide = hideWindow window
  True <- query | False => pure (Left "Hidden creation flag was not reported")
  True <- show | False => Left <$> getError
  False <- query | True => pure (Left "Showing the window retained its hidden flag")
  True <- show | False => Left <$> getError
  False <- query | True => pure (Left "Repeated show changed the hidden flag")
  True <- isWindowHidden other | False => pure (Left "Showing one window changed another")
  True <- hide | False => Left <$> getError
  True <- query | False => pure (Left "Hiding the window did not set its hidden flag")
  True <- hide | False => Left <$> getError
  True <- query | False => pure (Left "Repeated hide changed the hidden flag")
  True <- show | False => Left <$> getError
  False <- query | True => pure (Left "Cached show action did not show the window again")
  True <- isWindowHidden other | False => pure (Left "Visibility changes affected another window")
  pure (Right ())

retainedRenderer : Window -> WindowID -> Renderer -> IO (Either String ())
retainedRenderer window (MkWindowID identifier) renderer =
  withTargetTexture renderer 8 8 $ \texture => do
    Right () <- withRenderTarget renderer (Just texture) (do
      True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
      True <- clear renderer | False => Left <$> getError
      pure (Right ())) | Left err => pure (Left err)
    True <- hideWindow window | False => Left <$> getError
    True <- isWindowHidden window | False => pure (Left "A rendered window did not hide")
    Right (MkSize 8 8) <- getTextureSize texture | _ => pure (Left "Hiding the window changed its texture")
    True <- showWindow window | False => Left <$> getError
    False <- isWindowHidden window | True => pure (Left "A rendered window did not show")
    True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    True <- renderTexture renderer texture (Just (MkFRect 4 4 8 8)) | False => Left <$> getError
    1 <- primIO (prim__pixel identifier 6 6 20 180 60 255) | _ => pure (Left "Hide/show did not preserve usable rendering resources")
    True <- present renderer | False => Left <$> getError
    pure (Right ())

export
windowVisibilityTests : IO (Either String ())
windowVisibilityTests = do
  copied <- withWindow "visibility" 37 23 (hidden <+> resizable <+> borderless) $ \window =>
    withWindow "other hidden window" 16 16 hidden $ \other => do
      initial <- isWindowHidden window
      Right identifier <- getWindowID window | Left err => pure (Left err)
      Right () <- roundTrips window other | Left err => pure (Left err)
      Right () <- withRenderer window (retainedRenderer window identifier) | Left err => pure (Left err)
      Right after <- getWindowID window | Left err => pure (Left err)
      title <- getWindowTitle window
      Right (MkSize 37 23) <- getWindowSize window | _ => pure (Left "Visibility changes altered dimensions")
      if after /= identifier || title /= "visibility" then pure (Left "Visibility changes altered window identity or title")
         else pure (Right initial)
  Right True <- pure copied | _ => pure (Left "Copied hidden state changed after window destruction")
  -- A window without the hidden creation flag starts shown on the dummy driver.
  withWindow "initially shown" 16 16 neutral $ \window => do
    False <- isWindowHidden window | True => pure (Left "Shown creation was reported as hidden")
    pure (Right ())
