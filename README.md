# SDL3 for Idris 2

Thin bindings for games and multimedia applications. This initial version covers initialization,
windows, 2D rendering, BMP loading, and static and render-target textures.  It also covers keyboard,
mouse, text input, window-close events, and timers.  It does not yet bind streaming texture updates,
other image formats, audio streams, gamepads, or the GPU API.

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

`make run` creates a blue texture once and draws it in a fixed 640 by 480 scene.  Resizing preserves
the scene's width-to-height ratio and adds borders where needed. Close the window or press Escape to
exit.  `make test` uses SDL's dummy video driver, so it does not need a display.  Use `make test
CG=refc` for the secondary RefC compatibility test.  Use `make run-c` to build and run the example
with RefC.  This target is a shortcut for `make run CG=refc`.

## API and safety

Import `SDL3` for the typed API. `examples/Main.idr` shows an event loop and explicit cleanup.
`SDL3.Raw` is the unsafe foreign-function interface, which calls native C functions.  Do not use the
raw module unless you can enforce its pointer and lifetime requirements.

The typed API provides these guarantees:

- Distinct opaque types for windows, renderers, surfaces, textures, and event buffers.
- Texture access types that restrict render targets to `Texture TargetAccess`.
- Separate initialization and window flags, combined with `<+>` and empty flags through `neutral`.
- Null checks on resource creation, with errors returned as `Either String a`.
- Byte-sized color channels and fixed-width unsigned timer and flag values.
- Named event types, with unknown numeric event types preserved as `OtherEvent`.
- Distinct types for window identifiers, physical key positions, layout key values, and modifier
  bits.

The API does not enforce resource lifetimes or thread rules in the type system.  Call
initialization, window, rendering, and event functions on the main thread.  Do not share event
buffers between threads.

Destroy each texture before its renderer, and each renderer before its window.  Free each event
buffer exactly once. Destroy all owned resources before `quit`, and call `quit` even if
initialization fails.  Do not use or destroy a handle after destruction. This can access freed
memory.

Creation calls copy the error into `Left` on failure.  Rendering, initialization, and text input
start and stop controls return `Bool`, with `False` for failure.  Call `getError` immediately after
failure, on the same thread, before another SDL call can replace the error.

A logical resolution is a fixed coordinate size for drawing.  `setRenderLogicalPresentation renderer
width height mode` fits that size to the current target.  Use positive `Int32` dimensions for
enabled modes. The available modes are:

- `PresentationDisabled` uses the target's pixel resolution. Pass zero for width and height.
- `PresentationStretch` scales each axis to fill the target.
- `PresentationLetterbox` preserves the width-to-height ratio and adds borders.
- `PresentationOverscan` preserves the width-to-height ratio and crops excess content.
- `PresentationIntegerScale` uses integer scale factors to fit the target.

`setRenderScale renderer scaleX scaleY` applies additional scaling to drawing coordinates.  Use `1
1` to reset it. Values convert from Idris `Double` to SDL `float`.  Each target retains its own
scale and logical presentation state.  Configure only the intended targets to avoid scaling or
letterboxing an off-screen image twice.  Both controls require the main thread and return `False` on
failure.

These controls do not transform input events. Mouse event positions remain in window coordinates.
Event coordinate conversion is not yet bound. Do not treat mouse positions as logical drawing
coordinates.

A viewport is a drawing area with its own coordinate origin.  `setRenderViewport renderer (Just
(MkRect x y width height))` sets that area on the current render target.  Drawing starts at `(0, 0)`
within the viewport and clips to its bounds.  `Rect` uses signed 32-bit integers. Viewport width and
height must be nonnegative.  Use `setRenderViewport renderer Nothing` to restore the whole target.

`setRenderClipRect renderer (Just rect)` adds clipping relative to the viewport without moving the
drawing origin.  An empty clip rectangle blocks all drawing. `setRenderClipRect renderer Nothing`
disables this extra clipping, but does not remove viewport clipping.  Each render target retains its
own viewport and clip rectangle when you switch targets.  `clear` ignores both areas and clears the
entire current target. Use `fillRect` to clear only a drawing region.

`setDrawBlendMode renderer mode` selects blending for shapes such as filled rectangles, using the
same `BlendMode` type as textures.  It does not change texture blending. Use `setTextureBlendMode`
for that.  Viewport, clip, and draw blend controls require the main thread and return `False` on
failure.  Call `getError` immediately after failure. SDL can choose the closest supported draw blend
mode.

A render target is the destination for drawing commands.  `createTargetTexture renderer width
height` creates an RGBA32 texture for off-screen drawing.  Creation returns `Either String (Texture
TargetAccess)`. Dimensions must be positive 32-bit integers.  The texture starts with undefined
contents, so clear or draw into it before use.

`setRenderTarget renderer (Just texture)` directs drawing into a texture.  `setRenderTarget renderer
Nothing` restores the window as the destination.  `renderTexture renderer texture (Just (MkFRect x y
width height))` draws the whole source texture into the destination rectangle.  Pass `Nothing` as
the destination rectangle to use the whole current target.  Restore the window target before
`present`. Do not draw a texture into itself.

Use a texture only with its creating renderer. The types distinguish access modes but do not track
renderer identity or resource lifetimes.  SDL rejects textures from another renderer. Switch away
from a texture as the current target before `destroyTexture`.  All texture calls require the main
thread. Render targets retain separate SDL viewport, clipping, scaling, and presentation state.
Streaming texture creation and pixel updates are not yet exposed.

A surface stores image pixels in CPU memory. `loadBMP path` returns an owned `Surface` or a copied
SDL error.  `createTextureFromSurface renderer surface` copies those pixels into a `Texture
StaticAccess` on the main thread.  This call does not consume the surface. Call `destroySurface`
after conversion, on success or failure.  The texture remains usable after surface destruction. The
type system prevents using a static texture as a render target.  BMP loading can run on a worker
thread. Do not access a surface concurrently with conversion or destruction.

For example, this function loads a texture and releases its temporary surface:

```idris
loadImage : Renderer -> String -> IO (Either String (Texture StaticAccess))
loadImage renderer path = do
  Right surface <- loadBMP path | Left err => pure (Left err)
  result <- createTextureFromSurface renderer surface
  destroySurface surface
  pure result
