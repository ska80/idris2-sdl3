# Input and events

Initialize `video`. Use the main thread. `SDL3` re-exports `SDL3.Events`.  [Resource/error
rules](resources.md). Allocate one reusable `EventBuffer` per loop.

## Polling and waiting

| API | Result |
| --- | --- |
| `pollEvent buffer` | `Maybe EventType`. Type only |
| `pollEventData buffer` | `Maybe Event`. Copied payload |
| `waitEventData buffer` | `Either String Event`. Blocks |
| `waitEventDataTimeout buffer timeoutMS` | `Either String (Maybe Event)`. `Right Nothing` is timeout without an SDL error |

- Each successful call consumes one event. Do not poll both APIs for the same event. A wait already
  returns it.
- Timeouts: `Bits32` milliseconds, 0..2147483647. Zero does not wait. Oversized values fail without
  consuming an event.
- Timed waits clear stale SDL errors. Read earlier errors first. Actual waits can exceed the timeout
  and block drawing.
- Timestamps: nanoseconds since SDL initialization, like `ticksNS`. Copied payloads survive buffer
  reuse/cleanup.
- `OtherEvent code` / `UnknownEvent timestamp code` preserve unsupported types, not unsupported
  payload fields.
- Storage: `newEventBuffer` / `freeEventBuffer`, or `withEventBuffer` around the loop.

## Window notifications

| Event | Payload / action |
| --- | --- |
| `QuitEvent` | Shutdown request |
| `WindowCloseEvent` | Window ID. Request only, no automatic cleanup |
| `WindowMovedEvent` | `WindowPositionData`: ID, signed x/y desktop placement |
| `WindowResizedEvent` | `WindowSizeData`: ID, signed dimensions in window units |
| `WindowPixelSizeChangedEvent` | `PixelSizeData`: ID, signed physical-pixel dimensions |
| `WindowDisplayScaleChangedEvent` | Requery scale/density |
| `WindowFocusGainedEvent`, `WindowFocusLostEvent` | Keyboard-focus change |
| `WindowMouseEnterEvent`, `WindowMouseLeaveEvent` | Mouse-focus change |
| `WindowMinimizedEvent`, `WindowMaximizedEvent`, `WindowRestoredEvent` | State change, no dimensions |
| `WindowShownEvent`, `WindowHiddenEvent`, `WindowExposedEvent` | Visibility/redraw notification. No damaged rectangle |
| `WindowEnterFullscreenEvent`, `WindowLeaveFullscreenEvent` | Transition, no display-mode details |

- Events from display-scale through fullscreen carry timestamp and window ID. Match IDs against live
  windows. Zero means no associated window.
- Notifications describe past changes, without guaranteed ordering. They do not own windows or
  change application layout/input state.
- Window/pixel dimensions can differ. Resize events need not arrive together. Skip size-dependent
  work for non-positive dimensions.
- Decide application behavior for focus loss, repeats, pausing, and held controls.

## Keyboard input and state snapshots

| API / payload | Contract |
| --- | --- |
| `KeyboardData` | Window ID, `Pressed`/`Released`, `Scancode`, `Keycode`, `KeyModifiers`, repeat flag |
| `newKeyboardSnapshot`, `freeKeyboardSnapshot`, `withKeyboardSnapshot` | Reusable copy, not a live view |
| `refreshKeyboardSnapshot` | Copy current SDL state without pumping or consuming events |
| `keyDown snapshot scancode` | Last copied state. Unknown scancodes return `False`. Requires live snapshot |
| `pumpEvents` | Refresh SDL input without consuming queued events |

- Poll/wait normally, or call `pumpEvents` before state queries.
- `Scancode`: physical key position. `Keycode`: layout key, not entered text. `escapeKey`: Escape
  key value.
- Keep events for brief presses/releases between snapshots. Use text events for character entry.
- No application action map, keyboard-device IDs, or platform-specific key codes.

## Text entry

| API / payload | Contract |
| --- | --- |
| `startTextInput window`, `stopTextInput window` | Disabled initially. Stop before window destruction |
| `textInputActive` | State, not success |
| `TextInputEvent` | Committed UTF-8 text and window ID |
| `TextEditingEvent` | Unfinished composition, selection start/length in characters, not bytes. -1 means unset |
| `setTextInputArea window (Just area)` | `MkTextInputArea x y width height cursorOffset`, signed window coordinates. Offset relative to x |
| `setTextInputArea window Nothing` | Clear the input area |
| `clearComposition window` | Dismiss composition without stopping text input |

