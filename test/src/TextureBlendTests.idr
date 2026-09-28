module TextureBlendTests

import SDL3
import SDL3.Raw
import SDL3.Scoped
import Data.IORef
import System.File

%default covering

%foreign "C:idris_test_null_texture, libidris2_sdl3_test, fixtures.h"
prim__nullTexture : PrimIO NativeTexture

%foreign "C:idris_test_make_bmp, libidris2_sdl3_test, fixtures.h"
prim__makeBMP : PrimIO String

%foreign "C:idris_test_pixel_near, libidris2_sdl3_test, fixtures.h"
prim__pixelNear : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

expect : IO (Either String BlendMode) -> BlendMode -> IO (Either String ())
expect query expected = do
  Right actual <- query | Left err => pure (Left err)
  if actual == expected then pure (Right ()) else pure (Left "Texture blend query returned an incorrect mode")

roundTrips : Texture access -> List BlendMode -> IO (Either String ())
roundTrips texture [] = pure (Right ())
roundTrips texture (mode :: rest) = do
  True <- setTextureBlendMode texture mode | False => Left <$> getError
  Right actual <- getTextureBlendMode texture | Left err => pure (Left err)
  case actual of
    OtherBlendMode _ => pure (Left "A named blend code was not decoded to its constructor")
    _ => if actual == mode then roundTrips texture rest
            else pure (Left "Texture blend mode did not round-trip")

nested : Texture access -> IO (Either String ())
nested texture = do
  result <- withTextureBlendMode texture AdditiveBlend $ do
    Right () <- expect (getTextureBlendMode texture) AdditiveBlend | Left err => pure (Left err)
    Right value <- withTextureBlendMode texture NoBlend (do
      Right () <- expect (getTextureBlendMode texture) NoBlend | Left err => pure (Left err)
      pure (Right (the Bits64 0x100000002))) | Left err => pure (Left err)
    Right () <- expect (getTextureBlendMode texture) AdditiveBlend | Left err => pure (Left err)
    True <- setTextureAlphaMod texture 73 | False => Left <$> getError
    True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
    True <- setTextureBlendMode texture ModulateBlend | False => Left <$> getError
    pure (Right value)
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Blend scope changed its callback result") else do
    Right () <- expect (getTextureBlendMode texture) AlphaBlend | Left err => pure (Left err)
    Right 73 <- getTextureAlphaMod texture | _ => pure (Left "Blend scope restored unrelated alpha state")
    Right NearestScale <- getTextureScaleMode texture | _ => pure (Left "Blend scope restored unrelated filtering")
    pure (Right ())

rejected : Texture access -> Bits32 -> IO (Either String ())
rejected texture code = do
  called <- newIORef False
  result <- withTextureBlendMode texture (OtherBlendMode code) $ do
    writeIORef called True
    pure (Right ())
  ran <- readIORef called
  Left err <- pure result | Right () => pure (Left "Invalid blend code was accepted")
  if ran || err == "" then pure (Left "Failed blend selection ran its action or lost its error")
     else expect (getTextureBlendMode texture) AlphaBlend

scopeCases : Texture access -> IO (Either String ())
scopeCases texture = do
  Right () <- roundTrips texture [NoBlend, AlphaBlend, PremultipliedAlphaBlend, AdditiveBlend,
    PremultipliedAdditiveBlend, ModulateBlend, MultiplyBlend] | Left err => pure (Left err)
  let query = getTextureBlendMode texture
  True <- setTextureBlendMode texture NoBlend | False => Left <$> getError
  Right () <- expect query (OtherBlendMode 0) | Left err => pure (Left err)
  True <- setTextureBlendMode texture (OtherBlendMode 1) | False => Left <$> getError
  Right () <- expect query AlphaBlend | Left err => pure (Left err)
  Right () <- nested texture | Left err => pure (Left err)
  result <- withTextureBlendMode texture NoBlend (pure (the (Either String ()) (Left "blend action failed")))
  Left "blend action failed" <- pure result | _ => pure (Left "Blend scope changed its action error")
  Right () <- expect query AlphaBlend | Left err => pure (Left err)
  Right () <- rejected texture 0x7fffffff | Left err => pure (Left err)
  rejected texture 0xffffffff

renderedScope : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
renderedScope window renderer texture = do
  Right () <- withRenderTarget renderer (Just texture) (do
    True <- setDrawColor renderer 255 255 255 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  True <- setTextureAlphaMod texture 128 | False => Left <$> getError
  True <- setTextureBlendMode texture AdditiveBlend | False => Left <$> getError
  True <- setDrawColor renderer 40 40 40 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  Right () <- withTextureBlendMode texture AlphaBlend (do
    True <- renderTexture renderer texture (Just (MkFRect 4 4 8 8)) | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  True <- renderTexture renderer texture (Just (MkFRect 20 4 8 8)) | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 8 8 148 148 148 255 2) | _ => pure (Left "Scoped alpha blending produced an incorrect pixel")
  1 <- primIO (prim__pixelNear window 24 8 168 168 168 255 1) | _ => pure (Left "Additive blending was not restored")
  expect (getTextureBlendMode texture) AdditiveBlend

staticCases : Renderer -> IO (Either String ())
staticCases renderer = do
  path <- primIO prim__makeBMP
  if path == "" then Left <$> getError else do
    result <- withBMP path $ \surface => withTextureFromSurface renderer surface scopeCases
    removed <- removeFile path
    Right () <- pure result | Left err => pure (Left err)
    Right () <- pure removed | Left _ => pure (Left "Cannot remove blend test BMP")
    pure (Right ())

export
textureBlendTests : Window -> Renderer -> IO (Either String ())
textureBlendTests window renderer = do
  ptr <- primIO prim__nullTexture
  value <- primIO (prim__getTextureBlendMode ptr)
  if value /= -1 then pure (Left "Null blend query did not return its failure marker") else do
    err <- getError
    if err == "" then pure (Left "Null blend query lost its SDL error") else do
      Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
      Right () <- staticCases renderer | Left err => pure (Left err)
      withStreamingTexture renderer 1 1 $ \streaming => do
        Right () <- scopeCases streaming | Left err => pure (Left err)
        copied <- withTargetTexture renderer 8 8 $ \target => do
          Right () <- scopeCases target | Left err => pure (Left err)
          Right () <- renderedScope identifier renderer target | Left err => pure (Left err)
          Right () <- expect (getTextureBlendMode streaming) AlphaBlend | Left err => pure (Left err)
          getTextureBlendMode target
        expect (pure copied) AdditiveBlend
