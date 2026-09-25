# SDL3 for Idris 2

Thin bindings for games and multimedia applications. This initial version covers initialization,
windows, basic 2D rendering, keyboard and mouse events, text input, window-close events, and timers.
It does not yet bind textures, audio streams, gamepads, or the GPU API.

The build uses the SDL3 headers in `/usr/local/include/SDL3` through `pkg-config`.  Chez is the
primary backend and the default for builds, examples, tests, and performance work.  RefC support is
secondary. We preserve compatibility where practical without limiting Chez support.  Tests run on
Linux with SDL 3.4.16 and Idris 2 0.8.0, using both Chez and RefC.  Other platforms are not
tested. The current C build produces a Linux shared library.

## Build and run

Install `pack`, a C compiler, Make, `pkg-config`, and SDL3 development files.  Use SDL 3.2.12 or
newer. Wheel events use the integer scroll fields added in that version.  The project pins the pack
collection in `pack.toml`. Run these commands from the project root:

```sh
pkg-config --modversion sdl3
pack --no-prompt --cg=chez build sdl3.ipkg
make test
make run
```

The package build hook compiles `cbits/libidris2_sdl3.so`.  `--no-prompt` permits this local build
hook without an interactive question.  The Makefile uses `pack` for all Idris builds and sets native
library search paths.

`make run` opens a window with a blue rectangle. Close the window or press Escape to exit.  `make
test` uses SDL's dummy video driver, so it does not need a display.  Use `make test CG=refc` for the
secondary RefC compatibility test.  Use `make run-c` to build and run the example with RefC.  This
target is a shortcut for `make run CG=refc`.

## API and safety

Import `SDL3` for the typed API. `examples/Main.idr` shows an event loop and explicit cleanup.
`SDL3.Raw` is the unsafe foreign-function interface, which calls native C functions.  Do not use the
raw module unless you can enforce its pointer and lifetime requirements.

The typed API provides these guarantees:

- Distinct opaque types for windows, renderers, and event buffers.
- Separate initialization and window flags, combined with `<+>` and empty flags through `neutral`.
- Null checks on resource creation, with errors returned as `Either String a`.
- Byte-sized color channels and fixed-width unsigned timer and flag values.
- Named event types, with unknown numeric event types preserved as `OtherEvent`.
- Distinct types for window identifiers, physical key positions, layout key values, and modifier
  bits.

The API does not enforce resource lifetimes or thread rules in the type system.  Call
initialization, window, rendering, and event functions on the main thread.  Do not share event
buffers between threads.

Destroy each renderer before its window. Free each event buffer exactly once.  Destroy all owned
resources before `quit`, and call `quit` even if initialization fails.  Do not use or destroy a
handle after destruction. This can access freed memory.

Creation calls copy the error into `Left` on failure.  Rendering, initialization, and text input
start and stop controls return `Bool`, with `False` for failure.  Call `getError` immediately after
failure, on the same thread, before another SDL call can replace the error.

`pollEvent` returns only event types. `pollEventData` also returns timestamps and supported event
data.  Both return `Nothing` for an empty queue. Each call consumes one event, so use one polling
function, not both for the same event.  Returned data remains valid after buffer reuse or
destruction.

`WindowCloseEvent` contains a window identifier. Use `getWindowID` to match it to a live window.
Identifiers do not own windows or extend their lifetimes. A zero identifier in an event means no
associated window.

`KeyboardEvent` contains the window identifier, press or release action, physical key position,
layout key value, modifier bits, and repeat status.  `Scancode` represents a physical key
position. `Keycode` represents a key value from the keyboard layout, not text input.  `escapeKey` is
the Escape key value. `KeyModifiers` contains SDL's modifier bits, such as Shift and Ctrl.

Text input is disabled by default. Call `startTextInput window` when a text field gains focus.  Call
`stopTextInput window` when editing ends, before you destroy the window.  Both functions require the
main thread. `textInputActive window` reports the window's current text input state.  A `False`
result from that query means inactive, not failure.

`TextInputEvent` contains committed text and its window identifier. Use this event for character
input instead of converting key codes.  An input method editor (IME) lets users compose characters.
`TextEditingEvent` contains unfinished composition text, its window identifier, and the selection
start and length.  Selection positions count characters, not bytes. A value of `-1` means unset.
Empty composition text clears the current composition. Do not append composition text to committed
text.

