module BatchTests

import SDL3
import SDL3.Scoped
import Data.IORef

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_test_pixel_near, libidris2_sdl3_test, fixtures.h"
prim__pixelNear : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> IO (Either String ())
pixel window x y value = do
  1 <- primIO (prim__pixel window x y value value value 255)
    | _ => pure (Left "Batch drawing produced an incorrect pixel")
  pure (Right ())

background : Renderer -> IO (Either String ())
background renderer = do
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- setDrawColor renderer 255 255 255 255 | False => Left <$> getError
  pure (Right ())

rejectedCapacity : IO (Either String ())
rejectedCapacity = do
  called <- newIORef False
  result <- withPointBuffer 0 $ \_ => do
    writeIORef called True
    pure (Right ())
  ran <- readIORef called
  Left err <- pure result | Right () => pure (Left "Zero point capacity was accepted")
  if ran || err == "" then pure (Left "Point allocation failure ran the callback or lost its error") else do
    Left err <- newPointBuffer 0x80000000 | Right buffer => do
      freePointBuffer buffer
      pure (Left "Point capacity exceeded the SDL count limit")
    if err /= "" then pure (Right ()) else pure (Left "Point capacity failure lost its error")

points : Bits32 -> Renderer -> PointBuffer -> IO (Either String ())
points window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  -- Unwritten entries are initialized, not uninitialized native memory.
  True <- drawPoints renderer buffer 4 | False => Left <$> getError
  Right () <- pixel window 0 0 255 | Left err => pure (Left err)
  Right () <- background renderer | Left err => pure (Left err)
  True <- setPoint buffer 0 (MkPoint 4 6) | False => Left <$> getError
  True <- setPoint buffer 1 (MkPoint 8 6) | False => Left <$> getError
  True <- setPoint buffer 2 (MkPoint 12 6) | False => Left <$> getError
  True <- drawPoints renderer buffer 0 | False => Left <$> getError
  Right () <- pixel window 4 6 0 | Left err => pure (Left err)
  True <- drawPoints renderer buffer 2 | False => Left <$> getError
  -- Change the input before readback flushes pending draw commands.
  True <- setPoint buffer 0 (MkPoint 20 6) | False => Left <$> getError
  True <- setPoint buffer 1 (MkPoint 22 6) | False => Left <$> getError
  Right () <- pixel window 4 6 255 | Left err => pure (Left err)
  Right () <- pixel window 8 6 255 | Left err => pure (Left err)
  Right () <- pixel window 20 6 0 | Left err => pure (Left err)
  False <- setPoint buffer 4 (MkPoint 30 6) | True => pure (Left "Point index at capacity was accepted")
  False <- setPoint buffer 0xffffffff (MkPoint 30 6) | True => pure (Left "Oversized point index was accepted")
  False <- drawPoints renderer buffer 5 | True => pure (Left "Oversized point draw was accepted")
  False <- drawLines renderer buffer 0xffffffff | True => pure (Left "Oversized line draw was accepted")
  Right () <- pixel window 12 6 0 | Left err => pure (Left err)
  Right () <- pixel window 0 0 0 | Left err => pure (Left err)
  True <- drawPoints renderer buffer 2 | False => Left <$> getError
  Right () <- pixel window 20 6 255 | Left err => pure (Left err)
  pixel window 22 6 255

lines : Bits32 -> Renderer -> PointBuffer -> IO (Either String ())
lines window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setPoint buffer 0 (MkPoint 4 12) | False => Left <$> getError
  True <- setPoint buffer 1 (MkPoint 12 12) | False => Left <$> getError
  True <- setPoint buffer 2 (MkPoint 12 20) | False => Left <$> getError
  True <- drawLines renderer buffer 0 | False => Left <$> getError
  True <- drawLines renderer buffer 1 | False => Left <$> getError
  Right () <- pixel window 4 12 0 | Left err => pure (Left err)
  True <- drawLines renderer buffer 3 | False => Left <$> getError
  True <- setPoint buffer 1 (MkPoint 30 30) | False => Left <$> getError
  Right () <- pixel window 4 12 255 | Left err => pure (Left err)
  Right () <- pixel window 8 12 255 | Left err => pure (Left err)
  Right () <- pixel window 12 16 255 | Left err => pure (Left err)
  Right () <- pixel window 12 20 255 | Left err => pure (Left err)
  pixel window 8 16 0

