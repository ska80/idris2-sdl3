module StreamingTests

import Data.Buffer
import SDL3

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> IO Bool
pixel window x y r g b = (== 1) <$> primIO (prim__pixel window x y r g b 255)

-- Callers use known pixel positions within their test buffers.
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

expectRegionFailure : Texture StreamingAccess -> Rect -> Buffer -> Int32 -> IO (Either String ())
expectRegionFailure texture rect buffer pitch = do
  False <- updateTextureRegionRGBA texture rect buffer pitch
    | True => pure (Left "Invalid partial upload was accepted")
  err <- getError
  if err == "" then pure (Left "Rejected partial upload produced no error") else pure (Right ())

invalidRegions : Texture StreamingAccess -> Buffer -> List Rect -> IO (Either String ())
invalidRegions texture buffer [] = pure (Right ())
invalidRegions texture buffer (rect :: rest) = do
  Right () <- expectRegionFailure texture rect buffer 12 | Left err => pure (Left err)
  invalidRegions texture buffer rest

invalidPartialUploads : Texture StreamingAccess -> Buffer -> IO (Either String ())
invalidPartialUploads texture buffer = do
  Right () <- invalidRegions texture buffer
    [ MkRect (-1) 0 1 1, MkRect 0 (-1) 1 1, MkRect 2 0 1 1, MkRect 0 2 1 1
    , MkRect 0 0 0 1, MkRect 0 0 1 0, MkRect 0 0 (-1) 1, MkRect 0 0 1 (-1)
    , MkRect 1 0 2 1, MkRect 0 1 1 2, MkRect (-2147483648) 0 1 1
    , MkRect 2147483647 0 2147483647 1, MkRect 0 2147483647 1 2147483647 ]
    | Left err => pure (Left err)
  Just short <- newBuffer 23 | Nothing => pure (Left "Cannot allocate short patch buffer")
  Right () <- expectRegionFailure texture (MkRect 1 0 1 2) short 12 | Left err => pure (Left err)
  Right () <- expectRegionFailure texture (MkRect 1 0 1 2) buffer 3 | Left err => pure (Left err)
  Right () <- expectRegionFailure texture (MkRect 1 0 1 2) buffer (-1) | Left err => pure (Left err)
  expectRegionFailure texture (MkRect 1 0 1 2) buffer 2147483647

partialPixels : Bits32 -> Renderer -> Texture StreamingAccess -> Buffer -> IO (Either String ())
partialPixels window renderer texture buffer = do
  writePixel buffer 0 180 20 190
  writePixel buffer 12 240 230 10
  True <- updateTextureRegionRGBA texture (MkRect 1 0 1 2) buffer 12 | False => Left <$> getError
  writePixel buffer 0 0 0 0
  Right () <- invalidPartialUploads texture buffer | Left err => pure (Left err)
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 16 0 255 255 | False => pure (Left "Partial upload changed pixels outside its rectangle")
  True <- pixel window 16 48 30 40 220 | False => pure (Left "Partial upload changed the other column")
  True <- pixel window 48 16 180 20 190 | False => pure (Left "Partial upload used the wrong source origin or retained its pointer")
  True <- pixel window 48 48 240 230 10 | False => pure (Left "Partial upload ignored source row pitch")
  Just single <- newBuffer 4 | Nothing => pure (Left "Cannot allocate single pixel buffer")
  writePixel single 0 5 15 25
  True <- updateTextureRegionRGBA texture (MkRect 0 1 1 1) single 4 | False => Left <$> getError
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  True <- pixel window 16 48 5 15 25 | False => pure (Left "Single pixel upload failed at the bottom edge")
  True <- pixel window 48 48 240 230 10 | False => pure (Left "Single pixel upload changed its neighbor")
  pure (Right ())

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
  partialPixels window renderer texture buffer

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
