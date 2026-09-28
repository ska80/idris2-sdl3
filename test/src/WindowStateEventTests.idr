module WindowStateEventTests

import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

stateData : Event -> Maybe (Int, Bits64, WindowID)
stateData (WindowMinimizedEvent timestamp window) = Just (0, timestamp, window)
stateData (WindowMaximizedEvent timestamp window) = Just (1, timestamp, window)
stateData (WindowRestoredEvent timestamp window) = Just (2, timestamp, window)
stateData (WindowShownEvent timestamp window) = Just (3, timestamp, window)
stateData (WindowHiddenEvent timestamp window) = Just (4, timestamp, window)
stateData (WindowExposedEvent timestamp window) = Just (5, timestamp, window)
stateData _ = Nothing

stateType : EventType -> Maybe Int
stateType WindowMinimized = Just 0
stateType WindowMaximized = Just 1
stateType WindowRestored = Just 2
stateType WindowShown = Just 3
stateType WindowHidden = Just 4
stateType WindowExposed = Just 5
stateType _ = Nothing

copiedEvent : Int -> IO (Either String Event)
copiedEvent fixture = withEventBuffer $ \buffer => do
  let readEvent = pollEventData buffer
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window state event")
  Just saved <- readEvent | _ => pure (Left "Window state event was not polled")
  1 <- primIO (prim__queueEvent 1) | _ => pure (Left "Cannot queue a replacement event")
  Just (QuitEvent _) <- readEvent | _ => pure (Left "Replacement event was not consumed")
  pure (Right saved)

checkPaths : EventBuffer -> Int -> Int -> Bits32 -> IO (Either String ())
checkPaths buffer fixture kind identifier = do
  Right saved <- copiedEvent fixture | Left err => pure (Left err)
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window state event for timed wait")
  Right (Just timed) <- waitEventDataTimeout buffer 0 | _ => pure (Left "Timed wait lost a window state event")
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window state event for blocking wait")
  Right waited <- waitEventData buffer | Left err => pure (Left err)
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window state event type")
  Just eventType <- pollEvent buffer | _ => pure (Left "Window state event type was not polled")
  let expected = Just (kind, the Bits64 0x100000002, MkWindowID identifier)
  if stateData saved /= expected || stateData timed /= expected || stateData waited /= expected || stateType eventType /= Just kind
     then pure (Left "Window state notification changed type, identifier, or timestamp")
     else pure (Right ())

checkCases : EventBuffer -> List (Int, Int, Bits32) -> IO (Either String ())
checkCases buffer [] = pure (Right ())
checkCases buffer ((fixture, kind, identifier) :: rest) = do
  Right () <- checkPaths buffer fixture kind identifier | Left err => pure (Left err)
  checkCases buffer rest

export
windowStateEventTests : EventBuffer -> IO (Either String ())
windowStateEventTests buffer = do
  Right () <- checkCases buffer [(32, 0, 0x80000001), (33, 1, 0xffffffff), (34, 2, 42),
                                 (35, 0, 0), (36, 1, 0), (37, 2, 0),
                                 (38, 3, 0x80000001), (39, 4, 0xffffffff), (40, 5, 42),
                                 (41, 3, 0), (42, 4, 0), (43, 5, 0)]
    | Left err => pure (Left err)
  Nothing <- pollEventData buffer | _ => pure (Left "Window state events were not consumed")
  pure (Right ())