```

`renderTextureRegion renderer texture source destination` draws part of a texture.  The `source` is
an `FRect` in texture pixel coordinates. The `destination` is a `Maybe FRect` in the current
target's rendering coordinates.  Pass `Nothing` as the destination to fill the current target.  This
supports sprite sheets, images that contain several smaller images, without copying each sprite into
a new texture.

Color modulation multiplies each source color channel during drawing.  `setTextureColorMod texture r
g b` uses byte values, with 255 preserving a channel and zero removing it.  `setTextureAlphaMod
texture alpha` multiplies source alpha, which controls opacity, by `alpha / 255`.  These controls do
not change the stored texture pixels. An alpha value of 255 preserves the original alpha, rather
than forcing opacity.

Blending combines source texture pixels with destination pixels. Use `setTextureBlendMode texture
mode` with one of these modes:

- `NoBlend` copies source color and alpha.
- `AlphaBlend` combines colors using source alpha.
- `PremultipliedAlphaBlend` uses source colors already multiplied by their alpha.
- `AdditiveBlend` adds source colors, scaled by source alpha, to destination colors.
- `PremultipliedAdditiveBlend` adds source colors without scaling them again.
- `ModulateBlend` multiplies source and destination colors.
- `MultiplyBlend` also preserves destination color based on source transparency.

With `AlphaBlend`, alpha modulation of zero makes the texture invisible.  Premultiplied modes
require correctly prepared pixels. The binding does not convert their color values.  When fading a
premultiplied texture, scale RGB and alpha together.  For example, use 128 for all three color
multipliers and for alpha to reduce both by approximately half.

Filtering selects source pixels when drawing a scaled texture.  `setTextureScaleMode texture
NearestScale` selects individual pixels, which suits pixel art.  `LinearScale` interpolates
neighboring pixels and is SDL's default.  All four texture controls require the main thread and
return `False` on failure.  Call `getError` immediately after failure. SDL can choose the closest
supported blend or scale mode, so failure does not guarantee unchanged state.  Custom blend modes
and queries for these texture settings are not yet exposed.

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

`setTextInputArea window (Just area)` supplies the text field bounds and cursor position to SDL.
Construct `area` with `MkTextInputArea x y width height cursorOffset`, using signed 32-bit window
coordinates.  The cursor offset is relative to `x`, not a character or byte index.  Update the area
when the field or cursor moves. The platform decides how to position the native input method window.
Use `setTextInputArea window Nothing` to clear the area.

`clearComposition window` dismisses native composition without disabling text input.  Clear the
application's composition display separately. Call both area controls and composition cancellation
on the main thread.  These calls return `False` on failure. Call `getError` immediately for details.

`TextInputEvent` contains committed text and its window identifier. Use this event for character
input instead of converting key codes.  An input method editor (IME) lets users compose characters.
`TextEditingEvent` contains unfinished composition text, its window identifier, and the selection
start and length.  Selection positions count characters, not bytes. A value of `-1` means unset.
Empty composition text clears the current composition. Do not append composition text to committed
text.

The binding copies SDL's UTF-8 text into an Idris `String` before the next poll.  These strings
remain valid after buffer reuse or destruction. `pollEvent` still returns only event types and does
not copy text.  Starting text input can show a screen keyboard or activate an IME, which can consume
key events. Candidate lists, text input properties, and querying the current text input area are not
yet bound.

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
Rendering rectangle values use Idris `Double` and convert to SDL `float` values on the C stack.
Text input areas use `Int32` fields and a stack-allocated SDL rectangle, with no extra native heap
allocation.  Text events allocate Idris strings when `pollEventData` copies their text. The C
adapter does not allocate an additional text buffer.

Create textures outside the frame loop and reuse them. Texture destination rectangles use stack
storage in the C adapter.  The example creates one target texture before its loop. The tests read
pixels back to compare rendered colors, but normal rendering does not.

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
creation, drawing, and timers. Texture tests read pixels from off-screen and window targets.  They
test destination rectangles, target reset, invalid dimensions, and rejection of textures from
another renderer. BMP tests create temporary image files and remove them after each test.  They test
missing and invalid files, pixel colors, source rectangles, and texture use after surface
destruction. Renderer tests cover viewport origins, clipping, empty clip rectangles, per-target
state, and shape alpha blending. They also test that `clear` ignores viewport and clip state.
Scaling tests cover every logical presentation mode, independent axis scaling, and scale and logical
state retained across target switches.  Pixel tests cover all exposed blend modes, color and alpha
modulation, and nearest and linear filtering.  Tests allow small rounding differences for fractional
blending and interpolation.  Compile-time tests reject mixed handle types, mixed flag types, forged
handles, and static textures used as render targets. Event tests cover keyboard data, repeat status,
window identifiers, timestamps, and data retained after buffer reuse. Mouse tests cover fractional
coordinates, relative motion, presses, releases, click counts, unknown buttons, and button-state
bits.  Wheel tests cover normal, flipped, and unknown directions, fractional values, pointer
position, and signed 32-bit limits. Text tests cover Unicode, empty and long text, composition
selections, string ownership, and per-window start and stop controls. Area tests compare the stored
SDL rectangle and cursor against the Idris values.  They also test area reset and composition
cancellation without disabling text input.  The test-only native library inserts known events into
SDL's queue. It is not part of the binding library.  The example builds in the test environment, but
interactive display behavior needs a manual test.

With the current RefC version, use equality tests for wide numeric values instead of numeric case
patterns.  Its generated case code can truncate those values. The event tests use values above 32
bits to test timestamp preservation.

Next work includes event coordinate conversion, streaming texture updates, audio streams, and scoped
resource ownership.  Keep each addition close to SDL's API and test its failure paths.  Measure call
overhead and allocations before adding performance claims or a larger abstraction layer.