Do not append unfinished composition to committed text. Empty composition clears its application
display.  Starting input can activate a screen keyboard or input method editor. Platform placement
remains outside binding control.

## Mouse input

| Payload / query | Contract |
| --- | --- |
| `MouseMotionEvent` | Window/mouse IDs, held buttons, fractional position, relative dx/dy |
| `MouseButtonEvent` | IDs, button, action, click count, position |
| `MouseWheelEvent` | Fractional scroll, accumulated integer steps, direction, pointer position |
| `getMouseState buffer` | Copied buttons and `Point WindowSpace` for the window with mouse focus |
| `getRelativeMouseState buffer` | Copied buttons and motion since the previous relative-state query. Resets that shared SDL motion state |

- Storage: `newMouseStateBuffer` / `freeMouseStateBuffer`, or `withMouseStateBuffer`. Queries return
  `Either String`.
- Mouse queries do not consume motion events. Do not count the same motion from both sources.
- [Convert positions](rendering.md#coordinate-conversion) for rendering. Relative deltas are not
  positions.
- `MouseButton` is an index. `MouseButtons` is a bitset. Use `buttonHeld leftButton
  buttons`. Indices outside 1..32 return `False`.
- Named buttons: `leftButton`, `middleButton`, `rightButton`, `x1Button`, `x2Button`. Unknown
  codes/bits and synthetic mouse IDs survive decoding.
- Wheel integer steps are not rounded fractional fields. `mouseX`/`mouseY` are positions, not scroll
  distances.
- `WheelNormal`: positive X right, positive Y away from the user. Negate `WheelFlipped`
  values. Preserve `OtherWheelDirection code`.

## Mouse grab

| Control | Effect |
| --- | --- |
| `setWindowMouseGrab`, `getWindowMouseGrab` | Request/report confinement. Focus-dependent, separate from relative mode and capture |
| `setWindowRelativeMouseMode`, `getWindowRelativeMouseMode` | Hide/confine while focused. Continuous movement. Mode changes flush pending window motion |
| `captureMouse` | Request outside-window events without hiding/confining. SDL releases capture on focus loss |

Provide an exit action before enabling capture or confinement. Disable/release while the window
remains alive.  Flags and successful requests do not prove physical behavior. A hidden window can
accept a grab without activating it.

## Cursors and clipboard

- `createSystemCursor shape`, `destroyCursor`, `withSystemCursor`: owned system cursor. Select
  another before cleanup.
- `setCursor (Just cursor)` selects globally. `setCursor Nothing` selects the default, not SDL's
  null-pointer redraw behavior.
- `showCursor`, `hideCursor`, `cursorVisible`: relative mode can override visible state. Unsupported
  backends can reject creation.
- `setClipboardText` copies text. `getClipboardText` copies/frees SDL storage and clears stale
  errors to distinguish empty success from failure.
- `hasClipboardText` reports nonempty text availability. Other applications can change it at any
  time.
- No custom/animated cursors, primary selection, arbitrary clipboard formats, or clipboard
  callbacks.

## File and text drops

| Event | Payload |
| --- | --- |
| `DropFileEvent` | `DropData.text` is a filename |
| `DropTextEvent` | `DropData.text` is dropped text |
| `DropPositionEvent` | Position during dragging. Empty text |
| `DropBeginEvent`, `DropCompleteEvent` | Timestamp and window ID only |

`DropData`: window ID, window-relative x/y, copied source/text. Empty source means absent.  Do not
free SDL event pointers. Treat paths/text as untrusted. The binding neither opens files nor
validates paths.

## Renderer reset events

- `RenderTargetsResetEvent timestamp windowID`: redraw target contents.
- `RenderDeviceResetEvent timestamp windowID`: recreate textures under the applicable
  renderer/extension rules.
- Type-only forms: `RenderTargetsReset`, `RenderDeviceReset`. Update exhaustive matches. Recovery is
  not automatic.

Gamepad payloads: [gamepads](gamepads.md#events). Example: [Hello](../examples/Hello.idr). [Run
commands](build.md#examples).
