module WindowScaleTests

import SDL3
import SDL3.Raw
import SDL3.Scoped
import System.FFI

%default covering

%foreign "C:idris_test_null_texture, libidris2_sdl3_test, fixtures.h"
prim__nullPointer : PrimIO AnyPtr

expectDummy : IO (Either String Double) -> IO (Either String ())
expectDummy query = do
  Right value <- query | Left err => pure (Left err)
  if value == 1.0 then pure (Right ()) else pure (Left "Dummy window scale was not 1.0")

failures : IO (Either String ())
failures = do
  ptr <- primIO prim__nullPointer
  density <- primIO (prim__getWindowPixelDensity ptr)
  densityError <- getError
  display <- primIO (prim__getWindowDisplayScale ptr)
  displayError <- getError
  if density /= 0.0 || display /= 0.0 || densityError == "" || displayError == ""
     then pure (Left "Null window scale queries lost their failure markers or errors")
     else pure (Right ())

renderState : Window -> Renderer -> IO (Either String ())
renderState window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    True <- setRenderLogicalPresentation renderer 4 3 PresentationStretch | False => Left <$> getError
    True <- setRenderScale renderer 2 3 | False => Left <$> getError
    True <- setRenderViewport renderer (Just (MkRect 1 1 3 2)) | False => Left <$> getError
    Right () <- expectDummy (getWindowPixelDensity window) | Left err => pure (Left err)
    expectDummy (getWindowDisplayScale window)

resizeQueries : Window -> IO (Either String ())
resizeQueries window = do
  let densityQuery = getWindowPixelDensity window
  let displayQuery = getWindowDisplayScale window
  Right () <- expectDummy densityQuery | Left err => pure (Left err)
  Right () <- expectDummy displayQuery | Left err => pure (Left err)
  True <- setWindowSize window (MkSize 53 31) | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  Right () <- expectDummy densityQuery | Left err => pure (Left err)
  Right () <- expectDummy displayQuery | Left err => pure (Left err)
  Right density <- densityQuery | Left err => pure (Left err)
  Right (MkSize w h) <- getWindowSize window | Left err => pure (Left err)
  Right (MkSize pw ph) <- getWindowSizeInPixels window | Left err => pure (Left err)
  if w <= 0 || h <= 0 || cast w * density /= the Double (cast pw) || cast h * density /= the Double (cast ph)
     then pure (Left "Dummy pixel density did not match the pixel-to-window size ratio")
     else pure (Right ())

export
windowScaleTests : IO (Either String ())
windowScaleTests = do
  Right () <- failures | Left err => pure (Left err)
  copied <- withWindow "window scale" 37 23 hidden $ \window => do
    Right density <- getWindowPixelDensity window | Left err => pure (Left err)
    Right display <- getWindowDisplayScale window | Left err => pure (Left err)
    Right () <- resizeQueries window | Left err => pure (Left err)
    Right () <- withRenderer window (renderState window) | Left err => pure (Left err)
    Right () <- withWindow "density requested" 72 48 (hidden <+> highPixelDensity) (\other => do
      Right () <- expectDummy (getWindowPixelDensity other) | Left err => pure (Left err)
      Right () <- expectDummy (getWindowDisplayScale other) | Left err => pure (Left err)
      expectDummy (getWindowPixelDensity window)) | Left err => pure (Left err)
    pure (Right (density, display))
  Right (density, display) <- pure copied | Left err => pure (Left err)
  if density == 1.0 && display == 1.0 then pure (Right ())
     else pure (Left "Copied scale values changed after window destruction")
