module TextureTests

import SDL3
import SDL3.Scoped
import System.File

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> IO Bool
pixel window x y r g b = (== 1) <$> primIO (prim__pixel window x y r g b 255)

%foreign "C:idris_test_make_bmp, libidris2_sdl3_test, fixtures.h"
prim__makeBMP : PrimIO String

drawImage : Bits32 -> Renderer -> Texture StaticAccess -> IO (Either String ())
drawImage window renderer texture = do
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 32 220 30 40 | False => pure (Left "BMP left color was incorrect")
  True <- pixel window 48 32 20 210 60 | False => pure (Left "BMP right color was incorrect")
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTextureRegion renderer texture (MkFRect 4 0 4 4) (Just (MkFRect 8 8 16 24))
    | False => Left <$> getError
  True <- pixel window 16 16 20 210 60 | False => pure (Left "Source rectangle selected the wrong pixels")
  True <- pixel window 0 0 0 0 0 | False => pure (Left "Sprite drawing changed pixels outside its destination")
  True <- renderTextureRegion renderer texture (MkFRect 0 0 4 4) Nothing
    | False => Left <$> getError
  True <- pixel window 32 32 220 30 40 | False => pure (Left "Source rectangle with default destination was incorrect")
  pure (Right ())

%foreign "C:idris_test_pixel_near, libidris2_sdl3_test, fixtures.h"
prim__pixelNear : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

blendCases : Bits32 -> Renderer -> Texture access ->
             List (BlendMode, (Bits8, Bits8, Bits8), (Bits8, Bits8, Bits8)) -> IO (Either String ())
blendCases window renderer texture [] = pure (Right ())
blendCases window renderer texture ((mode, (br, bg, bb), (r, g, b)) :: rest) = do
  True <- setTextureBlendMode texture mode | False => Left <$> getError
  True <- setDrawColor renderer br bg bb 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 32 r g b | False => pure (Left "Texture blend mode produced the wrong pixel")
  blendCases window renderer texture rest

colorControls : Bits32 -> Renderer -> Texture StaticAccess -> IO (Either String ())
colorControls window renderer texture = do
  True <- setTextureBlendMode texture NoBlend | False => Left <$> getError
  True <- setTextureColorMod texture 0 255 0 | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 32 0 30 0 | False => pure (Left "Texture color modulation was incorrect")
  True <- setTextureColorMod texture 255 255 255 | False => Left <$> getError
  pure (Right ())

alphaControls : Bits32 -> Renderer -> Texture StaticAccess -> IO (Either String ())
alphaControls window renderer texture = do
  True <- setTextureBlendMode texture AlphaBlend | False => Left <$> getError
  True <- setTextureAlphaMod texture 0 | False => Left <$> getError
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 32 0 0 0 | False => pure (Left "Zero opacity changed the destination")
  True <- setTextureAlphaMod texture 128 | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 16 32 110 15 20 255 1)
    | _ => pure (Left "Half opacity produced the wrong pixel")
  pure (Right ())

premultipliedControls : Bits32 -> Renderer -> Texture StaticAccess -> IO (Either String ())
premultipliedControls window renderer texture = do
  -- Premultiplied pixels need matching RGB and alpha modulation when fading.
  True <- setTextureColorMod texture 128 128 128 | False => Left <$> getError
  True <- setTextureBlendMode texture PremultipliedAlphaBlend | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 16 32 110 15 20 255 1)
    | _ => pure (Left "Premultiplied alpha blending was incorrect")
  True <- setTextureBlendMode texture PremultipliedAdditiveBlend | False => Left <$> getError
  True <- setDrawColor renderer 10 20 30 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 16 32 120 35 50 255 1)
    | _ => pure (Left "Premultiplied additive blending was incorrect")
  pure (Right ())

scaleControls : Bits32 -> Renderer -> Texture StaticAccess -> IO (Either String ())
scaleControls window renderer texture = do
  True <- setTextureColorMod texture 255 255 255 | False => Left <$> getError
  True <- setTextureAlphaMod texture 255 | False => Left <$> getError
  True <- setTextureBlendMode texture AlphaBlend | False => Left <$> getError
  True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 31 32 220 30 40 | False => pure (Left "Nearest filtering mixed source colors")
  True <- setTextureScaleMode texture LinearScale | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 31 32 133 109 49 255 2)
    | _ => pure (Left "Linear filtering did not interpolate source colors")
  pure (Right ())

textureControls : Bits32 -> Renderer -> Texture StaticAccess -> IO (Either String ())
textureControls window renderer texture = do
  Right () <- blendCases window renderer texture
    [ (NoBlend, (10, 20, 30), (220, 30, 40))
    , (AlphaBlend, (10, 20, 30), (220, 30, 40))
    , (PremultipliedAlphaBlend, (10, 20, 30), (220, 30, 40))
    , (AdditiveBlend, (10, 20, 30), (230, 50, 70))
    , (PremultipliedAdditiveBlend, (10, 20, 30), (230, 50, 70))
    , (ModulateBlend, (255, 255, 255), (220, 30, 40))
    , (MultiplyBlend, (255, 255, 255), (220, 30, 40)) ]
    | Left err => pure (Left err)
  Right () <- colorControls window renderer texture | Left err => pure (Left err)
  Right () <- alphaControls window renderer texture | Left err => pure (Left err)
  Right () <- premultipliedControls window renderer texture | Left err => pure (Left err)
  scaleControls window renderer texture

bmpFile : Bits32 -> Renderer -> String -> IO (Either String ())
bmpFile window renderer path = do
  Left "surface callback failure" <- withBMP path (\_ => pure (the (Either String ()) (Left "surface callback failure")))
    | _ => pure (Left "Scoped surface lost the callback error")
  Right texture <- withBMP path (createTextureFromSurface renderer) | Left err => pure (Left err)
  -- Pixel tests must pass after the source surface is destroyed.
  result <- do
    Right () <- drawImage window renderer texture | Left err => pure (Left err)
    textureControls window renderer texture
  destroyTexture texture
  Right () <- pure result | Left err => pure (Left err)
  Right () <- writeFile path "not a BMP image" | Left _ => pure (Left "Cannot write invalid BMP fixture")
  Left err <- loadBMP path
    | Right surface => do
        destroySurface surface
        pure (Left "Invalid BMP data was accepted")
  if err == "" then pure (Left "Invalid BMP data produced no error") else pure (Right ())

bmpTests : Bits32 -> Renderer -> IO (Either String ())
bmpTests window renderer = do
  path <- primIO prim__makeBMP
  if path == "" then pure (Left "Cannot create BMP fixture") else do
    result <- bmpFile window renderer path
    removed <- removeFile path
    Right () <- pure result | Left err => pure (Left err)
    Right () <- pure removed | Left _ => pure (Left "Cannot remove BMP fixture")
    Left err <- withBMP path (\_ => pure (Right ()))
      | Right () => pure (Left "Missing BMP file was accepted")
    if err == "" then pure (Left "Missing BMP file produced no error") else pure (Right ())

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
  Right () <- bmpTests identifier renderer | Left err => pure (Left err)
  Right texture <- createTargetTexture renderer 16 16 | Left err => pure (Left err)
  result <- do
    Right () <- otherRenderer texture | Left err => pure (Left err)
    draw identifier renderer texture
  restored <- setRenderTarget renderer Nothing
  result <- if restored then pure result else Left <$> getError
  destroyTexture texture
  pure result
