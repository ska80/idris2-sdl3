module ScopedTests

import SDL3
import SDL3.Scoped
import Data.IORef

%default covering

%foreign "C:idris_test_window_state, libidris2_sdl3_test, fixtures.h"
prim__windowState : Bits32 -> PrimIO Int

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

expectState : WindowID -> Int -> IO (Either String ())
expectState (MkWindowID identifier) expected = do
  actual <- primIO (prim__windowState identifier)
  if actual == expected then pure (Right ()) else pure (Left "Scoped window or renderer lifetime was incorrect")

creationFailure : IO (Either String ())
creationFailure = do
  called <- newIORef False
  result <- withWindow "invalid scoped window" 0 16 hidden $ \_ => do
    writeIORef called True
    pure (Right ())
  ran <- readIORef called
  Left err <- pure result | Right () => pure (Left "Scoped creation accepted zero width")
  if not ran && err /= "" then pure (Right ()) else pure (Left "Creation failure ran the callback or lost the error")

bufferScopes : Renderer -> IO (Either String ())
bufferScopes renderer = do
  point <- withCoordinateBuffer $ \buffer =>
    renderCoordinatesFromWindow renderer buffer (MkPoint 1.25 2.5)
  Right (MkPoint x y) <- pure point | Left err => pure (Left err)
  if x /= 1.25 || y /= 2.5 then pure (Left "Copied point did not survive its scope") else do
    result <- withEventBuffer $ \buffer => do
      1 <- primIO (prim__queueEvent 13) | _ => pure (Left "Cannot queue scoped text")
      waitEventData buffer
    -- Replace native text storage after the scoped buffer was freed.
    1 <- primIO (prim__queueEvent 1) | _ => pure (Left "Cannot replace scoped text fixture")
    Right (TextInputEvent _ (MkTextInputData _ "héllo 世界 🎮")) <- pure result
      | _ => pure (Left "Copied text did not survive its scope")
    Left "buffer failure" <- withEventBuffer (\_ => pure (the (Either String ()) (Left "buffer failure")))
      | _ => pure (Left "Event buffer scope lost the callback error")
    Left "coordinate failure" <- withCoordinateBuffer (\_ => pure (the (Either String ()) (Left "coordinate failure")))
      | _ => pure (Left "Coordinate buffer scope lost the callback error")
    pure (Right ())

rendererScopes : Window -> WindowID -> IO (Either String ())
rendererScopes window identifier = do
  result <- withRenderer window $ \renderer => do
    Right () <- expectState identifier 2 | Left err => pure (Left err)
    Right () <- bufferScopes renderer | Left err => pure (Left err)
    pure (Right (the Bits64 0x100000002))
  Right value <- pure result | Left err => pure (Left err)
  if value /= 0x100000002 then pure (Left "Scoped result changed") else do
    Right () <- expectState identifier 1 | Left err => pure (Left err)
    Left "renderer failure" <- withRenderer window (\_ => pure (the (Either String ()) (Left "renderer failure")))
      | _ => pure (Left "Renderer scope lost the callback error")
    expectState identifier 1

successfulWindow : IO (Either String ())
successfulWindow = do
  result <- withWindow "scoped success" 16 16 hidden $ \window => do
    Right identifier <- getWindowID window | Left err => pure (Left err)
    Right () <- rendererScopes window identifier | Left err => pure (Left err)
    pure (Right identifier)
  Right identifier <- pure result | Left err => pure (Left err)
  expectState identifier 0

failedWindow : IO (Either String ())
failedWindow = do
  saved <- newIORef (the (Maybe WindowID) Nothing)
  result <- withWindow "scoped failure" 16 16 hidden $ \window => do
    Right identifier <- getWindowID window | Left err => pure (Left err)
    writeIORef saved (Just identifier)
    withRenderer window (\_ => pure (the (Either String ()) (Left "nested failure")))
  Left "nested failure" <- pure result | _ => pure (Left "Nested scope lost the callback error")
  Just identifier <- readIORef saved | Nothing => pure (Left "Nested callback did not run")
  expectState identifier 0

export
scopedTests : IO (Either String ())
scopedTests = do
  Right () <- creationFailure | Left err => pure (Left err)
  Right () <- successfulWindow | Left err => pure (Left err)
  failedWindow
