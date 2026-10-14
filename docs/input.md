# Input and events

Import `SDL3` for event polling and input controls. It also exports the types in `SDL3.Events`.
Initialize `video` for window input. Process events on the main thread and use one reusable
`EventBuffer` per polling loop.

## Polling and waiting

Create a buffer with `newEventBuffer` and release it with `freeEventBuffer`.  Alternatively, put the
loop inside `withEventBuffer` from `SDL3.Scoped`.  `pollEvent` returns only event
types. `pollEventData` returns timestamps and supported payloads.  Both return `Nothing` when no
event is returned. Each successful call consumes one event, so do not use both functions to read the
same event.

`waitEventData buffer` blocks until an event arrives and returns `Either String Event`.
`waitEventDataTimeout buffer timeoutMS` returns `Either String (Maybe Event)`.  `Right Nothing`
means no event arrived before the wait ended, without an SDL error.  Timeouts use `Bits32`
milliseconds from 0 through 2147483647. Zero does not wait.  Larger values return `Left` without
consuming an event.

Timed waits clear the previous SDL error, so read any earlier error first.  Actual waits can exceed
their timeout. Waiting blocks drawing on the same thread.  Use polling when the application must
render continuously. A wait already returns the decoded event, so poll afterward only for further
events.

Returned payloads are copied and survive buffer reuse or destruction.  Timestamps count nanoseconds
since SDL initialization, as does `ticksNS`.  `OtherEvent` preserves an unsupported numeric type in
type-only polling.  `UnknownEvent` preserves a timestamp and numeric type, but not unsupported
payload fields.

## Window notifications

`QuitEvent` requests application shutdown. `WindowCloseEvent` identifies a window that the user
requested to close. Match its `WindowID` against `getWindowID` on live windows.  An identifier does
not own a window, and zero means no associated window.  A close notification does not release your
resources.

Movement and size notifications carry copied records:

- `WindowMovedEvent`: `WindowPositionData` contains `windowID` and signed `x` and `y` placement
  coordinates.
- `WindowResizedEvent`: `WindowSizeData` contains dimensions in window coordinates.
- `WindowPixelSizeChangedEvent`: `PixelSizeData` contains dimensions in physical pixels.

Both size records contain `windowID`, `width`, and `height` with signed dimensions.  Do not assume
window and pixel dimensions are equal or that both events arrive together.  If dimensions are
non-positive, skip size-dependent drawing or allocation.  Window placement coordinates are not mouse
positions or renderer points.

The following notifications carry a timestamp and window identifier:

- `WindowDisplayScaleChangedEvent`: Query current density and display scale when updating layout.
- `WindowFocusGainedEvent` and `WindowFocusLostEvent`: Update application keyboard-focus state.
- `WindowMouseEnterEvent` and `WindowMouseLeaveEvent`: Update mouse-focus or hover state.
- `WindowMinimizedEvent`, `WindowMaximizedEvent`, and `WindowRestoredEvent`: Report size-state
  changes, without dimensions.
- `WindowShownEvent` and `WindowHiddenEvent`: Report visibility changes, not whether another window
  covers it.
- `WindowExposedEvent`: Redraw from application state. It carries no damaged rectangle.
- `WindowEnterFullscreenEvent` and `WindowLeaveFullscreenEvent`: Report transitions, without display
  modes or dimensions.

Notifications describe past changes, not guaranteed current state. Do not assume a fixed order
between movement, sizing, focus, and scale events. The binding does not clear held keys, pause
rendering, recreate textures, or change layout automatically.  On lost focus, clear application
input state if your interaction requires it.

## Keyboard input

`KeyboardEvent` contains `KeyboardData`: window identifier, action, physical key position, layout
key value, modifier bits, and repeat status. `Pressed` and `Released` describe the action.
`Scancode` identifies a physical key position. `Keycode` identifies a layout key, not entered text.
`escapeKey` is the Escape key value. `KeyModifiers` retains SDL's modifier bits.

Use key events for controls and shortcuts, not character entry.  The binding does not maintain a
held-key map. Decide how your application handles repeats and focus loss. Keyboard device
identifiers and platform-specific key codes are not exposed.

## State snapshots