The binding copies SDL's UTF-8 text into an Idris `String` before the next poll.  These strings
remain valid after buffer reuse or destruction. `pollEvent` still returns only event types and does
not copy text.  Starting text input can show a screen keyboard or activate an IME, which can consume
key events.  Candidate lists, text input properties, and composition window positioning are not yet
bound.

`MouseMotionEvent` contains window and mouse identifiers, held button states, position, and relative
motion.  `MouseButtonEvent` contains window and mouse identifiers, the button, press or release
action, click count, and position.  Positions are relative to the window. Mouse coordinates preserve
SDL's fractional values as Idris `Double` values.

`MouseButton` stores a button index. `MouseButtons` stores a set of held buttons as bits.  Use
`buttonHeld leftButton buttons` to test a motion event's button state.  Named buttons include
`leftButton`, `middleButton`, `rightButton`, `x1Button`, and `x2Button`.  Unknown button indices and
state bits are preserved. `buttonHeld` returns `False` for indices outside 1 through 32.  `MouseID`
preserves SDL's device identifier, including synthetic touch and pen identifiers.

`MouseWheelEvent` contains window and mouse identifiers, fractional scroll values, scroll direction,
pointer position, and signed integer scroll values.  `scrollX` and `scrollY` preserve SDL's
fractional values. `integerX` and `integerY` contain SDL's accumulated whole scroll steps, not
rounded fractional values.  `mouseX` and `mouseY` locate the pointer relative to the window, not the
amount scrolled.

For `WheelNormal`, positive X means rightward and positive Y means away from the user.  For
`WheelFlipped`, negate the scroll values to convert to the normal direction.  The binding does not
change the values automatically. `OtherWheelDirection` preserves unknown numeric directions.

Event timestamps use nanoseconds since SDL initialization. `ticks` still uses milliseconds.
`UnknownEvent` preserves the timestamp and numeric type, but discards unsupported event data.
Keyboard device identifiers and platform-specific key codes are not exposed yet.

## Performance and native code

The C adapter converts SDL boolean results to C integers and accesses SDL's event union, which
stores different event layouts.  The compiler reads struct sizes and event constants from the
installed headers.  Static assertions compare the exposed flag constants with the Idris definitions.

Allocate an event buffer once and reuse it in the event loop.  The adapter performs no heap
allocation per draw or poll call. SDL and the Idris runtime can still allocate internally.
Rectangle values use Idris `Double` and convert to SDL `float` values on the C stack.  Text events
allocate Idris strings when `pollEventData` copies their text. The C adapter does not allocate an
additional text buffer.

No resource registry, finalizer, or automatic error-string copy runs on each successful rendering
call.  Event polling uses multiple native calls and constructs Idris values.  There are no
benchmarks yet, so this project does not claim zero overhead.

## Use from another package

Add this project as a local package in your application's `pack.toml`, then add `depends = sdl3` to
its `.ipkg` file.  The C library is separate from pack's Idris package installation.  Keep it
available when you run the application.

For Chez, include this project's `cbits` directory and the SDL library directory in
`LD_LIBRARY_PATH`.  Only RefC needs the additional compile and link configuration below.  Add those
library directories to `LIBRARY_PATH` and add `cbits` and the SDL include directory to `CPATH`.  Set
`IDRIS2_LDLIBS` to include `-lidris2_sdl3 -lSDL3`. The root Makefile sets these values when
`CG=refc`.

## Tests and next steps

The tests cover native event classification, unknown events, empty queues, flag combinations, window
creation, drawing, and timers.  Compile-time tests reject mixed handle types, mixed flag types, and
forged window handles. Event tests cover keyboard data, repeat status, window identifiers,
timestamps, and data retained after buffer reuse. Mouse tests cover fractional coordinates, relative
motion, presses, releases, click counts, unknown buttons, and button-state bits.  Wheel tests cover
normal, flipped, and unknown directions, fractional values, pointer position, and signed 32-bit
limits. Text tests cover Unicode, empty and long text, composition selections, string ownership, and
per-window start and stop controls.  The test-only native library inserts known events into SDL's
queue. It is not part of the binding library.  The example builds in the test environment, but
interactive display behavior needs a manual test.

With the current RefC version, use equality tests for wide numeric values instead of numeric case
patterns.  Its generated case code can truncate those values. The event tests use values above 32
bits to test timestamp preservation.

Next work includes text input positioning, textures, audio streams, and scoped resource ownership.
Keep each addition close to SDL's API and test its failure paths.  Measure call overhead and
allocations before adding performance claims or a larger abstraction layer.
