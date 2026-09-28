module SizeTests

import SDL3
import SDL3.Scoped

%default covering

expect : IO (Either String (Size unit)) -> Int32 -> Int32 -> IO (Either String ())
expect query width height = do
  Right (MkSize w h) <- query | Left err => pure (Left err)
  if w == width && h == height then pure (Right ())
     else pure (Left ("Expected size " ++ show width ++ "x" ++ show height ++ ", got " ++ show w ++ "x" ++ show h))

export
sizeTests : Window -> Renderer -> IO (Either String ())
sizeTests window renderer = do
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
    -- Different dimensions exercise both halves of the packed native result.
    copied <- withWindow "size query" 37 23 hidden $ \temporary => do
      Right () <- expect (getWindowSizeInPixels temporary) 37 23 | Left err => pure (Left err)
      getWindowSize temporary
    Right (MkSize w h) <- pure copied | Left err => pure (Left err)
    if w == 37 && h == 23 then pure (Right ()) else pure (Left "Copied dimensions changed after window destruction")
