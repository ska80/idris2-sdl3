module TextureSizeTests

import SDL3
import SDL3.Raw
import SDL3.Scoped
import Data.Buffer
import System.FFI
import System.File

%default covering

%foreign "C:idris_test_texture_fields, libidris2_sdl3_test, fixtures.h"
prim__textureFields : Int32 -> Int32 -> PrimIO NativeTexture

%foreign "C:idris_test_null_texture, libidris2_sdl3_test, fixtures.h"
prim__nullTexture : PrimIO NativeTexture

%foreign "C:idris_test_make_bmp, libidris2_sdl3_test, fixtures.h"
prim__makeBMP : PrimIO String

checkFields : Int32 -> Int32 -> IO (Either String ())
checkFields width height = do
  -- This is not an SDL texture. Read the fabricated layout, but never call SDL with it.
  ptr <- primIO (prim__textureFields width height)
  let w : Int32 = getField ptr "w"
  let h : Int32 = getField ptr "h"
  let format : Bits32 = getField ptr "format"
  let refs : Int32 = getField ptr "refcount"
  if w == width && h == height && format == 0x89abcdef && refs == 42
     then pure (Right ()) else pure (Left "SDL_Texture public layout was incorrect")

layoutAndFailure : IO (Either String ())
layoutAndFailure = do
  Right () <- checkFields 0 0 | Left err => pure (Left err)
  Right () <- checkFields (-2147483648) 2147483647 | Left err => pure (Left err)
  Right () <- checkFields 2147483647 (-2147483648) | Left err => pure (Left err)
  ptr <- primIO prim__nullTexture
  1 <- primIO (prim__textureIsNull ptr) | _ => pure (Left "Typed null texture was not null")
  0 <- primIO (prim__getTextureSize ptr) | _ => pure (Left "Null texture size query succeeded")
  err <- getError
  if err /= "" then pure (Right ()) else pure (Left "Null texture query lost its SDL error")

expect : IO (Either String (Size PixelUnits)) -> Int32 -> Int32 -> IO (Either String ())
expect query width height = do
  Right (MkSize w h) <- query | Left err => pure (Left err)
  if w == width && h == height then pure (Right ())
     else pure (Left ("Expected texture size " ++ show width ++ "x" ++ show height ++ ", got " ++ show w ++ "x" ++ show h))

stateIndependent : Renderer -> Texture StreamingAccess -> IO (Either String ())
stateIndependent renderer streaming = withTargetTexture renderer 13 7 $ \target => do
  let query = getTextureSize target
  Right () <- expect query 13 7 | Left err => pure (Left err)
  withRenderTarget renderer (Just target) $ do
    True <- setRenderLogicalPresentation renderer 5 3 PresentationStretch | False => Left <$> getError
    True <- setRenderScale renderer 2 3 | False => Left <$> getError
    True <- setRenderViewport renderer (Just (MkRect 1 1 6 3)) | False => Left <$> getError
    True <- setRenderClipRect renderer (Just (MkRect 0 0 2 2)) | False => Left <$> getError
    Right () <- expect query 13 7 | Left err => pure (Left err)
    expect (getTextureSize streaming) 3 5

zeroBytes : Buffer -> Int -> IO ()
zeroBytes buffer 0 = pure ()
zeroBytes buffer count = do
  setBits8 buffer (count - 1) 0
  zeroBytes buffer (count - 1)

streamingSize : Renderer -> IO (Either String ())
streamingSize renderer = do
  copied <- withStreamingTexture renderer 3 5 $ \texture => do
    let query = getTextureSize texture
    Right initial <- query | Left err => pure (Left err)
    Just buffer <- newBuffer 60 | Nothing => pure (Left "Cannot allocate texture-size test pixels")
    zeroBytes buffer 60
    True <- updateTextureRGBA texture buffer 12 | False => Left <$> getError
    True <- setTextureColorMod texture 23 45 67 | False => Left <$> getError
    True <- setTextureAlphaMod texture 128 | False => Left <$> getError
    True <- setTextureScaleMode texture NearestScale | False => Left <$> getError
    Right () <- expect query 3 5 | Left err => pure (Left err)
    Right () <- stateIndependent renderer texture | Left err => pure (Left err)
    Right () <- expect query 3 5 | Left err => pure (Left err)
    pure (Right initial)
  -- Only the copied Idris record remains after destruction.
  expect (pure copied) 3 5

staticSize : Renderer -> IO (Either String ())
staticSize renderer = do
  path <- primIO prim__makeBMP
  if path == "" then Left <$> getError else do
    acquired <- withBMP path (createTextureFromSurface renderer)
    removed <- removeFile path
    Right texture <- pure acquired | Left err => pure (Left err)
    -- The source surface is already destroyed. The texture remains independently owned.
    copied <- getTextureSize texture
    destroyTexture texture
    Right () <- pure removed | Left _ => pure (Left "Cannot remove texture-size test BMP")
    expect (pure copied) 8 4

export
textureSizeTests : Renderer -> IO (Either String ())
textureSizeTests renderer = do
  Right () <- layoutAndFailure | Left err => pure (Left err)
  Right () <- streamingSize renderer | Left err => pure (Left err)
  Right () <- staticSize renderer | Left err => pure (Left err)
  copied <- withWindow "texture size lifetime" 16 16 hidden $ \window =>
    withRenderer window $ \temporary =>
      withTargetTexture temporary 7 9 getTextureSize
  -- The size also survives destruction of the creating renderer and window.
  expect (pure copied) 7 9
