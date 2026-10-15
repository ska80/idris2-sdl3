# Gamepads

Initialize `gamepad`, usually `video <+> gamepad`. Uses SDL mappings, not raw joystick controls.
[Resource/error rules](resources.md).

## Discovery and ownership

| API | Contract |
| --- | --- |
| `listGamepads` | Copied `List GamepadID`. Device IDs, not indices or open handles |
| `openGamepad id`, `withGamepad id` | Acquire one open reference. Disappearance before opening can fail |
| `closeGamepad` | Release one reference, including after removal |
| `getGamepadID`, `getGamepadName` | Copied `Either String` results |
| `gamepadConnected` | Current connection state. Does not close a removed handle |

Enumerate at startup, then use connection events rather than allocating a list each frame.  Repeated
opens can share a native pointer but own separate references. Copying an Idris handle adds no
reference.

## State and capabilities

| API | Result / units |
| --- | --- |
| `getGamepadAxis pad axis` | `Int16`. Sticks -32768..32767, triggers 0..32767 |
| `getGamepadButton pad button` | Pressed state |
| `updateGamepads` | Refresh state when not pumping events |
| `hasGamepadAxis`, `hasGamepadButton` | Mapped control availability, not pressed state |
| `hasGamepadRumble` | SDL capability, not guaranteed later success or physical response |
| `getGamepadButtonLabel pad button` | `LabelA/B/X/Y`, `LabelCross/Circle/Square/Triangle`, `UnknownButtonLabel`, or `OtherButtonLabel code` |
| `rumbleGamepad pad low high durationMS` | Two `Bits16` intensities 0..65535. `Bits32` milliseconds. Zero intensities stop. New effect replaces old |

- Axes: `leftStickX/Y`, `rightStickX/Y`, `leftTrigger`, `rightTrigger`.
- Buttons include `gamepadSouth/East/West/North`, start, shoulders, and D-pad. Face names describe
  positions, not labels.
- `MkGamepadAxis` / `MkGamepadButton` preserve unknown byte codes.
- Zero/False state values can mean unavailable input or error. Use live handles and pump events
  before reading.
- Requery labels/capabilities after remapping. `UnknownButtonLabel` also covers controls without
  face labels.
- No dead-zone policy, normalization, action mapping, artwork, or atomic multi-query snapshot. Keep
  events for short transitions.

## Events

| Event | Payload / action |
| --- | --- |
| `GamepadAddedEvent` | Timestamp + ID. Open if needed |
| `GamepadRemovedEvent` | Timestamp + ID. Stop input use and close the owned reference |
| `GamepadRemappedEvent` | Timestamp + ID. Mapping changed |
| `GamepadAxisEvent` | `GamepadAxisData`: ID, axis, signed value |
| `GamepadButtonEvent` | `GamepadButtonData`: ID, button, `Pressed`/`Released` |

No window IDs. Type-only polling uses added/removed/remapped, axis-motion, and button-down/up forms.
All paths share the [event queue and copied-value rules](input.md#polling-and-waiting).

## Threads and limits

- Initialization/event pumping: main thread. Individual gamepad calls: application threads allowed.
- Serialize cleanup with every user of the handle, including name queries and rumble.
- No custom mappings, battery/sensor queries, trigger rumble, or raw joystick APIs.
- Virtual-device tests cover binding behavior, not physical mappings or vibration. [Test commands
  and limits](build.md#targets-and-tests).
