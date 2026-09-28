module SizeTests

import SDL3
import SDL3.Scoped
import SDL3.Raw
import System.FFI

%default covering

expect : IO (Either String (Size unit)) -> Int32 -> Int32 -> IO (Either String ())
expect query width height = do
  Right (MkSize w h) <- query | Left err => pure (Left err)
  if w == width && h == height then pure (Right ())
     else pure (Left ("Expected size " ++ show width ++ "x" ++ show height ++ ", got " ++ show w ++ "x" ++ show h))

%foreign "C:idris_test_size_fields, libidris2_sdl3_test, fixtures.h"
prim__sizeFields : NativeSize -> Int32 -> Int32 -> PrimIO ()

%foreign "C:idris_test_resize_window, libidris2_sdl3_test, fixtures.h"
prim__resizeWindow : Bits32 -> Int32 -> Int32 -> PrimIO Int

checkFields : NativeSize -> Int32 -> Int32 -> IO (Either String ())
checkFields storage w h = do
  primIO (prim__sizeFields storage w h)
  let actualW : Int32 = getField storage "width"
  let actualH : Int32 = getField storage "height"
  if actualW == w && actualH == h then pure (Right ())
     else pure (Left "Native size layout or signed field access was incorrect")

layoutTests : IO (Either String ())
layoutTests = do
  storage <- primIO prim__newSize
  0 <- primIO (prim__sizeIsNull storage) | _ => Left <$> getError
  result <- do
    Right () <- checkFields storage 0 0 | Left err => pure (Left err)
    Right () <- checkFields storage (-2147483648) 2147483647 | Left err => pure (Left err)
    checkFields storage 2147483647 (-2147483648)
  primIO (prim__freeSize storage)
  pure result

reuseTests : Window -> IO (Either String ())
reuseTests other = do
  -- Retain only copied Idris values outside both native lifetimes.
  copied <- withWindow "size reuse" 37 23 hidden $ \window => do
    Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
    let windowQuery = getWindowSize window
    let pixelQuery = getWindowSizeInPixels window
    Right initial <- windowQuery | Left err => pure (Left err)
    Right () <- expect pixelQuery 37 23 | Left err => pure (Left err)
    1 <- primIO (prim__resizeWindow identifier 53 31) | _ => Left <$> getError
    Right () <- expect windowQuery 53 31 | Left err => pure (Left err)
    Right () <- expect pixelQuery 53 31 | Left err => pure (Left err)
    Right () <- expect (getWindowSize other) 64 64 | Left err => pure (Left err)
    Right () <- expect windowQuery 53 31 | Left err => pure (Left err)
    pure (Right initial)
  Right (MkSize w h) <- pure copied | Left err => pure (Left err)
  if w == 37 && h == 23 then pure (Right ())
     else pure (Left "Size changed after storage reuse or destruction")

export
sizeTests : Window -> Renderer -> IO (Either String ())
sizeTests window renderer = do
  Right () <- layoutTests | Left err => pure (Left err)
  Right () <- reuseTests window | Left err => pure (Left err)
  Right () <- expect (getWindowSize window) 64 64 | Left err => pure (Left err)
  -- Dummy video uses one physical pixel per window coordinate.
  Right () <- expect (getWindowSizeInPixels window) 64 64 | Left err => pure (Left err)
  Right texture <- createTargetTexture renderer 16 8 | Left err => pure (Left err)
  result <- withRenderTarget renderer (Just texture) $ do
    True <- setRenderLogicalPresentation renderer 4 2 PresentationStretch | False => Left <$> getError
    Right () <- expect (getWindowSize window) 64 64 | Left err => pure (Left err)
    expect (getWindowSizeInPixels window) 64 64
  restored <- setRenderTarget renderer Nothing
  destroyTexture texture
  Right () <- pure result | Left err => pure (Left err)
  if not restored then Left <$> getError else do
    -- Different dimensions exercise both fields of the native result.
    copied <- withWindow "size query" 37 23 hidden $ \temporary => do
      Right () <- expect (getWindowSizeInPixels temporary) 37 23 | Left err => pure (Left err)
      getWindowSize temporary
    Right (MkSize w h) <- pure copied | Left err => pure (Left err)
    if w == 37 && h == 23 then pure (Right ()) else pure (Left "Copied dimensions changed after window destruction")
