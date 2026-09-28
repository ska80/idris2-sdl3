module DrawBlendTests

import SDL3
import SDL3.Raw
import SDL3.Scoped
import Data.IORef
import System.FFI

%default covering

%foreign "C:idris_test_null_texture, libidris2_sdl3_test, fixtures.h"
prim__nullPointer : PrimIO AnyPtr

%foreign "C:idris_test_pixel_near, libidris2_sdl3_test, fixtures.h"
prim__pixelNear : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

expect : IO (Either String BlendMode) -> BlendMode -> IO (Either String ())
expect query expected = do
  Right actual <- query | Left err => pure (Left err)
  if actual == expected then pure (Right ()) else pure (Left "Draw blend query returned an incorrect mode")

roundTrips : Renderer -> List BlendMode -> IO (Either String ())
roundTrips renderer [] = pure (Right ())
roundTrips renderer (mode :: rest) = do
  True <- setDrawBlendMode renderer mode | False => Left <$> getError
  Right actual <- getDrawBlendMode renderer | Left err => pure (Left err)
  case actual of
    OtherBlendMode _ => pure (Left "A named draw blend mode was not decoded to its constructor")
    _ => if actual == mode then roundTrips renderer rest
            else pure (Left "Draw blend mode did not round-trip")

nested : Renderer -> IO (Either String ())
nested renderer = do
  True <- setDrawBlendMode renderer NoBlend | False => Left <$> getError
  let query = getDrawBlendMode renderer
  Right () <- expect query NoBlend | Left err => pure (Left err)
  result <- withDrawBlendMode renderer AlphaBlend $ do
    Right () <- expect query AlphaBlend | Left err => pure (Left err)
    Right value <- withDrawBlendMode renderer AdditiveBlend (do
      Right () <- expect query AdditiveBlend | Left err => pure (Left err)
      pure (Right (the Bits64 0x100000002))) | Left err => pure (Left err)
    Right () <- expect query AlphaBlend | Left err => pure (Left err)
    True <- setDrawBlendMode renderer ModulateBlend | False => Left <$> getError
    pure (Right value)
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Draw blend scope changed its action result")
     else expect query (OtherBlendMode 0)

failures : Renderer -> IO (Either String ())
failures renderer = do
  result <- withDrawBlendMode renderer AlphaBlend (pure (the (Either String ()) (Left "draw blend action failed")))
  Left "draw blend action failed" <- pure result | _ => pure (Left "Draw blend scope changed its action error")
  Right () <- expect (getDrawBlendMode renderer) NoBlend | Left err => pure (Left err)
  called <- newIORef False
  invalid <- withDrawBlendMode renderer (OtherBlendMode 0xffffffff) $ do
    writeIORef called True
    pure (Right ())
  ran <- readIORef called
  Left err <- pure invalid | Right () => pure (Left "Invalid draw blend code was accepted")
  if ran || err == "" then pure (Left "Failed draw blend selection ran its action or lost its error")
     else expect (getDrawBlendMode renderer) NoBlend

acrossTargets : Renderer -> IO (Either String ())
acrossTargets renderer = withTargetTexture renderer 8 8 $ \texture => do
  True <- setTextureBlendMode texture MultiplyBlend | False => Left <$> getError
  Right () <- withDrawBlendMode renderer AlphaBlend (do
    Right () <- withRenderTarget renderer (Just texture) (do
      Right () <- expect (getDrawBlendMode renderer) AlphaBlend | Left err => pure (Left err)
      True <- setDrawBlendMode renderer AdditiveBlend | False => Left <$> getError
      pure (Right ())) | Left err => pure (Left err)
    -- Target restoration does not restore draw blending: it belongs to the renderer.
    expect (getDrawBlendMode renderer) AdditiveBlend) | Left err => pure (Left err)
  Right () <- expect (getDrawBlendMode renderer) NoBlend | Left err => pure (Left err)
  expect (getTextureBlendMode texture) MultiplyBlend

anotherRenderer : Renderer -> IO (Either String ())
anotherRenderer renderer = do
  copied <- withWindow "draw blend isolation" 16 16 hidden $ \window =>
    withRenderer window $ \other => do
      True <- setDrawBlendMode other ModulateBlend | False => Left <$> getError
      Right () <- expect (getDrawBlendMode renderer) NoBlend | Left err => pure (Left err)
      getDrawBlendMode other
  expect (pure copied) ModulateBlend

renderedScope : Bits32 -> Renderer -> IO (Either String ())
renderedScope window renderer = withDrawBlendMode renderer AdditiveBlend $ do
  True <- setDrawColor renderer 40 40 40 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  Right () <- withDrawBlendMode renderer AlphaBlend (do
    True <- setDrawColor renderer 255 0 0 128 | False => Left <$> getError
    True <- fillRect renderer 4 4 8 8 | False => Left <$> getError
    pure (Right ())) | Left err => pure (Left err)
  -- The red drawing color remains, while blending returns to additive.
  True <- fillRect renderer 20 4 8 8 | False => Left <$> getError
  1 <- primIO (prim__pixelNear window 8 8 148 20 20 255 2) | _ => pure (Left "Scoped draw blending produced an incorrect pixel")
  1 <- primIO (prim__pixelNear window 24 8 168 40 40 255 1) | _ => pure (Left "Draw blend restoration changed the drawing color")
  expect (getDrawBlendMode renderer) AdditiveBlend

export
drawBlendTests : Window -> Renderer -> IO (Either String ())
drawBlendTests window renderer = do
  ptr <- primIO prim__nullPointer
  value <- primIO (prim__getDrawBlendMode ptr)
  if value /= -1 then pure (Left "Null draw blend query did not return its failure marker") else do
    err <- getError
    if err == "" then pure (Left "Null draw blend query lost its SDL error") else do
      Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
      withDrawBlendMode renderer NoBlend $ do
        Right () <- roundTrips renderer [NoBlend, AlphaBlend, PremultipliedAlphaBlend, AdditiveBlend,
          PremultipliedAdditiveBlend, ModulateBlend, MultiplyBlend] | Left err => pure (Left err)
        Right () <- nested renderer | Left err => pure (Left err)
        Right () <- failures renderer | Left err => pure (Left err)
        Right () <- acrossTargets renderer | Left err => pure (Left err)
        Right () <- anotherRenderer renderer | Left err => pure (Left err)
        renderedScope identifier renderer
