module SDL3.Events

import Data.Bits
import Data.Fin

%default total

||| An SDL window identifier, not an owned window handle. Zero means no window.
public export
data WindowID = MkWindowID Bits32

public export
Eq WindowID where
  MkWindowID x == MkWindowID y = x == y

||| Physical key position. Values follow SDL_Scancode.
public export
data Scancode = MkScancode Bits32

public export
Eq Scancode where
  MkScancode x == MkScancode y = x == y

||| Key value from the keyboard layout. Values follow SDL_Keycode.
public export
data Keycode = MkKeycode Bits32

public export
Eq Keycode where
  MkKeycode x == MkKeycode y = x == y

public export
escapeKey : Keycode
escapeKey = MkKeycode 27

||| Modifier bits from SDL_Keymod. This is not an initialization flag set.
public export
data KeyModifiers = MkKeyModifiers Bits16

public export
Eq KeyModifiers where
  MkKeyModifiers x == MkKeyModifiers y = x == y

public export
data KeyAction = Pressed | Released

||| Copied keyboard data. Safe to retain after the next poll.
public export
record KeyboardData where
  constructor MkKeyboardData
  windowID : WindowID
  action : KeyAction
  scancode : Scancode
  keycode : Keycode
  modifiers : KeyModifiers
  repeated : Bool

||| Mouse device identifier, including SDL's synthetic touch and pen identifiers.
public export
data MouseID = MkMouseID Bits32

public export
Eq MouseID where
  MkMouseID x == MkMouseID y = x == y

||| SDL button index. Unknown indices are preserved.
public export
data MouseButton = MkMouseButton Bits8

public export
Eq MouseButton where
  MkMouseButton x == MkMouseButton y = x == y

public export
leftButton, middleButton, rightButton, x1Button, x2Button : MouseButton
leftButton = MkMouseButton 1
middleButton = MkMouseButton 2
rightButton = MkMouseButton 3
x1Button = MkMouseButton 4
x2Button = MkMouseButton 5

||| SDL button-state bits, not a single button index.
public export
data MouseButtons = MkMouseButtons Bits32

||| Button indices outside 1 through 32 cannot occur in the state mask.
public export
buttonHeld : MouseButton -> MouseButtons -> Bool
buttonHeld (MkMouseButton button) (MkMouseButtons bits) =
  if button == 0 then False else
    case natToFin (cast (button - 1)) 32 of
      Nothing => False
      Just index => testBit bits index

public export
data MouseAction = ButtonPressed | ButtonReleased

||| Coordinates are relative to the window. Deltas describe relative motion.
public export
record MouseMotionData where
  constructor MkMouseMotionData
  windowID : WindowID
  mouseID : MouseID
  buttons : MouseButtons
  x : Double
  y : Double
  deltaX : Double
  deltaY : Double

||| Click count follows SDL: one for a single click, two for a double click.
public export
record MouseButtonData where
  constructor MkMouseButtonData
  windowID : WindowID
  mouseID : MouseID
  button : MouseButton
  action : MouseAction
  clicks : Bits8
  x : Double
  y : Double

||| Event data copied from the reusable buffer. Timestamps use nanoseconds.
||| Other types retain their numeric type and timestamp, but not their payload.
public export
data Event = QuitEvent Bits64
           | WindowCloseEvent Bits64 WindowID
           | KeyboardEvent Bits64 KeyboardData
           | MouseMotionEvent Bits64 MouseMotionData
           | MouseButtonEvent Bits64 MouseButtonData
           | UnknownEvent Bits64 Bits32
