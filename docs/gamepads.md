# Gamepads

Import `SDL3` and initialize `gamepad`, usually with `video <+> gamepad`.  Import `SDL3.Scoped` for
`withGamepad`. These bindings use SDL's gamepad mappings, not raw joystick axes.  Button labels
describe SDL's current mapping rather than application actions.

## Discovery and ownership

`listGamepads` returns `Either String (List GamepadID)` for currently connected gamepads.  The
identifiers are copied, not open handles or device indices. Enumerate at startup, then handle
connection events rather than allocating a list every frame.  A device can disappear between
enumeration and opening.

`openGamepad identifier` returns an owned `Gamepad` or a copied error.  `closeGamepad` releases one
open reference. Close exactly once for each successful open, including after removal. Opening the
same device again creates another reference, even when SDL returns the same native pointer. Copying
an Idris handle does not create a reference.

`withGamepad identifier action` closes after an ordinary callback return.  Do not close the supplied
handle or retain it after the callback. Runtime exceptions and nonreturning callbacks do not
guarantee cleanup. Release gamepads before SDL `quit`.  See [resource ownership](resources.md) for
shared scope rules.

`getGamepadID` and `getGamepadName` return copied values through `Either String`.
`gamepadConnected` reports current connection state. It does not close a removed handle.  Device
identifiers remain distinct from window identifiers, even if their numeric values match.

## Axes, buttons, and rumble

`getGamepadAxis pad axis` returns `Int16`. Named axes are `leftStickX`, `leftStickY`, `rightStickX`,
`rightStickY`, `leftTrigger`, and `rightTrigger`.  Sticks range from -32768 through 32767. Triggers
range from zero through 32767.  The binding does not normalize values or apply a dead zone, a range
of small ignored movement.

`getGamepadButton pad button` returns pressed state. Common names include `gamepadSouth`,
`gamepadEast`, `gamepadWest`, `gamepadNorth`, `gamepadStart`, the shoulder buttons, and the
`gamepadDpad...` directions. Face names describe positions, not A/B/X/Y labels.  `MkGamepadAxis` and
`MkGamepadButton` preserve numeric byte codes for additional controls.

These queries follow SDL's state semantics. Zero axis values and `False` button values can also mean
unavailable controls or errors. They are not success indicators.  Use live handles and process
events before querying. `updateGamepads` explicitly refreshes state when an application does not use
normal event pumping.

`rumbleGamepad pad low high durationMS` controls low- and high-frequency vibration.  Both
intensities use `Bits16`, from zero through 65535. Duration uses `Bits32` milliseconds.  Zero
intensities stop the current rumble. A new request replaces the previous effect.  Unsupported
hardware returns `False`. Read `getError` immediately after failure.

## Capabilities and labels

`hasGamepadAxis pad axis` and `hasGamepadButton pad button` report mapped control availability, not
current input state.  `hasGamepadRumble pad` reads SDL's rumble capability. A capability report does
not guarantee that a later operation succeeds.  Use live handles. `False` can also mean an error,
and these functions do not test physical hardware response.

`getGamepadButtonLabel pad button` returns a copied `GamepadButtonLabel` for prompts.  Known labels
are A, B, X, Y, Cross, Circle, Square, and Triangle.  `UnknownButtonLabel` includes controls without
a face-button label. `OtherButtonLabel code` preserves future numeric values.

Query again after a mapping change if the application displays labels or available controls.  The
binding does not map controls to actions, choose dead zones, or supply button artwork.  Keep events
for transitions that state queries can miss.

## Events

Connection notifications contain nanosecond timestamps and `GamepadID` values:

- `GamepadAddedEvent`: Open the device if the application needs it.
- `GamepadRemovedEvent`: Stop using its input and close the owned reference.
- `GamepadRemappedEvent`: The control mapping changed, not the device identifier.

`GamepadAxisEvent` carries `GamepadAxisData` with `gamepadID`, `axis`, and signed `value`.
`GamepadButtonEvent` carries `GamepadButtonData` with `gamepadID`, `button`, and `Pressed` or
`Released` action. Events have no window identifier. Match their gamepad ID to your open handle
rather than treating an event as current connection state.

Type-only polling returns `GamepadAdded`, `GamepadRemoved`, `GamepadRemapped`, `GamepadAxisMotion`,
`GamepadButtonDown`, or `GamepadButtonUp`.  Both polling APIs and both wait APIs consume events from
the same queue.  Copied payloads survive event-buffer reuse and cleanup. Unknown control codes
remain intact.

## Threading and limits

Use the main thread for initialization and event pumping.  SDL permits individual gamepad calls from
application threads. Serialize gamepad cleanup with all users. Do not close a handle while another
thread queries it or copies its name. SDL manages device state internally, but the binding does not
enforce resource lifetimes or make several queries an atomic snapshot.

Custom mapping management, battery information, sensors, trigger rumble, and raw joystick support
are not bound. SDL's built-in mappings determine which devices are recognized.  Connection events do
not automatically create or destroy application handles.

## Example and tests

With SDL gamepad support initialized, this function reads one gamepad's current state:

```idris
import SDL3
import SDL3.Scoped

readPad : GamepadID -> IO (Either String (Int16, Bool))
readPad identifier = withGamepad identifier $ \pad => do
  updateGamepads
  x <- getGamepadAxis pad leftStickX
  pressed <- getGamepadButton pad gamepadSouth
  pure (Right (x, pressed))
```

For a game loop, keep the handle open around the loop instead of opening every frame.  `make test`
uses an SDL virtual gamepad without physical hardware. It covers discovery, open references, signed
axis limits, buttons, rumble arguments, removal, and copied names.  Synthetic events cover
timestamps, identifiers, unknown controls, polling, and waits.  Real mappings, device removal, and
vibration still need hardware tests.
