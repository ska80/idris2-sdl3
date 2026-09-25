module TextureTests

import SDL3

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> IO Bool
pixel window x y r g b = (== 1) <$> primIO (prim__pixel window x y r g b 255)

draw : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
draw window renderer texture = do
  True <- setRenderTarget renderer (Just texture) | False => Left <$> getError
  True <- setDrawColor renderer 30 100 200 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- pixel window 4 4 30 100 200
    | False => pure (Left "Off-screen drawing produced the wrong pixel")
  True <- setRenderTarget renderer Nothing | False => Left <$> getError
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture (Just (MkFRect 8 8 32 32))
    | False => Left <$> getError
  True <- pixel window 16 16 30 100 200
    | False => pure (Left "Texture destination produced the wrong pixel")
  True <- pixel window 0 0 0 0 0
    | False => pure (Left "Texture drawing changed a pixel outside the destination")
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 0 0 30 100 200
    | False => pure (Left "Default texture destination did not cover the window")
  pure (Right ())

otherRenderer : Texture TargetAccess -> IO (Either String ())
otherRenderer texture = do
  Right window <- createWindow "texture ownership test" 16 16 hidden
    | Left err => pure (Left err)
  result <- do
    Right renderer <- createRenderer window | Left err => pure (Left err)
    targetAccepted <- setRenderTarget renderer (Just texture)
    restored <- setRenderTarget renderer Nothing
    drawAccepted <- renderTexture renderer texture Nothing
    destroyRenderer renderer
    if not targetAccepted && restored && not drawAccepted
       then pure (Right ())
       else pure (Left "A renderer accepted a texture from another renderer")
  destroyWindow window
  pure result

export
textureTests : Window -> Renderer -> IO (Either String ())
textureTests window renderer = do
  Left _ <- createTargetTexture renderer 0 16
    | Right texture => do
        destroyTexture texture
        pure (Left "Zero texture width was accepted")
  Left _ <- createTargetTexture renderer 16 (-1)
    | Right texture => do
        destroyTexture texture
        pure (Left "Negative texture height was accepted")
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Right texture <- createTargetTexture renderer 16 16 | Left err => pure (Left err)
  result <- do
    Right () <- otherRenderer texture | Left err => pure (Left err)
    draw identifier renderer texture
  restored <- setRenderTarget renderer Nothing
  result <- if restored then pure result else Left <$> getError
  destroyTexture texture
  pure result
