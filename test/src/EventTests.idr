module EventTests

import SDL3
import SDL3.Scoped
import FocusEventTests
import MouseFocusEventTests
import WindowStateEventTests
import Data.List

%default covering

%foreign "C:idris_test_queue_event, libidris2_sdl3_test, fixtures.h"
prim__queueEvent : Int -> PrimIO Int

fixture : EventBuffer -> Int -> IO (Maybe Event)
fixture buffer kind = do
  1 <- primIO (prim__queueEvent kind) | _ => pure Nothing
  pollEventData buffer

textTests : EventBuffer -> IO (Either String ())
textTests buffer = do
  Just (TextInputEvent inputTime committed) <- fixture buffer 13
    | _ => pure (Left "Text input was not decoded")
  Just (TextEditingEvent editTime composing) <- fixture buffer 14
    | _ => pure (Left "Text composition was not decoded")
  Just (TextInputEvent emptyTime (MkTextInputData emptyWindow "")) <- fixture buffer 15
    | _ => pure (Left "Empty text input was not preserved")
  Just (TextEditingEvent clearedTime (MkTextEditingData clearedWindow "" start length)) <- fixture buffer 16
    | _ => pure (Left "Empty composition was not preserved")
  Just (TextInputEvent longTime (MkTextInputData longWindow longText)) <- fixture buffer 17
    | _ => pure (Left "Long text input was not decoded")
  -- Subsequent fixtures overwrite both the event buffer and the native text storage.
  let MkTextInputData inputWindow "héllo 世界 🎮" = committed
    | _ => pure (Left "Committed Unicode text changed after buffer reuse")
  let MkTextEditingData editWindow "にほん" 1 2 = composing
    | _ => pure (Left "Composition text or selection changed after buffer reuse")
  let valuesOK = all (== 0x100000002) [inputTime, editTime, emptyTime, clearedTime, longTime] &&
                 all (== MkWindowID 0x80000001) [inputWindow, editWindow, emptyWindow, clearedWindow, longWindow] &&
                 start == -1 && length == -1 && longText == pack (replicate 200 'x')
  if not valuesOK then pure (Left "Text event data was incorrect") else do
    1 <- primIO (prim__queueEvent 13) | _ => pure (Left "Cannot queue text input")
    Just TextInput <- pollEvent buffer | _ => pure (Left "Text input type was incorrect")
    1 <- primIO (prim__queueEvent 14) | _ => pure (Left "Cannot queue text composition")
    Just TextEditing <- pollEvent buffer | _ => pure (Left "Text composition type was incorrect")
    Nothing <- pollEventData buffer | _ => pure (Left "Text event queue was not empty")
    Right temporary <- newEventBuffer | Left err => pure (Left err)
    snapshot <- fixture temporary 13
    freeEventBuffer temporary
    _ <- fixture buffer 15
    case snapshot of
      Just (TextInputEvent _ (MkTextInputData _ "héllo 世界 🎮")) => pure (Right ())
      _ => pure (Left "Text did not survive event buffer destruction")

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
    textTests buffer

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

sizeTests : EventBuffer -> IO (Either String ())
sizeTests buffer = do
  Just (WindowResizedEvent windowTime windowSize) <- fixture buffer 18
    | _ => pure (Left "Window-coordinate resize was not decoded")
  1 <- primIO (prim__queueEvent 19) | _ => pure (Left "Cannot queue a pixel size event")
  Right (Just (WindowPixelSizeChangedEvent pixelTime pixelSize)) <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Wait did not decode the pixel size event")
  Just (WindowPixelSizeChangedEvent _ (MkPixelSizeData _ zeroWidth zeroHeight)) <- fixture buffer 20
    | _ => pure (Left "Zero pixel dimensions were not decoded")
  Just (WindowPixelSizeChangedEvent _ (MkPixelSizeData _ minWidth maxHeight)) <- fixture buffer 21
    | _ => pure (Left "Signed pixel dimensions were not decoded")
  -- Earlier values must survive subsequent reuse of the native event buffer.
  let MkWindowSizeData windowID width height = windowSize
  let MkPixelSizeData pixelID pixelWidth pixelHeight = pixelSize
  if windowTime /= 0x100000002 || pixelTime /= 0x100000002 ||
     windowID /= MkWindowID 0x80000001 || pixelID /= windowID ||
     width /= 800 || height /= 600 || pixelWidth /= 1600 || pixelHeight /= 1200 ||
     zeroWidth /= 0 || zeroHeight /= 0 || minWidth /= -2147483648 || maxHeight /= 2147483647
     then pure (Left "Resize event values changed or lost bits")
     else do
       1 <- primIO (prim__queueEvent 18) | _ => pure (Left "Cannot queue window resize type")
       Just WindowResized <- pollEvent buffer | _ => pure (Left "Window resize type was incorrect")
       1 <- primIO (prim__queueEvent 19) | _ => pure (Left "Cannot queue pixel size type")
       Just WindowPixelSizeChanged <- pollEvent buffer | _ => pure (Left "Pixel size event type was incorrect")
       Nothing <- pollEventData buffer | _ => pure (Left "Resize events were not consumed")
       pure (Right ())

scaleLifetime : IO (Either String ())
scaleLifetime = do
  copied <- withEventBuffer $ \storage => do
    Just event <- fixture storage 22 | _ => pure (Left "Cannot copy a display-scale notification")
    pure (Right event)
  Right (WindowDisplayScaleChangedEvent 0x100000002 (MkWindowID 0x80000001)) <- pure copied
    | _ => pure (Left "Display-scale notification changed after buffer destruction")
  pure (Right ())

displayScaleTests : EventBuffer -> IO (Either String ())
displayScaleTests buffer = do
  Just copied <- fixture buffer 22 | _ => pure (Left "Display-scale notification was not polled")
  1 <- primIO (prim__queueEvent 23) | _ => pure (Left "Cannot queue a display-scale notification")
  Right (Just (WindowDisplayScaleChangedEvent timestamp (MkWindowID 0))) <- waitEventDataTimeout buffer 0
    | _ => pure (Left "Timed wait lost the display-scale notification or zero identifier")
  WindowDisplayScaleChangedEvent savedTime (MkWindowID 0x80000001) <- pure copied
    | _ => pure (Left "Display-scale notification changed after buffer reuse")
  if savedTime /= 0x100000002 || timestamp /= savedTime then pure (Left "Display-scale timestamps lost bits") else do
    1 <- primIO (prim__queueEvent 22) | _ => pure (Left "Cannot queue a display-scale type")
    Just WindowDisplayScaleChanged <- pollEvent buffer | _ => pure (Left "Display-scale type was not decoded")
    1 <- primIO (prim__queueEvent 22) | _ => pure (Left "Cannot queue a display-scale wait")
    Right (WindowDisplayScaleChangedEvent waitedTime (MkWindowID 0x80000001)) <- waitEventData buffer
      | _ => pure (Left "Blocking wait did not decode the display-scale notification")
    if waitedTime == savedTime then scaleLifetime else pure (Left "Wait changed the display-scale timestamp")

export
eventTests : EventBuffer -> IO (Either String ())
eventTests buffer = do
  Right () <- sizeTests buffer | Left err => pure (Left err)
  Right () <- displayScaleTests buffer | Left err => pure (Left err)
  Right () <- focusEventTests buffer | Left err => pure (Left err)
  Right () <- mouseFocusEventTests buffer | Left err => pure (Left err)
  Right () <- windowStateEventTests buffer | Left err => pure (Left err)
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
  -- Compare the full timestamp, including bits above the low 32 bits.
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
