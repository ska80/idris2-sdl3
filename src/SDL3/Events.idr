module SDL3.Events

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

||| Event data copied from the reusable buffer. Timestamps use nanoseconds.
||| Other types retain their numeric type and timestamp, but not their payload.
public export
data Event = QuitEvent Bits64
           | WindowCloseEvent Bits64 WindowID
           | KeyboardEvent Bits64 KeyboardData
           | UnknownEvent Bits64 Bits32
