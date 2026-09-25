module StreamingTests

import Data.Buffer
import SDL3

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> IO Bool
pixel window x y r g b = (== 1) <$> primIO (prim__pixel window x y r g b 255)

-- All offsets below refer to known positions in a 24-byte test buffer.
writePixel : Buffer -> Int -> Bits8 -> Bits8 -> Bits8 -> IO ()
writePixel buffer offset r g b = do
  setBits8 buffer offset r
  setBits8 buffer (offset + 1) g
  setBits8 buffer (offset + 2) b
  setBits8 buffer (offset + 3) 255

expectFailure : Texture StreamingAccess -> Buffer -> Int32 -> IO (Either String ())
expectFailure texture buffer pitch = do
  False <- updateTextureRGBA texture buffer pitch | True => pure (Left "Invalid texture upload was accepted")
  err <- getError
  if err == "" then pure (Left "Rejected texture upload produced no error") else pure (Right ())

overflowUpload : Renderer -> Buffer -> IO (Either String ())
overflowUpload renderer buffer = do
  Right texture <- createStreamingTexture renderer 2 3 | Left err => pure (Left err)
  -- 1431655766 * 3 is 4294967298, which would wrap to 2 in unsigned 32-bit arithmetic.
  result <- expectFailure texture buffer 1431655766
  destroyTexture texture
  pure result

invalidUploads : Renderer -> Texture StreamingAccess -> Buffer -> IO (Either String ())
invalidUploads renderer texture buffer = do
  Just short <- newBuffer 23 | Nothing => pure (Left "Cannot allocate short test buffer")
  Just empty <- newBuffer 0 | Nothing => pure (Left "Cannot allocate empty test buffer")
  Right () <- expectFailure texture short 12 | Left err => pure (Left err)
  Right () <- expectFailure texture empty 12 | Left err => pure (Left err)
  Right () <- expectFailure texture buffer 0 | Left err => pure (Left err)
  Right () <- expectFailure texture buffer (-1) | Left err => pure (Left err)
  Right () <- expectFailure texture buffer 7 | Left err => pure (Left err)
  Right () <- expectFailure texture buffer 2147483647 | Left err => pure (Left err)
  overflowUpload renderer buffer

uploadedPixels : Bits32 -> Renderer -> Texture StreamingAccess -> Buffer -> IO (Either String ())
uploadedPixels window renderer texture buffer = do
  True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
  True <- updateTextureRGBA texture buffer 12 | False => Left <$> getError
  -- SDL must consume the bytes during upload, not retain the source pointer.
  writePixel buffer 0 0 255 255
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 16 220 30 40 | False => pure (Left "Upload retained the source buffer")
  True <- pixel window 48 16 20 210 60 | False => pure (Left "RGBA byte order was incorrect")
  True <- pixel window 16 48 30 40 220 | False => pure (Left "Upload ignored row pitch")
  True <- pixel window 48 48 200 180 160 | False => pure (Left "Last uploaded pixel was incorrect")
  Right () <- invalidUploads renderer texture buffer | Left err => pure (Left err)
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 16 220 30 40 | False => pure (Left "Rejected upload changed texture contents")
  True <- updateTextureRGBA texture buffer 12 | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 16 0 255 255 | False => pure (Left "Reusing the upload buffer did not update the texture")
  pure (Right ())

export
streamingTests : Window -> Renderer -> IO (Either String ())
streamingTests window renderer = do
  Left _ <- createStreamingTexture renderer 0 2
    | Right texture => do
        destroyTexture texture
        pure (Left "Zero streaming texture width was accepted")
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Just buffer <- newBuffer 24 | Nothing => pure (Left "Cannot allocate upload buffer")
  writePixel buffer 0 220 30 40
  writePixel buffer 4 20 210 60
  setBits32 buffer 8 0x11223344
  writePixel buffer 12 30 40 220
  writePixel buffer 16 200 180 160
  setBits32 buffer 20 0x55667788
  Right texture <- createStreamingTexture renderer 2 2 | Left err => pure (Left err)
  result <- uploadedPixels identifier renderer texture buffer
  destroyTexture texture
  pure result
