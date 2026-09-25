module RenderTests

import SDL3

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

%foreign "C:idris_test_pixel_near, libidris2_sdl3_test, fixtures.h"
prim__pixelNear : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> IO Bool
pixel window x y r g b = (== 1) <$> primIO (prim__pixel window x y r g b 255)

setupArea : Renderer -> IO (Either String ())
setupArea renderer = do
  True <- setDrawBlendMode renderer NoBlend | False => Left <$> getError
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- setRenderViewport renderer (Just (MkRect 8 8 32 32)) | False => Left <$> getError
  True <- setRenderClipRect renderer (Just (MkRect 4 4 8 8)) | False => Left <$> getError
  True <- setDrawColor renderer 240 20 30 255 | False => Left <$> getError
  True <- fillRect renderer 0 0 32 32 | False => Left <$> getError
  pure (Right ())

resetArea : Renderer -> IO Bool
resetArea renderer = do
  viewport <- setRenderViewport renderer Nothing
  clip <- setRenderClipRect renderer Nothing
  pure (viewport && clip)

areaPixels : Bits32 -> Renderer -> IO (Either String ())
areaPixels window renderer = do
  Right () <- setupArea renderer | Left err => pure (Left err)
  -- Readback uses viewport coordinates. Reset before testing absolute positions.
  True <- resetArea renderer | False => Left <$> getError
  True <- pixel window 13 13 240 20 30 | False => pure (Left "Viewport or clip origin was incorrect")
  True <- pixel window 9 9 0 0 0 | False => pure (Left "Drawing escaped the clip rectangle")
  True <- pixel window 0 0 0 0 0 | False => pure (Left "Drawing escaped the viewport")
  pure (Right ())

targetState : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
targetState window renderer texture = do
  Right () <- setupArea renderer | Left err => pure (Left err)
  True <- setRenderTarget renderer (Just texture) | False => Left <$> getError
  True <- setDrawColor renderer 0 0 200 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- setDrawColor renderer 0 200 0 255 | False => Left <$> getError
  True <- fillRect renderer 0 0 4 4 | False => Left <$> getError
  True <- pixel window 2 2 0 200 0 | False => pure (Left "Texture target inherited the window drawing area")
  True <- setRenderTarget renderer Nothing | False => Left <$> getError
  True <- fillRect renderer 0 0 32 32 | False => Left <$> getError
  True <- resetArea renderer | False => Left <$> getError
  True <- pixel window 13 13 0 200 0 | False => pure (Left "Window drawing area was not restored")
  True <- pixel window 9 9 0 0 0 | False => pure (Left "Window clip state was not restored")
  pure (Right ())

emptyClip : Bits32 -> Renderer -> IO (Either String ())
emptyClip window renderer = do
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- setRenderClipRect renderer (Just (MkRect 0 0 0 0)) | False => Left <$> getError
  True <- setDrawColor renderer 200 0 0 255 | False => Left <$> getError
  True <- fillRect renderer 0 0 64 64 | False => Left <$> getError
  True <- setRenderClipRect renderer Nothing | False => Left <$> getError
  True <- pixel window 2 2 0 0 0 | False => pure (Left "Empty clip rectangle allowed drawing")
  True <- fillRect renderer 0 0 4 4 | False => Left <$> getError
  True <- pixel window 2 2 200 0 0 | False => pure (Left "Disabling clipping did not restore drawing")
  pure (Right ())

clearArea : Bits32 -> Renderer -> IO (Either String ())
clearArea window renderer = do
  Right () <- setupArea renderer | Left err => pure (Left err)
  True <- setDrawColor renderer 0 0 200 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- resetArea renderer | False => Left <$> getError
  True <- pixel window 0 0 0 0 200 | False => pure (Left "Clear did not ignore viewport and clip state")
  pure (Right ())

blendShapes : Bits32 -> Renderer -> IO (Either String ())
blendShapes window renderer = do
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- setDrawBlendMode renderer AlphaBlend | False => Left <$> getError
  True <- setDrawColor renderer 200 100 50 128 | False => Left <$> getError
  True <- fillRect renderer 0 0 16 16 | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 8 8 100 50 25 255 1)
    | _ => pure (Left "Shape alpha blending produced the wrong pixel")
  True <- setDrawBlendMode renderer NoBlend | False => Left <$> getError
  True <- setDrawColor renderer 0 200 0 255 | False => Left <$> getError
  True <- fillRect renderer 16 16 16 16 | False => Left <$> getError
  True <- pixel window 20 20 0 200 0 | False => pure (Left "Shape blend reset produced the wrong pixel")
  pure (Right ())

export
renderTests : Window -> Renderer -> IO (Either String ())
renderTests window renderer = do
  False <- setRenderViewport renderer (Just (MkRect 0 0 (-1) 16))
    | True => pure (Left "Negative viewport width was accepted")
  err <- getError
  if err == "" then pure (Left "Invalid viewport produced no error") else do
    True <- resetArea renderer | False => Left <$> getError
    Right (MkWindowID identifier) <- getWindowID window | Left message => pure (Left message)
    Right texture <- createTargetTexture renderer 16 16 | Left message => pure (Left message)
    result <- do
      Right () <- areaPixels identifier renderer | Left message => pure (Left message)
      Right () <- targetState identifier renderer texture | Left message => pure (Left message)
      Right () <- emptyClip identifier renderer | Left message => pure (Left message)
      Right () <- clearArea identifier renderer | Left message => pure (Left message)
      blendShapes identifier renderer
    target <- setRenderTarget renderer Nothing
    area <- resetArea renderer
    blend <- setDrawBlendMode renderer NoBlend
    destroyTexture texture
    if target && area && blend then pure result else pure (Left "Cannot restore renderer state after tests")
