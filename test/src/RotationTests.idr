module RotationTests

import SDL3
import SDL3.Scoped
import Data.Buffer

%default covering

RGB : Type
RGB = (Bits8, Bits8, Bits8)

Quad : Type
Quad = (RGB, RGB, RGB, RGB)

red, green, blue, yellow : RGB
red = (255, 0, 0)
green = (0, 255, 0)
blue = (0, 0, 255)
yellow = (255, 255, 0)

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> RGB -> IO (Either String ())
pixel window x y (r, g, b) = do
  1 <- primIO (prim__pixel window x y r g b 255)
    | _ => pure (Left "Rotated texture pixel was incorrect")
  pure (Right ())

quad : Bits32 -> Int -> Int -> Quad -> IO (Either String ())
quad window lo hi (tl, tr, bl, br) = do
  Right () <- pixel window lo lo tl | Left err => pure (Left err)
  Right () <- pixel window hi lo tr | Left err => pure (Left err)
  Right () <- pixel window lo hi bl | Left err => pure (Left err)
  pixel window hi hi br

background : Renderer -> IO (Either String ())
background renderer = do
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  pure (Right ())

transforms : Bits32 -> Renderer -> Texture StreamingAccess -> List (Double, TextureFlip, Quad) -> IO (Either String ())
transforms window renderer texture [] = pure (Right ())
transforms window renderer texture ((angle, flip, expected) :: rest) = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- renderTextureRotated renderer texture Nothing (Just (MkFRect 16 16 32 32)) angle Nothing flip
    | False => Left <$> getError
  Right () <- quad window 24 40 expected | Left err => pure (Left err)
  Right () <- pixel window 0 0 (0, 0, 0) | Left err => pure (Left err)
  transforms window renderer texture rest

sourceAndDestination : Bits32 -> Renderer -> Texture StreamingAccess -> IO (Either String ())
sourceAndDestination window renderer texture = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- renderTextureRotated renderer texture Nothing Nothing 0 Nothing NoFlip | False => Left <$> getError
  Right () <- quad window 16 48 (red, green, blue, yellow) | Left err => pure (Left err)
  True <- renderTextureRotated renderer texture (Just (MkFRect 0 0 1 2)) Nothing 0 Nothing NoFlip
    | False => Left <$> getError
  Right () <- quad window 16 48 (red, red, blue, blue) | Left err => pure (Left err)
  Right () <- background renderer | Left err => pure (Left err)
  True <- renderTextureRotated renderer texture (Just (MkFRect 0 0 1 2)) (Just (MkFRect 16 16 32 32)) 0 Nothing FlipVertical
    | False => Left <$> getError
  quad window 24 40 (blue, blue, red, red)

customCenter : Bits32 -> Renderer -> Texture StreamingAccess -> IO (Either String ())
customCenter window renderer texture = do
  Right () <- background renderer | Left err => pure (Left err)
  True <- renderTextureRotated renderer texture Nothing (Just (MkFRect 32 16 16 16)) 90 (Just (MkRotationCenter 0 0)) NoFlip
    | False => Left <$> getError
  -- Rotating around the destination's top-left moves the quad to its left.
  Right () <- quad window 20 28 (blue, red, yellow, green) | Left err => pure (Left err)
  Right () <- pixel window 40 20 (0, 0, 0) | Left err => pure (Left err)
  -- Exercise every option bit together, including the explicit source rectangle.
  True <- renderTextureRotated renderer texture (Just (MkFRect 0 0 2 2)) (Just (MkFRect 32 16 16 16))
    90 (Just (MkRotationCenter 0 0)) FlipBoth | False => Left <$> getError
  quad window 20 28 (green, yellow, red, blue)

export
rotationTests : Window -> Renderer -> IO (Either String ())
rotationTests window renderer = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Just pixels <- newBuffer 16 | Nothing => pure (Left "Cannot allocate rotation test pixels")
  -- setBits32 writes little-endian bytes, giving RGBA byte order on every host.
  setBits32 pixels 0 0xff0000ff
  setBits32 pixels 4 0xff00ff00
  setBits32 pixels 8 0xffff0000
  setBits32 pixels 12 0xff00ffff
  withStreamingTexture renderer 2 2 $ \texture => do
    True <- updateTextureRGBA texture pixels 8 | False => Left <$> getError
    True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
    True <- setTextureBlendMode texture NoBlend | False => Left <$> getError
    Right () <- transforms identifier renderer texture
      [ (0, NoFlip, (red, green, blue, yellow))
      , (0, FlipHorizontal, (green, red, yellow, blue))
      , (0, FlipVertical, (blue, yellow, red, green))
      , (0, FlipBoth, (yellow, blue, green, red))
      , (90, NoFlip, (blue, red, yellow, green))
      , (-90, NoFlip, (green, yellow, red, blue))
      , (180, NoFlip, (yellow, blue, green, red))
      , (90, FlipHorizontal, (yellow, green, blue, red)) ]
      | Left err => pure (Left err)
    Right () <- sourceAndDestination identifier renderer texture | Left err => pure (Left err)
    customCenter identifier renderer texture
