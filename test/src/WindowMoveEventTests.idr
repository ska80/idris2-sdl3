module WindowMoveEventTests

import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

positionData : Event -> Maybe (Bits64, WindowID, Int32, Int32)
positionData (WindowMovedEvent timestamp (MkWindowPositionData window x y)) = Just (timestamp, window, x, y)
positionData _ = Nothing

copiedEvent : Int -> IO (Either String Event)
copiedEvent fixture = withEventBuffer $ \buffer => do
  let readEvent = pollEventData buffer
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window move")
  Just saved <- readEvent | _ => pure (Left "Window move was not polled")
  1 <- primIO (prim__queueEvent 1) | _ => pure (Left "Cannot queue a replacement event")
  Just (QuitEvent _) <- readEvent | _ => pure (Left "Replacement event was not consumed")
  pure (Right saved)

checkFixture : EventBuffer -> Int -> Bits32 -> Int32 -> Int32 -> IO (Either String ())
checkFixture buffer fixture identifier x y = do
  Right saved <- copiedEvent fixture | Left err => pure (Left err)
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window move for timed wait")
  Right (Just timed) <- waitEventDataTimeout buffer 0 | _ => pure (Left "Timed wait lost a window move")
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window move for blocking wait")
  Right waited <- waitEventData buffer | Left err => pure (Left err)
  1 <- primIO (prim__queueEvent fixture) | _ => pure (Left "Cannot queue a window move type")
  Just WindowMoved <- pollEvent buffer | _ => pure (Left "Window move type was incorrect")
  let expected = Just (the Bits64 0x100000002, MkWindowID identifier, x, y)
  if positionData saved /= expected || positionData timed /= expected || positionData waited /= expected
     then pure (Left "Window move data changed or lost signed coordinates")
     else pure (Right ())

export
windowMoveEventTests : EventBuffer -> IO (Either String ())
windowMoveEventTests buffer = do
  Right () <- checkFixture buffer 44 0x80000001 (-320) 240 | Left err => pure (Left err)
  Right () <- checkFixture buffer 45 0 0 0 | Left err => pure (Left err)
  Right () <- checkFixture buffer 46 0xffffffff (-2147483648) 2147483647 | Left err => pure (Left err)
  Nothing <- pollEventData buffer | _ => pure (Left "Window move events were not consumed")
  pure (Right ())