`newKeyboardSnapshot` allocates a reusable copy of SDL keyboard state. Release it with
`freeKeyboardSnapshot` or use `withKeyboardSnapshot`.  After polling, `refreshKeyboardSnapshot`
copies current state without consuming events or allocating a new native array.  If the application
does not poll or wait, call `pumpEvents` first. Use these operations on the main thread.

`keyDown snapshot scancode` reads the last copied state. Unknown scancodes return `False`.  The
snapshot is not a live view and does not apply an application action map.  Keep keyboard events for
brief presses and releases between snapshots. Text entry still requires text input events.

`newMouseStateBuffer` allocates reusable query storage. Release it with `freeMouseStateBuffer` or
use `withMouseStateBuffer`.  `getMouseState buffer` returns copied button bits and a `Point
WindowSpace` for the window with mouse focus.  It does not query an arbitrary window. Pump events
before querying, and convert positions explicitly for rendering.

`getRelativeMouseState buffer` returns copied button bits and relative `dx` and `dy` values.  Each
call resets accumulated motion since the previous relative-state query. It does not consume motion
events.  Do not count the same motion from both sources. Mouse queries return `Either String` and
use the main thread.

Keep all query storage alive during access, and do not share it concurrently between threads.
Copied mouse results survive buffer reuse and cleanup. Keyboard reads require the live snapshot.
The scoped forms clean up only after ordinary callback returns, under the [resource
rules](resources.md).

## Text entry

Text input is disabled by default. Call `startTextInput window` when a text field gains focus and
`stopTextInput window` when editing ends, before window destruction.  `textInputActive` reports
state, not success. Starting text input can activate a screen keyboard or an input method editor,
which lets users compose characters.

`TextInputEvent` carries committed text and its window identifier.  `TextEditingEvent` carries
unfinished composition text, selection start, and selection length.  Selection positions count
characters, not bytes. A value of `-1` means unset.  Empty composition clears the application
composition display. Do not append unfinished composition to committed text.

`setTextInputArea window (Just area)` supplies field bounds and cursor position.  Use
`MkTextInputArea x y width height cursorOffset` in signed window coordinates.  The cursor offset is
relative to `x`, not a character index. Update it when the field or cursor moves. `Nothing` clears
the area. The platform controls native input-window placement.

`clearComposition window` dismisses native composition without disabling text input.  Clear your
application's composition display separately. Text controls require the main thread.  After a
control returns `False`, read `getError` immediately.  The returned Idris strings copy SDL's UTF-8
text and survive buffer reuse.

## Mouse input

