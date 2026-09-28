module RectBatchTests

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
    | _ => pure (Left "Rectangle batch produced an incorrect pixel")
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
  result <- withRectBuffer 0 $ \_ => do
    writeIORef called True
    pure (Right ())
  ran <- readIORef called
  Left err <- pure result | Right () => pure (Left "Zero rectangle capacity was accepted")
  if ran || err == "" then pure (Left "Rectangle allocation failure ran the callback or lost its error") else do
    Left err <- newRectBuffer 0x80000000 | Right buffer => do
      freeRectBuffer buffer
      pure (Left "Rectangle capacity exceeded the SDL count limit")
    if err /= "" then pure (Right ()) else pure (Left "Rectangle capacity failure lost its error")

outlines : Bits32 -> Renderer -> RectBuffer -> IO (Either String ())
outlines window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setRect buffer 0 (MkFRect 4 4 8 6) | False => Left <$> getError
  True <- setRect buffer 1 (MkFRect 20 4 4 8) | False => Left <$> getError
  True <- setRect buffer 2 (MkFRect 28 4 4 4) | False => Left <$> getError
  True <- drawRects renderer buffer 0 | False => Left <$> getError
  True <- fillRects renderer buffer 0 | False => Left <$> getError
  Right () <- pixel window 4 4 0 | Left err => pure (Left err)
  True <- drawRects renderer buffer 2 | False => Left <$> getError
  -- Modify the source before readback flushes any pending drawing commands.
  True <- setRect buffer 0 (MkFRect 4 20 8 6) | False => Left <$> getError
  Right () <- pixel window 4 4 255 | Left err => pure (Left err)
  Right () <- pixel window 11 8 255 | Left err => pure (Left err)
  Right () <- pixel window 7 9 255 | Left err => pure (Left err)
  Right () <- pixel window 7 6 0 | Left err => pure (Left err)
  Right () <- pixel window 23 8 255 | Left err => pure (Left err)
  Right () <- pixel window 21 6 0 | Left err => pure (Left err)
  pixel window 4 20 0

boundsAndFills : Bits32 -> Renderer -> RectBuffer -> IO (Either String ())
boundsAndFills window renderer buffer = do
  False <- setRect buffer 3 (MkFRect 24 24 4 4) | True => pure (Left "Rectangle index at capacity was accepted")
  False <- setRect buffer 0xffffffff (MkFRect 24 24 4 4) | True => pure (Left "Oversized rectangle index was accepted")
  False <- drawRects renderer buffer 4 | True => pure (Left "Oversized outline count was accepted")
  False <- fillRects renderer buffer 0xffffffff | True => pure (Left "Oversized fill count was accepted")
  Right () <- pixel window 28 4 0 | Left err => pure (Left err)
  Right () <- pixel window 7 6 0 | Left err => pure (Left err)
  True <- fillRects renderer buffer 2 | False => Left <$> getError
  True <- setRect buffer 0 (MkFRect 8 24 4 4) | False => Left <$> getError
  Right () <- pixel window 7 22 255 | Left err => pure (Left err)
  Right () <- pixel window 21 6 255 | Left err => pure (Left err)
  Right () <- pixel window 25 25 0 | Left err => pure (Left err)
  Right () <- pixel window 29 5 0 | Left err => pure (Left err)
  True <- drawRects renderer buffer 3 | False => Left <$> getError
  True <- fillRects renderer buffer 3 | False => Left <$> getError
  pixel window 29 5 255

outlinesAndFills : Bits32 -> Renderer -> RectBuffer -> IO (Either String ())
outlinesAndFills window renderer buffer = do
  Right () <- outlines window renderer buffer | Left err => pure (Left err)
  boundsAndFills window renderer buffer

clipped : Bits32 -> Renderer -> RectBuffer -> IO (Either String ())
clipped window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setRect buffer 0 (MkFRect 0 0 8 8) | False => Left <$> getError
  True <- setRenderViewport renderer (Just (MkRect 8 8 16 16)) | False => Left <$> getError
  True <- setRenderClipRect renderer (Just (MkRect 2 2 3 3)) | False => Left <$> getError
  True <- fillRects renderer buffer 1 | False => Left <$> getError
  True <- setRenderViewport renderer Nothing | False => Left <$> getError
  True <- setRenderClipRect renderer Nothing | False => Left <$> getError
  Right () <- pixel window 10 10 255 | Left err => pure (Left err)
  Right () <- pixel window 12 12 255 | Left err => pure (Left err)
  Right () <- pixel window 9 10 0 | Left err => pure (Left err)
  pixel window 13 12 0

