module FocusEventTests

import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

copiedNotifications : IO (Either String ())
copiedNotifications = do
  copied <- withEventBuffer $ \buffer => do
    let readEvent = pollEventData buffer
    1 <- primIO (prim__queueEvent 24) | _ => pure (Left "Cannot queue gained focus")
    Just gained <- readEvent | _ => pure (Left "Gained focus was not polled")
    1 <- primIO (prim__queueEvent 25) | _ => pure (Left "Cannot queue lost focus")
    Just lost <- readEvent | _ => pure (Left "Lost focus was not polled")
    pure (Right (gained, lost))
  Right (WindowFocusGainedEvent 0x100000002 (MkWindowID 0x80000001),
         WindowFocusLostEvent 0x100000002 (MkWindowID 0xffffffff)) <- pure copied
    | _ => pure (Left "Focus notifications lost bits or changed after buffer cleanup")
  pure (Right ())

waits : EventBuffer -> IO (Either String ())
waits buffer = do
  1 <- primIO (prim__queueEvent 24) | _ => pure (Left "Cannot queue focus for timed wait")
  Right (Just (WindowFocusGainedEvent 0x100000002 (MkWindowID 0x80000001))) <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Timed wait did not decode gained focus")
  1 <- primIO (prim__queueEvent 25) | _ => pure (Left "Cannot queue focus for blocking wait")
  Right (WindowFocusLostEvent 0x100000002 (MkWindowID 0xffffffff)) <- waitEventData buffer
    | _ => pure (Left "Blocking wait did not decode lost focus")
  1 <- primIO (prim__queueEvent 26) | _ => pure (Left "Cannot queue focus with a zero identifier")
  Right (WindowFocusGainedEvent 0x100000002 (MkWindowID 0)) <- waitEventData buffer
    | _ => pure (Left "Blocking wait changed the zero focus identifier")
  1 <- primIO (prim__queueEvent 27) | _ => pure (Left "Cannot queue lost focus with a zero identifier")
  Right (Just (WindowFocusLostEvent 0x100000002 (MkWindowID 0))) <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Timed wait changed the zero focus identifier")
  pure (Right ())

export
focusEventTests : EventBuffer -> IO (Either String ())
focusEventTests buffer = do
  Right () <- copiedNotifications | Left err => pure (Left err)
  Right () <- waits buffer | Left err => pure (Left err)
  1 <- primIO (prim__queueEvent 24) | _ => pure (Left "Cannot queue gained focus type")
  Just WindowFocusGained <- pollEvent buffer | _ => pure (Left "Gained focus type was incorrect")
  1 <- primIO (prim__queueEvent 25) | _ => pure (Left "Cannot queue lost focus type")
  Just WindowFocusLost <- pollEvent buffer | _ => pure (Left "Lost focus type was incorrect")
  Nothing <- pollEventData buffer | _ => pure (Left "Focus notifications were not consumed")
  pure (Right ())