`MouseMotionEvent` reports window and mouse identifiers, held buttons, position, and relative
motion.  `MouseButtonEvent` reports identifiers, button, action, click count, and position.
Positions are window-relative and preserve SDL's fractional values as `Double`.  Convert positions
explicitly when drawing uses a different coordinate space.  See [coordinate
conversion](rendering.md#coordinate-conversion).

`MouseButton` stores one button index, while `MouseButtons` stores held-button bits.  Use
`buttonHeld leftButton buttons` to test the state from a motion event.  Named buttons are
`leftButton`, `middleButton`, `rightButton`, `x1Button`, and `x2Button`.  Unknown indices and bits
are preserved. Indices outside 1 through 32 test as not held.  `MouseID` also preserves synthetic
touch and pen identifiers.

`MouseWheelEvent` reports fractional scrolling, whole scroll steps, direction, and pointer position.
`scrollX` and `scrollY` are fractional amounts. `integerX` and `integerY` are accumulated whole
steps, not rounded fractions. `mouseX` and `mouseY` are pointer positions, not scroll amounts.  For
`WheelNormal`, positive X means rightward and positive Y means away from the user.  For
`WheelFlipped`, negate scrolling values to use normal direction.  `OtherWheelDirection` preserves
unknown direction codes.

## Renderer reset events

`RenderTargetsResetEvent timestamp windowID` reports that render-target contents need to be redrawn.
`RenderDeviceResetEvent timestamp windowID` reports that textures need to be recreated.  Type-only
polling uses `RenderTargetsReset` and `RenderDeviceReset`. Both poll and wait paths copy timestamps
and identifiers.

Update exhaustive event matches for these constructors. The binding does not recreate resources or
reload assets automatically.  Match the window identifier and apply the relevant renderer and
extension recovery rules.  Other unsupported renderer events remain `OtherEvent` or `UnknownEvent`.

## Mouse grab

Mouse grab requests confinement of the cursor to a window.  `setWindowMouseGrab window True`
requests confinement, and `False` requests release.  Provide a release or exit action before
enabling it. Release the grab when the interaction no longer needs it, while the window is still
alive.

`getWindowMouseGrab` reports SDL's active state, not setter success.  Focus changes and grabs on
other windows can change that state.  A hidden window can accept a request without an active
grab. Mouse grab alone does not enable capture, relative mode, or keyboard grab.  A reported grab
does not prove physical confinement on every backend.

## Relative mouse mode and capture

`setWindowRelativeMouseMode window enabled` requests continuous relative movement.  While the window
has focus, SDL hides and confines the cursor and reports movement even at window edges. Read `dx`
and `dy` from `MouseMotionEvent` rather than converting them as positions.  Changing this mode
flushes pending mouse motion for that window.

`getWindowRelativeMouseMode` reports whether the mode is enabled, not whether the window has focus.
`captureMouse True` instead requests mouse events outside the current window without hiding or
confining the cursor. Capture is temporary and backend-dependent. SDL releases it on focus loss and
can also capture automatically during a mouse drag.

Use these controls on the main thread. Provide an exit action, disable relative mode when no longer
needed, and release explicit capture with `captureMouse False`. Read `getError` immediately after a
failed request. Successful dummy-driver calls do not establish physical mouse behavior.

## Cursors

`createSystemCursor shape` creates an owned cursor. `SystemCursor` includes arrow, text, wait,
crosshair, pointer, movement, and resize shapes. `setCursor (Just cursor)` selects one.  `setCursor
Nothing` selects SDL's default cursor, rather than requesting a redraw with a null pointer.  Cursor
selection is shared SDL state, not a property of one window.

`showCursor` and `hideCursor` return success booleans. `cursorVisible` returns state.  Relative
mouse mode can hide the cursor regardless of the normal visibility setting.  Use all cursor
operations on the main thread. Backends without cursor support can reject creation.

Select another cursor before calling `destroyCursor`, then release it exactly once before `quit`.
`withSystemCursor shape action` owns a cursor without selecting it or restoring previous selection.
Select another cursor before its callback returns. Do not destroy or retain the supplied handle.
Custom image cursors and cursor animation are not bound.

## Clipboard text

`setClipboardText text` copies UTF-8 text to the clipboard. Embedded NUL ends the text.
`getClipboardText` returns a copied string through `Either String` and releases SDL's temporary
copy.  Empty text is valid. The getter clears an earlier SDL error to distinguish empty text from
failure, so read earlier errors before calling it.

`hasClipboardText` reports whether nonempty text is available, not operation success.  Use all
clipboard calls on the main thread. Other applications can change the clipboard at any time.  Only
text is supported. Primary selection, arbitrary formats, and clipboard callbacks are not bound.

## File and text drops

Payload polling and both wait APIs decode file-drop events:

- `DropFileEvent timestamp data`: A file-open request. `data.text` contains the filename.
- `DropTextEvent timestamp data`: Dropped text in `data.text`.
- `DropPositionEvent timestamp data`: Position during dragging, with empty `data.text`.
- `DropBeginEvent timestamp windowID`: A group of drops begins.
- `DropCompleteEvent timestamp windowID`: The group ends.

`DropData` contains `windowID`, window-relative `x` and `y`, copied `source`, and copied `text`.
Empty source means no source name was supplied. Begin and complete events expose only a window ID,
not coordinates. Type-only polling uses the same names without the `Event` suffix.

The decoder copies SDL's strings before the next poll or wait. Do not free SDL's event pointers.
The returned data survives buffer reuse and cleanup. Match the window ID against a live window and
treat dropped paths and text as untrusted input. The binding does not open files or validate paths
automatically. Gamepad notifications are described in the [gamepad guide](gamepads.md).

## Ownership, examples, and tests

Do not share an event buffer between threads. Allocate it outside the loop and free it exactly
once. Keep windows alive through their input-control calls.  See [resource ownership](resources.md)
for scoped cleanup limits.

[Hello](../examples/Hello.idr) handles close, Escape, and mouse-button events.  `make test` covers
copied events, clipboard text, drops, identifiers, waits, and buffer reuse. Synthetic events test
decoding rather than real input devices or window-manager policy.  Physical input, input methods,
screen keyboards, and cursor confinement need manual testing.
