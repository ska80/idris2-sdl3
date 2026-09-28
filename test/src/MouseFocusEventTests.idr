module MouseFocusEventTests

import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

copiedNotifications : IO (Either String ())
copiedNotifications = do
  copied <- withEventBuffer $ \buffer => do
    let readEvent = pollEventData buffer
    1 <- primIO (prim__queueEvent 28) | _ => pure (Left "Cannot queue mouse entry")
    Just entered <- readEvent | _ => pure (Left "Mouse entry was not polled")
    1 <- primIO (prim__queueEvent 29) | _ => pure (Left "Cannot queue mouse departure")
    Just left <- readEvent | _ => pure (Left "Mouse departure was not polled")
    pure (Right (entered, left))
  Right (WindowMouseEnterEvent 0x100000002 (MkWindowID 0x80000001),
         WindowMouseLeaveEvent 0x100000002 (MkWindowID 0xffffffff)) <- pure copied
    | _ => pure (Left "Mouse-focus notifications lost bits or changed after buffer cleanup")
  pure (Right ())

waits : EventBuffer -> IO (Either String ())
waits buffer = do
  1 <- primIO (prim__queueEvent 28) | _ => pure (Left "Cannot queue mouse entry for timed wait")
  Right (Just (WindowMouseEnterEvent 0x100000002 (MkWindowID 0x80000001))) <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Timed wait did not decode mouse entry")
  1 <- primIO (prim__queueEvent 29) | _ => pure (Left "Cannot queue mouse departure for blocking wait")
  Right (WindowMouseLeaveEvent 0x100000002 (MkWindowID 0xffffffff)) <- waitEventData buffer
    | _ => pure (Left "Blocking wait did not decode mouse departure")
  1 <- primIO (prim__queueEvent 30) | _ => pure (Left "Cannot queue mouse entry with a zero identifier")
  Right (WindowMouseEnterEvent 0x100000002 (MkWindowID 0)) <- waitEventData buffer
    | _ => pure (Left "Blocking wait changed the zero mouse-focus identifier")
  1 <- primIO (prim__queueEvent 31) | _ => pure (Left "Cannot queue mouse departure with a zero identifier")
  Right (Just (WindowMouseLeaveEvent 0x100000002 (MkWindowID 0))) <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Timed wait changed the zero mouse-focus identifier")
  pure (Right ())

export
mouseFocusEventTests : EventBuffer -> IO (Either String ())
mouseFocusEventTests buffer = do
  Right () <- copiedNotifications | Left err => pure (Left err)
  Right () <- waits buffer | Left err => pure (Left err)
  1 <- primIO (prim__queueEvent 28) | _ => pure (Left "Cannot queue mouse entry type")
  Just WindowMouseEnter <- pollEvent buffer | _ => pure (Left "Mouse entry type was incorrect")
  1 <- primIO (prim__queueEvent 29) | _ => pure (Left "Cannot queue mouse departure type")
  Just WindowMouseLeave <- pollEvent buffer | _ => pure (Left "Mouse departure type was incorrect")
  Nothing <- pollEventData buffer | _ => pure (Left "Mouse-focus notifications were not consumed")
  pure (Right ())
