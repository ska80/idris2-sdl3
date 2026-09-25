module EventTests

import SDL3

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

fixture : EventBuffer -> Int -> IO (Maybe Event)
fixture buffer kind = do
  1 <- primIO (prim__queueEvent kind) | _ => pure Nothing
  pollEventData buffer

export
eventTests : EventBuffer -> IO (Either String ())
eventTests buffer = do
  Just (QuitEvent quitTime) <- fixture buffer 1
    | _ => pure (Left "Quit event was not decoded")
  Just (WindowCloseEvent closeTime target) <- fixture buffer 2
    | _ => pure (Left "Close event was not decoded")
  Just (KeyboardEvent pressTime pressed) <- fixture buffer 3
    | _ => pure (Left "Key press was not decoded")
  Just (KeyboardEvent releaseTime released) <- fixture buffer 4
    | _ => pure (Left "Key release was not decoded")
  -- Inspect the first value after the next poll overwrites the native buffer.
  let MkKeyboardData pressWindow Pressed (MkScancode 41)
                     (MkKeycode 27) (MkKeyModifiers 0x81) True = pressed
    | _ => pure (Left "Key press data changed after buffer reuse")
  let MkKeyboardData releaseWindow Released (MkScancode 41)
                     (MkKeycode 27) (MkKeyModifiers 0x81) False = released
    | _ => pure (Left "Key release data was incorrect")
  Just (UnknownEvent unknownTime 0x8000) <- fixture buffer 5
    | _ => pure (Left "Unknown event type was not preserved")
  -- Equality avoids RefC's truncation of wide numeric case patterns.
  let times = [quitTime, closeTime, pressTime, releaseTime, unknownTime]
  if not (all (== 0x100000002) times)
    then pure (Left "Event timestamps lost bits")
    else if not (all (== MkWindowID 0x80000001) [target, pressWindow, releaseWindow])
      then pure (Left "Window identifiers lost bits")
      else do
        Nothing <- pollEventData buffer
          | _ => pure (Left "Event queue was not empty")
        1 <- primIO (prim__queueEvent 3)
          | _ => pure (Left "Cannot queue a test event")
        Just KeyDown <- pollEvent buffer
          | _ => pure (Left "Type-only polling changed behavior")
        pure (Right ())
