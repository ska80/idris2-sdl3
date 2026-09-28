module CoordinateTests

import SDL3

%default covering

near : Double -> Double -> Bool
near x y = abs (x - y) < 0.0001

pointCase : Renderer -> CoordinateBuffer -> Point WindowSpace -> Point RenderSpace -> IO (Either String ())
pointCase renderer buffer original@(MkPoint wx wy) (MkPoint expectedX expectedY) = do
  Right converted <- renderCoordinatesFromWindow renderer buffer original | Left err => pure (Left err)
  Right (MkPoint backX backY) <- renderCoordinatesToWindow renderer buffer converted | Left err => pure (Left err)
  -- Inspect the first copied point after the inverse call reuses native storage.
  let MkPoint x y = converted
  if near x expectedX && near y expectedY && near backX wx && near backY wy
     then pure (Right ())
     else pure (Left "Coordinate conversion or inverse result was incorrect")

scaleAndViewport : Renderer -> CoordinateBuffer -> IO (Either String ())
scaleAndViewport renderer buffer = do
  Right () <- pointCase renderer buffer (MkPoint 12.5 (-7.25)) (MkPoint 12.5 (-7.25))
    | Left err => pure (Left err)
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  Right () <- pointCase renderer buffer (MkPoint 12.5 (-7.5)) (MkPoint 6.25 (-2.5))
    | Left err => pure (Left err)
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  True <- setRenderViewport renderer (Just (MkRect 8 6 32 32)) | False => Left <$> getError
  Right () <- pointCase renderer buffer (MkPoint 12.5 10.25) (MkPoint 4.5 4.25)
    | Left err => pure (Left err)
  True <- setRenderViewport renderer Nothing | False => Left <$> getError
  pure (Right ())

logicalCoordinates : Renderer -> CoordinateBuffer -> IO (Either String ())
logicalCoordinates renderer buffer = do
  True <- setRenderLogicalPresentation renderer 32 16 PresentationLetterbox | False => Left <$> getError
  Right () <- pointCase renderer buffer (MkPoint 32 24) (MkPoint 16 4)
    | Left err => pure (Left err)
  -- Points in the letterbox border stay outside the logical scene, not clamped.
  Right () <- pointCase renderer buffer (MkPoint 0 0) (MkPoint 0 (-8))
    | Left err => pure (Left err)
  True <- setRenderClipRect renderer (Just (MkRect 0 0 1 1)) | False => Left <$> getError
  Right () <- pointCase renderer buffer (MkPoint 32 24) (MkPoint 16 4)
    | Left err => pure (Left err)
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  True <- setRenderViewport renderer (Just (MkRect 4 2 8 8)) | False => Left <$> getError
  Right converted <- renderCoordinatesFromWindow renderer buffer (MkPoint 20.25 40.5)
    | Left err => pure (Left err)
  Right (MkPoint x y) <- renderCoordinatesToWindow renderer buffer converted
    | Left err => pure (Left err)
  if near x 20.25 && near y 40.5 then pure (Right ()) else pure (Left "Combined coordinate transform did not round trip")

copiedPoint : Renderer -> IO (Either String ())
copiedPoint renderer = do
  Right buffer <- newCoordinateBuffer | Left err => pure (Left err)
  result <- renderCoordinatesFromWindow renderer buffer (MkPoint 1.25 2.5)
  freeCoordinateBuffer buffer
  Right (MkPoint x y) <- pure result | Left err => pure (Left err)
  if near x 1.25 && near y 2.5 then pure (Right ()) else pure (Left "Point did not survive buffer destruction")

cachedConversion : Renderer -> CoordinateBuffer -> IO (Either String ())
cachedConversion renderer buffer = do
  let query = renderCoordinatesFromWindow renderer buffer (MkPoint 12.5 (-7.5))
  Right (MkPoint x1 y1) <- query | Left err => pure (Left err)
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  Right (MkPoint x2 y2) <- query | Left err => pure (Left err)
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  if near x1 12.5 && near y1 (-7.5) && near x2 6.25 && near y2 (-2.5)
     then pure (Right ()) else pure (Left "Reused conversion action returned stale fields")

export
coordinateTests : Renderer -> IO (Either String ())
coordinateTests renderer = do
  Right buffer <- newCoordinateBuffer | Left err => pure (Left err)
  result <- do
    Right () <- cachedConversion renderer buffer | Left err => pure (Left err)
    Right () <- scaleAndViewport renderer buffer | Left err => pure (Left err)
    logicalCoordinates renderer buffer
  viewport <- setRenderViewport renderer Nothing
  clip <- setRenderClipRect renderer Nothing
  scale <- setRenderScale renderer 1 1
  logical <- setRenderLogicalPresentation renderer 0 0 PresentationDisabled
  freeCoordinateBuffer buffer
  Right () <- pure result | Left err => pure (Left err)
  if viewport && clip && scale && logical then copiedPoint renderer
     else pure (Left "Cannot restore renderer state after coordinate tests")
