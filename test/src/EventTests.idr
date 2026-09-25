module EventTests

import SDL3

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

fixture : EventBuffer -> Int -> IO (Maybe Event)
fixture buffer kind = do
  1 <- primIO (prim__queueEvent kind) | _ => pure Nothing
  pollEventData buffer

wheelTests : EventBuffer -> IO (Either String ())
wheelTests buffer = do
  Just (MouseWheelEvent normalTime normal) <- fixture buffer 10
    | _ => pure (Left "Normal wheel event was not decoded")
  Just (MouseWheelEvent flippedTime flipped) <- fixture buffer 11
    | _ => pure (Left "Flipped wheel event was not decoded")
  Just (MouseWheelEvent unknownTime unknown) <- fixture buffer 12
    | _ => pure (Left "Unknown wheel direction was not decoded")
  -- Inspect data only after subsequent polls overwrite the native buffer.
  let MkMouseWheelData normalWindow normalID x y WheelNormal mx my ix iy = normal
    | _ => pure (Left "Normal wheel direction was incorrect")
  let MkMouseWheelData flippedWindow flippedID fx fy WheelFlipped fmx fmy fix fiy = flipped
    | _ => pure (Left "Flipped wheel direction was incorrect")
  let MkMouseWheelData unknownWindow unknownID ux uy (OtherWheelDirection 42) umx umy uix uiy = unknown
    | _ => pure (Left "Unknown wheel direction was not preserved")
  let valuesOK = all (== 0x100000002) [normalTime, flippedTime, unknownTime] &&
                 all (== MkWindowID 0x80000001) [normalWindow, flippedWindow, unknownWindow] &&
                 all (== MkMouseID 0xfffffffe) [normalID, flippedID, unknownID] &&
                 all (== -16.5) [mx, fmx, umx] && all (== 99.25) [my, fmy, umy] &&
                 x == -2.5 && y == 3.75 && ix == -2 && iy == 3 &&
                 fx == 2.5 && fy == -3.75 && fix == 2 && fiy == -3 &&
                 ux == -2.5 && uy == 3.75 && uix == -2147483648 && uiy == 2147483647
  if not valuesOK then pure (Left "Wheel event data was incorrect") else do
    1 <- primIO (prim__queueEvent 10) | _ => pure (Left "Cannot queue wheel event")
    Just MouseWheel <- pollEvent buffer | _ => pure (Left "Wheel event type was incorrect")
    Nothing <- pollEventData buffer | _ => pure (Left "Wheel event queue was not empty")
    pure (Right ())

mouseTests : EventBuffer -> IO (Either String ())
mouseTests buffer = do
  Just (MouseMotionEvent motionTime motion) <- fixture buffer 6
    | _ => pure (Left "Mouse motion was not decoded")
  Just (MouseButtonEvent downTime down) <- fixture buffer 7
    | _ => pure (Left "Mouse press was not decoded")
  Just (MouseButtonEvent upTime up) <- fixture buffer 8
    | _ => pure (Left "Mouse release was not decoded")
  Just (MouseButtonEvent _ (MkMouseButtonData _ _ (MkMouseButton 200) ButtonPressed _ _ _)) <- fixture buffer 9
    | _ => pure (Left "Unknown mouse button was not preserved")
  -- All records below must survive reuse of the same native buffer.
  let MkMouseMotionData motionWindow motionID buttons x y dx dy = motion
  let MkMouseButtonData downWindow downID downButton ButtonPressed 2 downX downY = down
    | _ => pure (Left "Mouse press action or click count was incorrect")
  let MkMouseButtonData upWindow upID upButton ButtonReleased 2 upX upY = up
    | _ => pure (Left "Mouse release action or click count was incorrect")
  let valuesOK = all (== 0x100000002) [motionTime, downTime, upTime] &&
                 all (== MkWindowID 0x80000001) [motionWindow, downWindow, upWindow] &&
                 all (== MkMouseID 0xfffffffe) [motionID, downID, upID] &&
                 downButton == rightButton && upButton == rightButton &&
                 x == 12.5 && y == -7.25 && dx == -1.5 && dy == 2.75 &&
                 downX == -0.5 && downY == 100.25 && upX == -0.5 && upY == 100.25
  let buttonsOK = buttonHeld leftButton buttons && buttonHeld rightButton buttons &&
                  not (buttonHeld middleButton buttons) &&
                  not (buttonHeld x1Button buttons) && not (buttonHeld x2Button buttons) &&
                  buttonHeld (MkMouseButton 32) buttons &&
                  not (buttonHeld (MkMouseButton 0) buttons) &&
                  not (buttonHeld (MkMouseButton 33) buttons)
  if not (valuesOK && buttonsOK) then pure (Left "Mouse event data was incorrect") else do
    1 <- primIO (prim__queueEvent 6) | _ => pure (Left "Cannot queue mouse motion")
    Just MouseMotion <- pollEvent buffer | _ => pure (Left "Mouse motion type was incorrect")
    1 <- primIO (prim__queueEvent 7) | _ => pure (Left "Cannot queue mouse press")
    Just MouseButtonDown <- pollEvent buffer | _ => pure (Left "Mouse press type was incorrect")
    1 <- primIO (prim__queueEvent 8) | _ => pure (Left "Cannot queue mouse release")
    Just MouseButtonUp <- pollEvent buffer | _ => pure (Left "Mouse release type was incorrect")
    Nothing <- pollEventData buffer | _ => pure (Left "Mouse event queue was not empty")
    wheelTests buffer

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
        mouseTests buffer
