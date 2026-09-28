module TargetTextureScopeTests

import SDL3
import SDL3.Scoped
import Data.IORef

%default covering

%foreign "C:idris_test_watch_target, libidris2_sdl3_test, fixtures.h"
prim__watchTarget : Bits32 -> Int -> PrimIO Int

%foreign "C:idris_test_target_alive, libidris2_sdl3_test, fixtures.h"
prim__targetAlive : Int -> PrimIO Int

%foreign "C:idris_test_target_selected, libidris2_sdl3_test, fixtures.h"
prim__targetSelected : Bits32 -> Int -> PrimIO Int

watch : Bits32 -> Int -> IO (Either String ())
watch identifier slot = do
  1 <- primIO (prim__watchTarget identifier slot) | _ => Left <$> getError
  pure (Right ())

alive : Int -> Int -> IO (Either String ())
alive slot expected = do
  actual <- primIO (prim__targetAlive slot)
  if actual == expected then pure (Right ())
     else pure (Left "Target texture scope released a texture too early or too late")

selected : Bits32 -> Int -> IO (Either String ())
selected identifier slot = do
  1 <- primIO (prim__targetSelected identifier slot)
    | _ => pure (Left "Target texture ownership changed target selection")
  pure (Right ())

rejectedCreation : Renderer -> IO (Either String ())
rejectedCreation renderer = do
  called <- newIORef False
  result <- withTargetTexture renderer 0 8 $ \texture => do
    writeIORef called True
    pure (Right ())
  ran <- readIORef called
  Left err <- pure result | Right () => pure (Left "Invalid target texture dimensions were accepted")
  if not ran && err /= "" then pure (Right ())
     else pure (Left "Failed texture creation ran the callback or lost its error")

success : Bits32 -> Renderer -> IO (Either String ())
success identifier renderer = do
  result <- withTargetTexture renderer 8 8 $ \texture => do
    Right () <- selected identifier 0 | Left err => pure (Left err)
    withRenderTarget renderer (Just texture) $ do
      Right () <- watch identifier 1 | Left err => pure (Left err)
      Right () <- alive 1 1 | Left err => pure (Left err)
      pure (Right (the Bits64 0x100000002))
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Target texture scope changed the callback result") else do
    Right () <- alive 1 0 | Left err => pure (Left err)
    Right () <- alive 0 1 | Left err => pure (Left err)
    selected identifier 0

failure : Bits32 -> Renderer -> IO (Either String ())
failure identifier renderer = do
  result <- withTargetTexture renderer 8 8 $ \texture => do
    Right () <- selected identifier 0 | Left err => pure (Left err)
    withRenderTarget renderer (Just texture) $ do
      Right () <- watch identifier 2 | Left err => pure (Left err)
      Right () <- alive 2 1 | Left err => pure (Left err)
      pure (the (Either String ()) (Left "target texture callback failed"))
  Left "target texture callback failed" <- pure result
    | _ => pure (Left "Target texture scope changed the callback error")
  Right () <- alive 2 0 | Left err => pure (Left err)
  Right () <- alive 0 1 | Left err => pure (Left err)
  selected identifier 0

export
targetTextureScopeTests : Window -> Renderer -> IO (Either String ())
targetTextureScopeTests window renderer = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Right () <- selected identifier (-1) | Left err => pure (Left err)
  Right () <- withTargetTexture renderer 16 16 (\outer => do
    Right () <- selected identifier (-1) | Left err => pure (Left err)
    withRenderTarget renderer (Just outer) $ do
      Right () <- watch identifier 0 | Left err => pure (Left err)
      Right () <- success identifier renderer | Left err => pure (Left err)
      Right () <- failure identifier renderer | Left err => pure (Left err)
      Right () <- rejectedCreation renderer | Left err => pure (Left err)
      Right () <- alive 0 1 | Left err => pure (Left err)
      selected identifier 0) | Left err => pure (Left err)
  Right () <- alive 0 0 | Left err => pure (Left err)
  selected identifier (-1)
