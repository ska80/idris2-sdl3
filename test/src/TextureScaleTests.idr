module TextureScaleTests

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

expect : IO (Either String ScaleMode) -> ScaleMode -> IO (Either String ())
expect query expected = do
  Right actual <- query | Left err => pure (Left err)
  if actual == expected then pure (Right ()) else pure (Left "Texture filtering query returned an incorrect mode")

nested : Texture access -> IO (Either String ())
nested texture = do
  result <- withTextureScaleMode texture NearestScale $ do
    Right () <- expect (getTextureScaleMode texture) NearestScale | Left err => pure (Left err)
    Right value <- withTextureScaleMode texture LinearScale (do
      Right () <- expect (getTextureScaleMode texture) LinearScale | Left err => pure (Left err)
      pure (Right (the Bits64 0x100000002))) | Left err => pure (Left err)
    Right () <- expect (getTextureScaleMode texture) NearestScale | Left err => pure (Left err)
    True <- setTextureAlphaMod texture 73 | False => Left <$> getError
    pure (Right value)
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Filtering scope changed its callback result") else do
    Right () <- expect (getTextureScaleMode texture) LinearScale | Left err => pure (Left err)
    Right 73 <- getTextureAlphaMod texture | _ => pure (Left "Filtering scope restored unrelated alpha state")
    True <- setTextureAlphaMod texture 255 | False => Left <$> getError
    pure (Right ())

failures : Texture access -> IO (Either String ())
failures texture = do
  failed <- withTextureScaleMode texture NearestScale $ do
    True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
    pure (the (Either String ()) (Left "filtering action failed"))
  Left "filtering action failed" <- pure failed | _ => pure (Left "Filtering scope changed the action error")
  Right () <- expect (getTextureScaleMode texture) LinearScale | Left err => pure (Left err)
  called <- newIORef False
  rejected <- withTextureScaleMode texture (OtherScaleMode (-1)) $ do
    writeIORef called True
    pure (Right ())
  ran <- readIORef called
  Left err <- pure rejected | Right () => pure (Left "Invalid filtering mode was accepted")
  if ran || err == "" then pure (Left "Failed filtering selection ran the action or lost its error")
     else expect (getTextureScaleMode texture) LinearScale

newerMode : Texture access -> IO (Either String ())
newerMode texture = do
  -- Code 2 is SDL 3.4 pixel-art filtering. Older runtimes can reject it.
  selected <- setTextureScaleMode texture (OtherScaleMode 2)
  case selected of
    False => do
      err <- getError
      True <- setTextureScaleMode texture LinearScale | False => Left <$> getError
      if err == "" then pure (Left "Unsupported filtering mode lost its error") else pure (Right ())
    True => do
      Right saved <- getTextureScaleMode texture | Left err => pure (Left err)
      Right () <- withTextureScaleMode texture NearestScale
        (expect (getTextureScaleMode texture) NearestScale) | Left err => pure (Left err)
      -- SDL can select the closest supported mode. Preserve the actual reported code.
      Right () <- expect (getTextureScaleMode texture) saved | Left err => pure (Left err)
      True <- setTextureScaleMode texture LinearScale | False => Left <$> getError
      pure (Right ())

scopeCases : Texture access -> IO (Either String ())
scopeCases texture = do
  let query = getTextureScaleMode texture
  Right () <- expect query LinearScale | Left err => pure (Left err)
  True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
  Right () <- expect query (OtherScaleMode 0) | Left err => pure (Left err)
  True <- setTextureScaleMode texture (OtherScaleMode 1) | False => Left <$> getError
  Right () <- expect query (OtherScaleMode 1) | Left err => pure (Left err)
  Right () <- nested texture | Left err => pure (Left err)
  Right () <- failures texture | Left err => pure (Left err)
  newerMode texture

renderedScope : Bits32 -> Renderer -> Texture StaticAccess -> IO (Either String ())
renderedScope window renderer texture = do
  True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
  Right () <- withTextureScaleMode texture LinearScale (do
    True <- renderTexture renderer texture Nothing | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  -- Read after restoration: queued drawing must still use the scoped filtering mode.
  1 <- primIO (prim__pixelNear window 31 32 133 109 49 255 2) | _ => pure (Left "Scoped linear filtering produced an incorrect pixel")
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 31 32 220 30 40 255 0) | _ => pure (Left "Nearest filtering was not restored")
  expect (getTextureScaleMode texture) NearestScale

staticCases : Bits32 -> Renderer -> IO (Either String ())
staticCases window renderer = do
  path <- primIO prim__makeBMP
  if path == "" then Left <$> getError else do
    result <- withBMP path $ \surface => withTextureFromSurface renderer surface $ \texture => do
      Right () <- scopeCases texture | Left err => pure (Left err)
      renderedScope window renderer texture
    removed <- removeFile path
    Right () <- pure result | Left err => pure (Left err)
    Right () <- pure removed | Left _ => pure (Left "Cannot remove filtering test BMP")
    pure (Right ())

export
textureScaleTests : Window -> Renderer -> IO (Either String ())
textureScaleTests window renderer = do
  ptr <- primIO prim__nullTexture
  value <- primIO (prim__getTextureScaleMode ptr)
  if value /= -2147483649 then pure (Left "Null filtering query did not return its failure marker") else do
    err <- getError
    if err == "" then pure (Left "Null filtering query lost its SDL error") else do
      Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
      Right () <- staticCases identifier renderer | Left err => pure (Left err)
      withStreamingTexture renderer 1 1 $ \streaming => do
        Right () <- scopeCases streaming | Left err => pure (Left err)
        copied <- withTargetTexture renderer 8 8 $ \target => do
          Right () <- scopeCases target | Left err => pure (Left err)
          Right () <- expect (getTextureScaleMode streaming) LinearScale | Left err => pure (Left err)
          getTextureScaleMode target
        expect (pure copied) LinearScale
