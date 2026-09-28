module TextureAlphaTests

import SDL3
import SDL3.Raw
import SDL3.Scoped
import System.File

%default covering

%foreign "C:idris_test_null_texture, libidris2_sdl3_test, fixtures.h"
prim__nullTexture : PrimIO NativeTexture

%foreign "C:idris_test_make_bmp, libidris2_sdl3_test, fixtures.h"
prim__makeBMP : PrimIO String

%foreign "C:idris_test_pixel_near, libidris2_sdl3_test, fixtures.h"
prim__pixelNear : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

expect : IO (Either String Bits8) -> Bits8 -> IO (Either String ())
expect query expected = do
  Right actual <- query | Left err => pure (Left err)
  if actual == expected then pure (Right ()) else pure (Left "Texture alpha query returned an incorrect value")

allBytes : Texture access -> Nat -> IO (Either String ())
allBytes texture Z = pure (Right ())
allBytes texture (S remaining) = do
  let alpha : Bits8 = cast remaining
  True <- setTextureAlphaMod texture alpha | False => Left <$> getError
  Right () <- expect (getTextureAlphaMod texture) alpha | Left err => pure (Left err)
  allBytes texture remaining

nested : Texture access -> IO (Either String ())
nested texture = do
  True <- setTextureAlphaMod texture 91 | False => Left <$> getError
  result <- withTextureAlphaMod texture 128 $ do
    Right () <- expect (getTextureAlphaMod texture) 128 | Left err => pure (Left err)
    Right value <- withTextureAlphaMod texture 0 (do
      Right () <- expect (getTextureAlphaMod texture) 0 | Left err => pure (Left err)
      pure (Right (the Bits64 0x100000002))) | Left err => pure (Left err)
    Right () <- expect (getTextureAlphaMod texture) 128 | Left err => pure (Left err)
    -- The outer scope must restore its entry value, not the action's last value.
    True <- setTextureAlphaMod texture 17 | False => Left <$> getError
    pure (Right value)
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Alpha scope changed its callback result")
     else expect (getTextureAlphaMod texture) 91

failedAction : Texture access -> IO (Either String ())
failedAction texture = do
  result <- withTextureAlphaMod texture 200 $ do
    inner <- withTextureAlphaMod texture 5 (pure (the (Either String ()) (Left "inner alpha action failed")))
    Left "inner alpha action failed" <- pure inner | _ => pure (Left "Inner alpha error changed")
    Right () <- expect (getTextureAlphaMod texture) 200 | Left err => pure (Left err)
    pure (the (Either String ()) (Left "outer alpha action failed"))
  Left "outer alpha action failed" <- pure result | _ => pure (Left "Outer alpha error changed")
  Right () <- expect (getTextureAlphaMod texture) 91 | Left err => pure (Left err)
  withTextureAlphaMod texture 91 (expect (getTextureAlphaMod texture) 91)

scopeCases : Texture access -> IO (Either String ())
scopeCases texture = do
  let query = getTextureAlphaMod texture
  Right () <- expect query 255 | Left err => pure (Left err)
  True <- setTextureAlphaMod texture 0 | False => Left <$> getError
  Right () <- expect query 0 | Left err => pure (Left err)
  True <- setTextureAlphaMod texture 255 | False => Left <$> getError
  Right () <- expect query 255 | Left err => pure (Left err)
  Right () <- nested texture | Left err => pure (Left err)
  failedAction texture

renderedScope : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
renderedScope window renderer texture = do
  Right () <- withRenderTarget renderer (Just texture) (do
    True <- setDrawColor renderer 255 255 255 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  True <- setTextureBlendMode texture AlphaBlend | False => Left <$> getError
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  Right () <- withTextureAlphaMod texture 128 (do
    True <- setTextureColorMod texture 255 0 0 | False => Left <$> getError
    True <- renderTexture renderer texture (Just (MkFRect 4 4 8 8)) | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  -- Alpha returns to 91, but the red color modulation is not restored.
  True <- renderTexture renderer texture (Just (MkFRect 20 4 8 8)) | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 8 8 128 0 0 255 1) | _ => pure (Left "Scoped alpha did not affect drawing")
  1 <- primIO (prim__pixelNear window 24 8 91 0 0 255 1) | _ => pure (Left "Alpha restoration changed unrelated texture state")
  expect (getTextureAlphaMod texture) 91

staticCases : Renderer -> IO (Either String ())
staticCases renderer = do
  path <- primIO prim__makeBMP
  if path == "" then Left <$> getError else do
    result <- withBMP path $ \surface => withTextureFromSurface renderer surface scopeCases
    removed <- removeFile path
    Right () <- pure result | Left err => pure (Left err)
    Right () <- pure removed | Left _ => pure (Left "Cannot remove alpha test BMP")
    pure (Right ())

export
textureAlphaTests : Window -> Renderer -> IO (Either String ())
textureAlphaTests window renderer = do
  ptr <- primIO prim__nullTexture
  -1 <- primIO (prim__getTextureAlphaMod ptr) | _ => pure (Left "Null alpha query did not fail")
  err <- getError
  if err == "" then pure (Left "Null alpha query lost its SDL error") else do
    Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
    Right () <- staticCases renderer | Left err => pure (Left err)
    withStreamingTexture renderer 1 1 $ \streaming => do
      Right () <- scopeCases streaming | Left err => pure (Left err)
      Right () <- allBytes streaming 256 | Left err => pure (Left err)
      copied <- withTargetTexture renderer 8 8 $ \target => do
        Right () <- scopeCases target | Left err => pure (Left err)
        Right () <- renderedScope identifier renderer target | Left err => pure (Left err)
        Right () <- expect (getTextureAlphaMod streaming) 0 | Left err => pure (Left err)
        getTextureAlphaMod target
      expect (pure copied) 91
