module TargetScopeTests

import SDL3
import SDL3.Scoped
import Data.IORef

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

color : Bits32 -> Bits8 -> Bits8 -> Bits8 -> IO (Either String ())
color window r g b = do
  1 <- primIO (prim__pixel window 4 4 r g b 255)
    | _ => pure (Left "Render target scope restored the wrong target")
  pure (Right ())

paint : Renderer -> Bits8 -> Bits8 -> Bits8 -> IO (Either String ())
paint renderer r g b = do
  True <- setDrawColor renderer r g b 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  pure (Right ())

rejectedSelection : Renderer -> IO (Either String ())
rejectedSelection renderer = withWindow "foreign target scope" 16 16 hidden $ \window =>
  withRenderer window $ \other => do
    Right texture <- createTargetTexture other 8 8 | Left err => pure (Left err)
    called <- newIORef False
    result <- withRenderTarget renderer (Just texture) $ do
      writeIORef called True
      pure (Right ())
    destroyTexture texture
    ran <- readIORef called
    Left err <- pure result | Right () => pure (Left "A target scope accepted another renderer's texture")
    if not ran && err /= "" then pure (Right ()) else pure (Left "Failed target selection ran the action or lost its error")

nestedSuccess : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String Bits64)
nestedSuccess window renderer inner = withRenderTarget renderer (Just inner) $ do
  Right () <- paint renderer 0 200 0 | Left err => pure (Left err)
  Right () <- withRenderTarget renderer Nothing (paint renderer 0 0 200) | Left err => pure (Left err)
  Right () <- color window 0 200 0 | Left err => pure (Left err)
  -- The outer scope must restore its saved target even if the action changes it.
  True <- setRenderTarget renderer Nothing | False => Left <$> getError
  pure (Right 0x100000002)

outerAction : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
outerAction window renderer inner = do
  Right () <- paint renderer 200 0 0 | Left err => pure (Left err)
  Right value <- nestedSuccess window renderer inner | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Target scope changed the action result") else do
    Right () <- color window 200 0 0 | Left err => pure (Left err)
    failed <- withRenderTarget renderer (Just inner) $ do
      Right () <- paint renderer 200 200 0 | Left err => pure (Left err)
      True <- setRenderTarget renderer Nothing | False => Left <$> getError
      pure (the (Either String ()) (Left "nested target failure"))
    Left "nested target failure" <- pure failed | _ => pure (Left "Target scope lost an action error")
    Right () <- color window 200 0 0 | Left err => pure (Left err)
    -- Draw color is deliberately not restored by a target-selection scope.
    True <- fillRect renderer 0 0 8 8 | False => Left <$> getError
    Right () <- color window 200 200 0 | Left err => pure (Left err)
    Right () <- rejectedSelection renderer | Left err => pure (Left err)
    color window 200 200 0

scopes : Bits32 -> Renderer -> Texture TargetAccess -> Texture TargetAccess -> IO (Either String ())
scopes window renderer outer inner = do
  Right () <- withRenderTarget renderer (Just outer) (outerAction window renderer inner)
    | Left err => pure (Left err)
  Right () <- color window 0 0 200 | Left err => pure (Left err)
  Left "outer target failure" <- withRenderTarget renderer (Just outer)
    (pure (the (Either String ()) (Left "outer target failure")))
    | _ => pure (Left "Outer target scope lost its error")
  color window 0 0 200

export
targetScopeTests : Window -> Renderer -> IO (Either String ())
targetScopeTests window renderer = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Right outer <- createTargetTexture renderer 8 8 | Left err => pure (Left err)
  result <- do
    Right inner <- createTargetTexture renderer 8 8 | Left err => pure (Left err)
    result <- scopes identifier renderer outer inner
    restored <- setRenderTarget renderer Nothing
    destroyTexture inner
    Right () <- pure result | Left err => pure (Left err)
    if restored then pure (Right ()) else Left <$> getError
  destroyTexture outer
  pure result