clipped : Bits32 -> Renderer -> PointBuffer -> IO (Either String ())
clipped window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setPoint buffer 0 (MkPoint 2 3) | False => Left <$> getError
  True <- setPoint buffer 1 (MkPoint 6 3) | False => Left <$> getError
  True <- setRenderViewport renderer (Just (MkRect 8 8 16 16)) | False => Left <$> getError
  True <- setRenderClipRect renderer (Just (MkRect 0 0 4 4)) | False => Left <$> getError
  True <- drawPoints renderer buffer 2 | False => Left <$> getError
  True <- setRenderViewport renderer Nothing | False => Left <$> getError
  True <- setRenderClipRect renderer Nothing | False => Left <$> getError
  Right () <- pixel window 10 11 255 | Left err => pure (Left err)
  pixel window 14 11 0

scaled : Bits32 -> Renderer -> PointBuffer -> IO (Either String ())
scaled window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setPoint buffer 0 (MkPoint 4.5 5) | False => Left <$> getError
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  True <- drawPoints renderer buffer 1 | False => Left <$> getError
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  Right () <- pixel window 9 15 255 | Left err => pure (Left err)
  Right () <- pixel window 10 17 255 | Left err => pure (Left err)
  pixel window 8 15 0

blended : Bits32 -> Renderer -> PointBuffer -> IO (Either String ())
blended window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setDrawBlendMode renderer AlphaBlend | False => Left <$> getError
  True <- setDrawColor renderer 255 255 255 128 | False => Left <$> getError
  True <- setPoint buffer 0 (MkPoint 4 4) | False => Left <$> getError
  True <- drawPoints renderer buffer 1 | False => Left <$> getError
  True <- setPoint buffer 0 (MkPoint 8 8) | False => Left <$> getError
  True <- setPoint buffer 1 (MkPoint 12 8) | False => Left <$> getError
  True <- drawLines renderer buffer 2 | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 4 4 128 128 128 255 1) | _ => pure (Left "Batch point blending failed")
  1 <- primIO (prim__pixelNear window 10 8 128 128 128 255 1) | _ => pure (Left "Batch line blending failed")
  True <- setDrawBlendMode renderer NoBlend | False => Left <$> getError
  pure (Right ())

anotherRenderer : PointBuffer -> IO (Either String ())
anotherRenderer buffer = withWindow "point buffer reuse" 16 16 hidden $ \window =>
  withRenderer window $ \renderer => do
    Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
    Right () <- background renderer | Left err => pure (Left err)
    True <- setPoint buffer 0 (MkPoint 3 5) | False => Left <$> getError
    True <- drawPoints renderer buffer 1 | False => Left <$> getError
    pixel identifier 3 5 255

releasedInput : Bits32 -> Renderer -> IO (Either String ())
releasedInput window renderer = do
  Right () <- background renderer | Left err => pure (Left err)
  result <- withPointBuffer 1 $ \buffer => do
    True <- setPoint buffer 0 (MkPoint 30 6) | False => Left <$> getError
    True <- drawPoints renderer buffer 1 | False => Left <$> getError
    pure (Right (the Bits64 0x100000002))
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Point scope changed its callback result") else do
    Right () <- pixel window 30 6 255 | Left err => pure (Left err)
    Left "point scope failed" <- withPointBuffer 1 (\buffer => do
      True <- setPoint buffer 0 (MkPoint 32 6) | False => Left <$> getError
      True <- drawPoints renderer buffer 1 | False => Left <$> getError
      pure (the (Either String ()) (Left "point scope failed")))
      | _ => pure (Left "Point scope changed its callback error")
    pixel window 32 6 255

reset : Renderer -> IO Bool
reset renderer = do
  viewport <- setRenderViewport renderer Nothing
  clip <- setRenderClipRect renderer Nothing
  scale <- setRenderScale renderer 1 1
  blend <- setDrawBlendMode renderer NoBlend
  pure (viewport && clip && scale && blend)

export
batchTests : Window -> Renderer -> IO (Either String ())
batchTests window renderer = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Right () <- rejectedCapacity | Left err => pure (Left err)
  True <- reset renderer | False => Left <$> getError
  result <- withPointBuffer 4 $ \buffer => do
    Right () <- points identifier renderer buffer | Left err => pure (Left err)
    Right () <- lines identifier renderer buffer | Left err => pure (Left err)
    Right () <- clipped identifier renderer buffer | Left err => pure (Left err)
    Right () <- scaled identifier renderer buffer | Left err => pure (Left err)
    Right () <- blended identifier renderer buffer | Left err => pure (Left err)
    Right () <- anotherRenderer buffer | Left err => pure (Left err)
    Right () <- withTargetTexture renderer 32 32 (\texture =>
      withRenderTarget renderer (Just texture) (lines identifier renderer buffer))
      | Left err => pure (Left err)
    releasedInput identifier renderer
  restored <- reset renderer
  Right () <- pure result | Left err => pure (Left err)
  if restored then pure (Right ()) else pure (Left "Cannot restore state after batch tests")
