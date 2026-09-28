module WindowOpacityTests

import SDL3
import SDL3.Raw
import SDL3.Scoped
import System.FFI

%default covering

%foreign "C:idris_test_null_texture, libidris2_sdl3_test, fixtures.h"
prim__nullPointer : PrimIO AnyPtr

expectOpaque : IO (Either String Double) -> IO (Either String ())
expectOpaque query = do
  Right opacity <- query | Left err => pure (Left err)
  if opacity == 1.0 then pure (Right ()) else pure (Left "Dummy window opacity was not 1.0")

requests : Window -> List Double -> IO (Either String ())
requests window [] = pure (Right ())
requests window (value :: rest) = do
  False <- setWindowOpacity window value | True => pure (Left "Dummy driver unexpectedly accepted window opacity")
  err <- getError
  if err == "" then pure (Left "Rejected opacity request did not report an error") else do
    -- The getter succeeds even while the previous setter's SDL error remains set.
    Right () <- expectOpaque (getWindowOpacity window) | Left msg => pure (Left msg)
    requests window rest

rawFailure : IO (Either String ())
rawFailure = do
  ptr <- primIO prim__nullPointer
  value <- primIO (prim__getWindowOpacity ptr)
  err <- getError
  if value == -1.0 && err /= "" then pure (Right ()) else pure (Left "Raw opacity query lost its failure marker")

textureState : Window -> Renderer -> IO (Either String ())
textureState window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    True <- setTextureAlphaMod texture 123 | False => Left <$> getError
    Right () <- requests window [0.5, 0.0, 1.0] | Left err => pure (Left err)
    Right 123 <- getTextureAlphaMod texture | _ => pure (Left "Window opacity requests changed texture alpha")
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())

export
windowOpacityTests : IO (Either String ())
windowOpacityTests = do
  Right () <- rawFailure | Left err => pure (Left err)
  copied <- withWindow "window opacity" 37 23 neutral $ \window =>
    withWindow "other opacity" 16 16 hidden $ \other => do
      let query = getWindowOpacity window
      Right () <- expectOpaque query | Left err => pure (Left err)
      Right identifier <- getWindowID window | Left err => pure (Left err)
      Right () <- requests window [0.0, 0.5, 1.0, -2.0, 2.0, -1.0e300, 1.0e300, 0.5]
        | Left err => pure (Left err)
      Right () <- requests other [0.25, 1.0] | Left err => pure (Left err)
      Right () <- expectOpaque query | Left err => pure (Left err)
      Right () <- withRenderer window (textureState window) | Left err => pure (Left err)
      Right after <- getWindowID window | Left err => pure (Left err)
      title <- getWindowTitle window
      Right (MkSize 37 23) <- getWindowSize window | _ => pure (Left "Opacity requests changed window dimensions")
      if identifier == after && title == "window opacity" then query
         else pure (Left "Opacity requests changed window identity or title")
  Right value <- pure copied | Left err => pure (Left err)
  if value == 1.0 then pure (Right ()) else pure (Left "Copied window opacity changed after cleanup")
