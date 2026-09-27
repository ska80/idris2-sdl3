module ShapeTests

import SDL3

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_test_pixel_near, libidris2_sdl3_test, fixtures.h"
prim__pixelNear : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> IO (Either String ())
pixel window x y value = do
  1 <- primIO (prim__pixel window x y value value value 255)
    | _ => pure (Left "Shape pixel was incorrect")
  pure (Right ())

background : Renderer -> IO (Either String ())
background renderer = do
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- setDrawColor renderer 255 255 255 255 | False => Left <$> getError
  pure (Right ())

basicShapes : Bits32 -> Renderer -> IO (Either String ())
basicShapes window renderer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- drawPoint renderer (MkPoint 4 6) | False => Left <$> getError
  True <- drawLine renderer (MkPoint 8 10) (MkPoint 16 10) | False => Left <$> getError
  True <- drawLine renderer (MkPoint 24 8) (MkPoint 24 16) | False => Left <$> getError
  True <- drawRect renderer (Just (MkFRect 32 8 8 8)) | False => Left <$> getError
  Right () <- pixel window 4 6 255 | Left err => pure (Left err)
  Right () <- pixel window 5 6 0 | Left err => pure (Left err)
  Right () <- pixel window 8 10 255 | Left err => pure (Left err)
  Right () <- pixel window 16 10 255 | Left err => pure (Left err)
  Right () <- pixel window 24 12 255 | Left err => pure (Left err)
  Right () <- pixel window 32 12 255 | Left err => pure (Left err)
  Right () <- pixel window 39 12 255 | Left err => pure (Left err)
  pixel window 36 12 0

clippedShapes : Bits32 -> Renderer -> IO (Either String ())
clippedShapes window renderer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setRenderViewport renderer (Just (MkRect 8 8 32 32)) | False => Left <$> getError
  True <- setRenderClipRect renderer (Just (MkRect 4 4 8 8)) | False => Left <$> getError
  True <- drawPoint renderer (MkPoint 5 5) | False => Left <$> getError
  True <- drawLine renderer (MkPoint 0 6) (MkPoint 31 6) | False => Left <$> getError
  True <- drawRect renderer (Just (MkFRect 2 2 10 10)) | False => Left <$> getError
  True <- setRenderViewport renderer Nothing | False => Left <$> getError
  True <- setRenderClipRect renderer Nothing | False => Left <$> getError
  Right () <- pixel window 13 13 255 | Left err => pure (Left err)
  Right () <- pixel window 12 14 255 | Left err => pure (Left err)
  Right () <- pixel window 11 14 0 | Left err => pure (Left err)
  Right () <- pixel window 20 14 0 | Left err => pure (Left err)
  Right () <- pixel window 18 19 255 | Left err => pure (Left err)
  pixel window 15 15 0

scaledPoint : Bits32 -> Renderer -> IO (Either String ())
scaledPoint window renderer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  True <- drawPoint renderer (MkPoint 4.5 5) | False => Left <$> getError
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  Right () <- pixel window 9 15 255 | Left err => pure (Left err)
  Right () <- pixel window 10 17 255 | Left err => pure (Left err)
  pixel window 8 15 0

blendedShapes : Bits32 -> Renderer -> IO (Either String ())
blendedShapes window renderer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setDrawBlendMode renderer AlphaBlend | False => Left <$> getError
  True <- setDrawColor renderer 255 255 255 128 | False => Left <$> getError
  True <- drawPoint renderer (MkPoint 4 4) | False => Left <$> getError
  True <- drawLine renderer (MkPoint 8 8) (MkPoint 12 8) | False => Left <$> getError
  True <- drawRect renderer (Just (MkFRect 16 16 8 8)) | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 4 4 128 128 128 255 1) | _ => pure (Left "Point blending failed")
  1 <- primIO (prim__pixelNear window 10 8 128 128 128 255 1) | _ => pure (Left "Line blending failed")
  1 <- primIO (prim__pixelNear window 16 20 128 128 128 255 1) | _ => pure (Left "Outline blending failed")
  True <- setDrawBlendMode renderer NoBlend | False => Left <$> getError
  pure (Right ())

targetOutline : Bits32 -> Renderer -> IO (Either String ())
targetOutline window renderer = do
  Right texture <- createTargetTexture renderer 8 8 | Left err => pure (Left err)
  result <- withRenderTarget renderer (Just texture) $ do
    Right () <- background renderer | Left err => pure (Left err)
    True <- drawRect renderer Nothing | False => Left <$> getError
    Right () <- pixel window 0 0 255 | Left err => pure (Left err)
    Right () <- pixel window 7 7 255 | Left err => pure (Left err)
    pixel window 3 3 0
  restored <- setRenderTarget renderer Nothing
  destroyTexture texture
  Right () <- pure result | Left err => pure (Left err)
  if restored then pure (Right ()) else Left <$> getError

reset : Renderer -> IO Bool
reset renderer = do
  viewport <- setRenderViewport renderer Nothing
  clip <- setRenderClipRect renderer Nothing
  scale <- setRenderScale renderer 1 1
  blend <- setDrawBlendMode renderer NoBlend
  pure (viewport && clip && scale && blend)

export
shapeTests : Window -> Renderer -> IO (Either String ())
shapeTests window renderer = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  True <- reset renderer | False => Left <$> getError
  result <- do
    Right () <- basicShapes identifier renderer | Left err => pure (Left err)
    Right () <- clippedShapes identifier renderer | Left err => pure (Left err)
    Right () <- scaledPoint identifier renderer | Left err => pure (Left err)
    Right () <- blendedShapes identifier renderer | Left err => pure (Left err)
    targetOutline identifier renderer
  restored <- reset renderer
  Right () <- pure result | Left err => pure (Left err)
  if restored then pure (Right ()) else Left <$> getError
