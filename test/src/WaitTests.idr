module WaitTests

import SDL3

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

%foreign "C:idris_test_schedule_quit, libidris2_sdl3_test, fixtures.h"
prim__scheduleQuit : PrimIO Bits32

%foreign "C:idris_test_cancel_timer, libidris2_sdl3_test, fixtures.h"
prim__cancelTimer : Bits32 -> PrimIO ()

copiedEvents : EventBuffer -> IO (Either String ())
copiedEvents buffer = do
  1 <- primIO (prim__queueEvent 13) | _ => pure (Left "Cannot queue an event for waiting")
  Right committed <- waitEventData buffer | Left err => pure (Left err)
  1 <- primIO (prim__queueEvent 14) | _ => pure (Left "Cannot queue a timed event")
  Right (Just composed) <- waitEventDataTimeout buffer 2147483647
    | _ => pure (Left "Timed wait did not consume the queued event")
  -- Invalidate fixture text, and prove that each wait consumed exactly one event.
  1 <- primIO (prim__queueEvent 1) | _ => pure (Left "Cannot queue quit")
  Right (Just (QuitEvent _)) <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Zero timeout missed an available event")
  Right Nothing <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Empty wait returned an event or an error")
  let TextInputEvent inputTime (MkTextInputData inputWindow "héllo 世界 🎮") = committed
    | _ => pure (Left "Waited text changed after buffer reuse")
  let TextEditingEvent editTime (MkTextEditingData editWindow "にほん" 1 2) = composed
    | _ => pure (Left "Waited composition changed after buffer reuse")
  if inputTime == 0x100000002 && editTime == 0x100000002 &&
     inputWindow == MkWindowID 0x80000001 && editWindow == inputWindow
     then pure (Right ()) else pure (Left "Waited event metadata was incorrect")

invalidTimeout : EventBuffer -> Bits32 -> IO (Either String ())
invalidTimeout buffer timeout = do
  1 <- primIO (prim__queueEvent 1) | _ => pure (Left "Cannot queue timeout boundary fixture")
  Left err <- waitEventDataTimeout buffer timeout
    | Right _ => pure (Left "Out-of-range wait timeout was accepted")
  Just (QuitEvent _) <- pollEventData buffer
    | _ => pure (Left "Invalid wait consumed an event")
  if err /= "" then pure (Right ()) else pure (Left "Invalid timeout had no error")

laterEvent : EventBuffer -> Bool -> IO (Either String ())
laterEvent buffer forever = do
  timer <- primIO prim__scheduleQuit
  if timer == 0 then Left <$> getError else do
    result <- the (IO (Either String (Maybe Event))) $
      if forever then map (map Just) (waitEventData buffer)
                 else waitEventDataTimeout buffer 5000
    primIO (prim__cancelTimer timer)
    case result of
      Right (Just (QuitEvent _)) => pure (Right ())
      Left err => pure (Left err)
      _ => pure (Left "Timed wait did not receive the delayed event")

export
waitTests : IO (Either String ())
waitTests = do
  Right buffer <- newEventBuffer | Left err => pure (Left err)
  result <- do
    Right () <- copiedEvents buffer | Left err => pure (Left err)
    Right () <- invalidTimeout buffer 2147483648 | Left err => pure (Left err)
    Right () <- invalidTimeout buffer 4294967295 | Left err => pure (Left err)
    -- The preceding invalid timeout leaves an SDL error. A timeout must not reuse it.
    Right Nothing <- waitEventDataTimeout buffer 1
      | _ => pure (Left "Timed wait reused an old error or stale event data")
    Right () <- laterEvent buffer False | Left err => pure (Left err)
    laterEvent buffer True
  freeEventBuffer buffer
  pure result