scaled : Bits32 -> Renderer -> RectBuffer -> IO (Either String ())
scaled window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setRect buffer 0 (MkFRect 4.5 5 2 2) | False => Left <$> getError
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  True <- fillRects renderer buffer 1 | False => Left <$> getError
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  Right () <- pixel window 9 15 255 | Left err => pure (Left err)
  Right () <- pixel window 12 20 255 | Left err => pure (Left err)
  Right () <- pixel window 13 20 0 | Left err => pure (Left err)
  Right () <- background renderer | Left err => pure (Left err)
  True <- setRect buffer 0 (MkFRect 2 3 2 2) | False => Left <$> getError
  True <- setRenderLogicalPresentation renderer 32 32 PresentationStretch | False => Left <$> getError
  True <- fillRects renderer buffer 1 | False => Left <$> getError
  True <- setRenderLogicalPresentation renderer 0 0 PresentationDisabled | False => Left <$> getError
  Right () <- pixel window 4 6 255 | Left err => pure (Left err)
  Right () <- pixel window 7 9 255 | Left err => pure (Left err)
  pixel window 8 9 0

blended : Bits32 -> Renderer -> RectBuffer -> IO (Either String ())
blended window renderer buffer = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- setDrawBlendMode renderer AlphaBlend | False => Left <$> getError
  True <- setDrawColor renderer 255 255 255 128 | False => Left <$> getError
  True <- setRect buffer 0 (MkFRect 4 4 8 8) | False => Left <$> getError
  True <- drawRects renderer buffer 1 | False => Left <$> getError
  True <- setRect buffer 0 (MkFRect 16 16 8 8) | False => Left <$> getError
  True <- fillRects renderer buffer 1 | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 4 8 128 128 128 255 1) | _ => pure (Left "Batched outline blending failed")
  1 <- primIO (prim__pixelNear window 18 18 128 128 128 255 1) | _ => pure (Left "Batched fill blending failed")
  True <- setDrawBlendMode renderer NoBlend | False => Left <$> getError
  pure (Right ())

anotherRenderer : RectBuffer -> IO (Either String ())
anotherRenderer buffer = withWindow "rectangle buffer reuse" 16 16 hidden $ \window =>
  withRenderer window $ \renderer => do
    Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
    Right () <- background renderer | Left err => pure (Left err)
    True <- setRect buffer 0 (MkFRect 2 3 4 6) | False => Left <$> getError
    True <- fillRects renderer buffer 1 | False => Left <$> getError
    pixel identifier 3 5 255

releasedInput : Bits32 -> Renderer -> IO (Either String ())
releasedInput window renderer = do
  Right () <- background renderer | Left err => pure (Left err)
  result <- withRectBuffer 1 $ \buffer => do
    True <- setRect buffer 0 (MkFRect 4 4 8 8) | False => Left <$> getError
    True <- drawRects renderer buffer 1 | False => Left <$> getError
    pure (Right (the Bits64 0x100000002))
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Rectangle scope changed its callback result") else do
    Right () <- pixel window 4 8 255 | Left err => pure (Left err)
    Left "rectangle scope failed" <- withRectBuffer 1 (\buffer => do
      True <- setRect buffer 0 (MkFRect 16 16 8 8) | False => Left <$> getError
      True <- fillRects renderer buffer 1 | False => Left <$> getError
      pure (the (Either String ()) (Left "rectangle scope failed")))
      | _ => pure (Left "Rectangle scope changed its callback error")
    pixel window 18 18 255

reset : Renderer -> IO Bool
reset renderer = do
  viewport <- setRenderViewport renderer Nothing
  clip <- setRenderClipRect renderer Nothing
  scale <- setRenderScale renderer 1 1
  blend <- setDrawBlendMode renderer NoBlend
  logical <- setRenderLogicalPresentation renderer 0 0 PresentationDisabled
  pure (viewport && clip && scale && blend && logical)

export
rectBatchTests : Window -> Renderer -> IO (Either String ())
rectBatchTests window renderer = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Right () <- rejectedCapacity | Left err => pure (Left err)
  True <- reset renderer | False => Left <$> getError
  result <- withRectBuffer 3 $ \buffer => do
    Right () <- background renderer | Left err => pure (Left err)
    True <- fillRects renderer buffer 3 | False => Left <$> getError
    Right () <- pixel identifier 0 0 0 | Left err => pure (Left err)
    Right () <- outlinesAndFills identifier renderer buffer | Left err => pure (Left err)
    Right () <- clipped identifier renderer buffer | Left err => pure (Left err)
    Right () <- scaled identifier renderer buffer | Left err => pure (Left err)
    Right () <- blended identifier renderer buffer | Left err => pure (Left err)
    Right () <- anotherRenderer buffer | Left err => pure (Left err)
    Right () <- withTargetTexture renderer 32 32 (\texture =>
      withRenderTarget renderer (Just texture) (outlinesAndFills identifier renderer buffer))
      | Left err => pure (Left err)
    releasedInput identifier renderer
  restored <- reset renderer
  Right () <- pure result | Left err => pure (Left err)
  if restored then pure (Right ()) else pure (Left "Cannot restore state after rectangle batch tests")
