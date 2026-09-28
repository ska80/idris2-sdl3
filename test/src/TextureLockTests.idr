module TextureLockTests

import Data.Buffer
import Data.IORef
import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO (Either String ())
pixel identifier x y r g b a = do
  1 <- primIO (prim__pixel identifier x y r g b a) | _ => pure (Left "Locked texture pixel was incorrect")
  pure (Right ())

writePixel : Buffer -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO ()
writePixel buffer offset r g b a = do
  setBits8 buffer offset r
  setBits8 buffer (offset + 1) g
  setBits8 buffer (offset + 2) b
  setBits8 buffer (offset + 3) a

invalidRegions : TextureLockBuffer -> Texture StreamingAccess -> List Rect -> IO (Either String ())
invalidRegions storage texture [] = pure (Right ())
invalidRegions storage texture (region :: rest) = do
  called <- newIORef False
  Left err <- withTextureLockRGBA storage texture (Just region) (\view => do
    writeIORef called True
    True <- fillLockedRGBA view 0 0 0 255 | False => Left <$> getError
    pure (Right ())) | Right () => pure (Left "Invalid lock region was accepted")
  False <- readIORef called | True => pure (Left "Failed lock ran its callback")
  if err == "" then pure (Left "Invalid lock region lost its SDL error")
     else invalidRegions storage texture rest

wholeLock : TextureLockBuffer -> Texture StreamingAccess -> IO (Either String ())
wholeLock storage texture = do
  result <- withTextureLockRGBA storage texture Nothing $ \view => do
    True <- fillLockedRGBA view 20 40 60 255 | False => Left <$> getError
    let MkSize w h = lockedRGBASize view
    if w /= 8 || h /= 5 || lockedRGBAPitch view < 32 then pure (Left "Whole lock metadata was incorrect") else do
      False <- setLockedPixelRGBA view (-1) 0 0 0 0 0 | True => pure (Left "Negative pixel coordinate was accepted")
      False <- setLockedPixelRGBA view 8 0 0 0 0 0 | True => pure (Left "Pixel outside lock was accepted")
      False <- setLockedPixelRGBA view 0 5 0 0 0 0 | True => pure (Left "Pixel outside lock height was accepted")
      called <- newIORef False
      Left _ <- withTextureLockRGBA storage texture Nothing (\nested => do
        writeIORef called True
        pure (Right ())) | Right () => pure (Left "Active lock storage was reused")
      False <- readIORef called | True => pure (Left "Nested lock ran its callback")
      True <- setLockedPixelRGBA view 0 0 90 80 70 255 | False => Left <$> getError
      pure (Right (the Bits64 0x100000002))
  if result == Right 0x100000002 then pure (Right ()) else pure (Left "Scoped lock lost its callback result")

partialLock : TextureLockBuffer -> Texture StreamingAccess -> IO (Either String (Size PixelUnits, Int32))
partialLock storage texture = do
  Just source <- newBuffer 24 | Nothing => pure (Left "Cannot allocate lock test pixels")
  Just short <- newBuffer 23 | Nothing => pure (Left "Cannot allocate short lock source")
  writePixel source 0 210 20 40 123
  writePixel source 4 30 180 50 255
  writePixel source 12 20 40 230 77
  writePixel source 16 220 190 10 255
  setBits32 source 8 0xabcdef01
  setBits32 source 20 0xabcdef01
  withTextureLockRGBA storage texture (Just (MkRect 6 3 2 2)) $ \view => do
    -- Initialize before testing failure paths: locks do not preserve old contents.
    True <- fillLockedRGBA view 1 2 3 255 | False => Left <$> getError
    False <- copyLockedRGBA view short 12 | True => pure (Left "Short lock source was accepted")
    False <- copyLockedRGBA view source 7 | True => pure (Left "Small source pitch was accepted")
    False <- copyLockedRGBA view source (-1) | True => pure (Left "Negative source pitch was accepted")
    True <- copyLockedRGBA view source 12 | False => Left <$> getError
    -- The copy must not retain the source bytes until unlock.
    writePixel source 0 0 0 0 0
    pure (Right (lockedRGBASize view, lockedRGBAPitch view))

