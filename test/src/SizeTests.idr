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

rejectedSizes : Window -> List (Size WindowUnits) -> IO (Either String ())
rejectedSizes window [] = pure (Right ())
rejectedSizes window (dimensions :: rest) = do
  False <- setWindowSize window dimensions | True => pure (Left "Invalid window dimensions were accepted")
  err <- getError
  if err == "" then pure (Left "Rejected window size lost its SDL error") else do
    True <- syncWindow window | False => Left <$> getError
    Right () <- expect (getWindowSize window) 53 31 | Left err => pure (Left err)
    rejectedSizes window rest

resizeChecks : Window -> IO (Either String ())
resizeChecks window = do
  let resize = setWindowSize window (MkSize 53 31)
  let wait = syncWindow window
  True <- resize | False => Left <$> getError
  True <- wait | False => Left <$> getError
  Right () <- expect (getWindowSize window) 53 31 | Left err => pure (Left err)
  Right () <- rejectedSizes window [MkSize 0 31, MkSize 53 0, MkSize (-1) 31,
    MkSize 53 (-1), MkSize (-2147483648) 31, MkSize 53 (-2147483648)] | Left err => pure (Left err)
  True <- setWindowSize window (MkSize 1 1) | False => Left <$> getError
  True <- wait | False => Left <$> getError
  Right () <- expect (getWindowSize window) 1 1 | Left err => pure (Left err)
  True <- resize | False => Left <$> getError
  True <- wait | False => Left <$> getError
  Right () <- expect (getWindowSize window) 53 31 | Left err => pure (Left err)
  -- Waiting with no pending change also succeeds on the dummy driver.
  True <- wait | False => Left <$> getError
  pure (Right ())

reuseTests : Window -> IO (Either String ())
reuseTests other = do
  -- Retain only copied Idris values outside both native lifetimes.
  copied <- withWindow "size reuse" 37 23 hidden $ \window => do
    let windowQuery = getWindowSize window
    let pixelQuery = getWindowSizeInPixels window
    Right initial <- windowQuery | Left err => pure (Left err)
    Right () <- expect pixelQuery 37 23 | Left err => pure (Left err)
    Right () <- resizeChecks window | Left err => pure (Left err)
    Right () <- expect windowQuery 53 31 | Left err => pure (Left err)
    Right () <- expect pixelQuery 53 31 | Left err => pure (Left err)
    Right () <- expect (getWindowSize other) 64 64 | Left err => pure (Left err)
    Right () <- expect windowQuery 53 31 | Left err => pure (Left err)
    pure (Right initial)
  Right (MkSize w h) <- pure copied | Left err => pure (Left err)
  if w == 37 && h == 23 then pure (Right ())
     else pure (Left "Size changed after storage reuse or destruction")

findResize : EventBuffer -> WindowID -> Nat -> IO (Either String ())
findResize buffer identifier Z = pure (Left "Resize event was not found within the test limit")
findResize buffer identifier (S remaining) = do
  event <- pollEventData buffer
  case event of
    -- A poll-cycle boundary can precede events queued since the previous poll.
    Nothing => findResize buffer identifier remaining
    Just (WindowResizedEvent _ (MkWindowSizeData target width height)) =>
      if target == identifier && width == 53 && height == 31 then pure (Right ())
         else findResize buffer identifier remaining
    _ => findResize buffer identifier remaining

rendererResize : IO (Either String ())
rendererResize = withWindow "renderer resize" 37 23 (hidden <+> resizable) $ \window =>
  withRenderer window $ \renderer =>
    withTargetTexture renderer 7 9 $ \texture =>
      withEventBuffer $ \buffer => do
        Right identifier <- getWindowID window | Left err => pure (Left err)
        Right () <- withRenderTarget renderer (Just texture) (do
          True <- setRenderLogicalPresentation renderer 4 3 PresentationStretch | False => Left <$> getError
          True <- setWindowSize window (MkSize 53 31) | False => Left <$> getError
          True <- syncWindow window | False => Left <$> getError
          Right () <- expect (getWindowSize window) 53 31 | Left err => pure (Left err)
          Right () <- expect (getWindowSizeInPixels window) 53 31 | Left err => pure (Left err)
          expect (getTextureSize texture) 7 9) | Left err => pure (Left err)
        Right after <- getWindowID window | Left err => pure (Left err)
        if after /= identifier then pure (Left "Window resizing changed its identifier")
           else findResize buffer identifier 256

export
sizeTests : Window -> Renderer -> IO (Either String ())
sizeTests window renderer = do
  Right () <- layoutTests | Left err => pure (Left err)
  Right () <- reuseTests window | Left err => pure (Left err)
  Right () <- rendererResize | Left err => pure (Left err)
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