rendered : Window -> Renderer -> Texture StreamingAccess -> IO (Either String ())
rendered window renderer texture = withTargetTexture renderer 8 5 $ \target =>
  withRenderTarget renderer (Just target) $ do
    Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
    True <- setTextureBlendMode texture NoBlend | False => Left <$> getError
    True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
    True <- renderTexture renderer texture Nothing | False => Left <$> getError
    Right () <- pixel identifier 0 0 90 80 70 255 | Left err => pure (Left err)
    Right () <- pixel identifier 5 4 20 40 60 255 | Left err => pure (Left err)
    Right () <- pixel identifier 0 4 20 40 60 255 | Left err => pure (Left err)
    Right () <- pixel identifier 6 3 210 20 40 123 | Left err => pure (Left err)
    Right () <- pixel identifier 7 3 30 180 50 255 | Left err => pure (Left err)
    Right () <- pixel identifier 6 4 20 40 230 77 | Left err => pure (Left err)
    pixel identifier 7 4 220 190 10 255

errorAndReuse : TextureLockBuffer -> Texture StreamingAccess -> IO (Either String ())
errorAndReuse storage texture = do
  failed <- withTextureLockRGBA storage texture Nothing $ \view => do
    True <- fillLockedRGBA view 11 22 33 255 | False => Left <$> getError
    pure (the (Either String ()) (Left "callback error"))
  Left "callback error" <- pure failed | _ => pure (Left "Lock scope lost the action error")
  -- A second acquisition with the same storage must succeed after Left cleanup.
  Right old <- lockTextureRGBA storage texture (Just (MkRect 0 0 1 1)) | Left err => pure (Left err)
  True <- fillLockedRGBA old 1 2 3 255 | False => Left <$> getError
  True <- unlockTextureRGBA old | False => Left <$> getError
  False <- setLockedPixelRGBA old 0 0 9 9 9 255 | True => pure (Left "Inactive view accepted a write")
  withTextureLockRGBA storage texture (Just (MkRect 0 0 1 1)) $ \view => do
    True <- fillLockedRGBA view 7 8 9 255 | False => Left <$> getError
    False <- fillLockedRGBA old 0 0 0 0 | True => pure (Left "Reused storage accepted a stale view")
    False <- unlockTextureRGBA old | True => pure (Left "Stale view unlocked a later acquisition")
    True <- setLockedPixelRGBA view 0 0 4 5 6 255 | False => Left <$> getError
    pure (Right ())

renderErrorChanges : Window -> Renderer -> Texture StreamingAccess -> IO (Either String ())
renderErrorChanges window renderer texture = withTargetTexture renderer 8 5 $ \target =>
  withRenderTarget renderer (Just target) $ do
    Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
    True <- renderTexture renderer texture Nothing | False => Left <$> getError
    Right () <- pixel identifier 0 0 4 5 6 255 | Left err => pure (Left err)
    pixel identifier 4 4 11 22 33 255

export
textureLockTests : Window -> Renderer -> IO (Either String ())
textureLockTests window renderer = do
  copied <- withStreamingTexture renderer 8 5 $ \texture =>
    withTextureLockBuffer $ \storage => do
      Right () <- invalidRegions storage texture [MkRect (-1) 0 1 1, MkRect 0 0 0 1,
                       MkRect 0 0 1 (-1), MkRect 7 4 2 1, MkRect 0 0 2147483647 1]
        | Left err => pure (Left err)
      Right () <- wholeLock storage texture | Left err => pure (Left err)
      Right metadata <- partialLock storage texture | Left err => pure (Left err)
      Right () <- rendered window renderer texture | Left err => pure (Left err)
      Right () <- errorAndReuse storage texture | Left err => pure (Left err)
      Right () <- renderErrorChanges window renderer texture | Left err => pure (Left err)
      -- Reuse the storage for another texture after unlocking the first one.
      Right () <- withStreamingTexture renderer 1 1 (\other =>
        withTextureLockRGBA storage other Nothing $ \view => do
          True <- fillLockedRGBA view 0 0 0 255 | False => Left <$> getError
          pure (Right ())) | Left err => pure (Left err)
      pure (Right metadata)
  Right (MkSize 2 2, pitch) <- pure copied | _ => pure (Left "Copied lock metadata changed after cleanup")
  if pitch >= 8 then pure (Right ()) else pure (Left "Copied lock pitch was incorrect")
