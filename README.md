# SDL3 for Idris 2

Thin bindings for games and multimedia applications. This initial version covers initialization,
windows, 2D rendering, BMP loading, and static, streaming, and render-target textures.  It also
covers keyboard, mouse, text input, window-close and size-change events, and timers.  It does not
yet bind other image formats, audio streams, gamepads, or the GPU API.

The build uses the SDL3 headers in `/usr/local/include/SDL3` through `pkg-config`.  Chez is the only
supported backend. Tests run on Linux with SDL 3.4.16 and Idris 2 0.8.0.  Other platforms are not
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

`make run` creates a blue texture once and draws it with a pale outline in a fixed 640 by 480 scene.
Resizing preserves the scene's width-to-height ratio and adds borders where needed.  Close the
window, press Escape, or left-click the blue rectangle to exit.  The example converts click
positions into scene coordinates, including after resizing.  `make test` uses SDL's dummy video
driver, so it does not need a display. The Makefile rejects backends other than Chez.

## API and safety

Import `SDL3` for the typed API. `examples/Main.idr` shows an event loop, callback-based cleanup,
and scoped texture cleanup. `SDL3.Raw` is the unsafe foreign-function interface, which calls native
C functions.  Do not use the raw module unless you can enforce its pointer and lifetime
requirements.

The typed API provides these guarantees:

- Distinct opaque types for windows, renderers, surfaces, textures, event buffers, coordinate
  buffers, point buffers, and rectangle buffers.
- Distinct point types for window and render coordinates.
- Texture access types that restrict render targets to `Texture TargetAccess`.
- Separate initialization and window flags, combined with `<+>` and empty flags through `neutral`.
- Null checks on resource creation, with errors returned as `Either String a`.
- Byte-sized color channels and fixed-width unsigned timer and flag values.
- Named event types, with unknown numeric event types preserved as `OtherEvent`.
- Distinct types for window identifiers, physical key positions, layout key values, and modifier
  bits.

The API does not enforce resource lifetimes or thread rules in the type system.  Call
initialization, window, rendering, and event functions on the main thread.  Do not share event or
coordinate, point, or rectangle buffers between threads.

Destroy each texture before its renderer, and each renderer before its window.  Free each event
buffer, coordinate buffer, point buffer, and rectangle buffer exactly once. Destroy all owned
resources before `quit`, and call `quit` even if initialization fails.  Do not use or destroy a
handle after destruction. This can access freed memory.

Creation calls copy the error into `Left` on failure.  Rendering, initialization, and text input
start and stop controls return `Bool`, with `False` for failure.  Call `getError` immediately after
failure, on the same thread, before another SDL call can replace the error.

Import `SDL3.Scoped` for optional cleanup helpers. A callback is the function that receives the
resource.  Each resource helper creates a resource, calls your function, and releases it after the
function returns.  The available helpers are:

- `withWindow title width height flags action` creates and destroys a window.
- `withRenderer window action` creates and destroys a renderer.
- `withStreamingTexture renderer width height action` creates and destroys a streaming texture.
- `withTargetTexture renderer width height action` creates and destroys a target texture without
  selecting it for drawing.
- `withTextureFromSurface renderer surface action` creates and destroys a static texture. The caller
  still owns the surface.
- `withEventBuffer action` allocates and frees an event buffer.
- `withCoordinateBuffer action` allocates and frees a coordinate buffer.
- `withPointBuffer capacity action` allocates and frees a point array for batched drawing.
- `withRectBuffer capacity action` allocates and frees a rectangle array for batched drawing.
- `withBMP path action` loads and destroys a BMP surface.

The callback returns `IO (Either String a)`. Cleanup runs after both `Right` and `Left`, and the
helper preserves the callback's result.  If creation fails, the helper returns `Left` without
running the callback.  Copy SDL errors with `getError` inside the callback, before cleanup can
replace them.  Runtime exceptions, process exit, and callbacks that never return do not guarantee
cleanup.  These helpers do not catch exceptions or enforce resource lifetimes in the type system.

Do not destroy the supplied resource yourself or retain it after the callback returns.  Do not
return functions or store references that use the resource after cleanup. They can access freed
memory.  Destroy dependent resources before returning. Nest renderer helpers inside window helpers,
and destroy textures before the renderer callback returns.  Call `quit` only after all resource
helpers return. The original thread rules still apply.  Copied events and points, and textures
copied from a surface, can outlive the corresponding buffer or surface helper.

Keep buffer helpers around the event loop, not inside each frame or event handler.  Each helper
entry creates a new resource. These resource helpers do not cache resources or restore rendering
state. Keep texture helpers inside the creating renderer's lifetime.  Use `withRenderTarget` inside
the `withTargetTexture` callback for temporary target selection.  The selection scope must finish
before the texture is destroyed. Do not leave the supplied texture selected when the callback
returns. If target restoration fails, do not assume the previous target is active. The ownership
helper still destroys its texture after an ordinary callback return.  The example keeps one target
texture alive around the entire event loop.

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
Allocate a reusable buffer with `newCoordinateBuffer` to convert positions explicitly.
`renderCoordinatesFromWindow renderer buffer point` converts a `Point WindowSpace` into a `Point
RenderSpace`.  `renderCoordinatesToWindow` performs the inverse conversion. Both return a copied
point or an SDL error through `Either`.  Construct input points with `MkPoint x y`, using the
event's position values.

Conversion uses SDL's window dimensions, logical presentation, drawing scale, and viewport state.
Call on the main thread with the intended render target selected.  For multiple windows, match the
event's `WindowID` to the renderer before conversion.  Points outside the scene are not clamped, and
clipping does not restrict conversion.  Compare the returned position with your scene bounds before
handling a click.

Reuse the buffer for later conversions, then call `freeCoordinateBuffer` during cleanup.  Returned
points retain their values after buffer reuse or destruction.  Conversions do not modify event
records or convert relative motion values. They convert positions, not movement distances.  The
point types distinguish coordinate spaces, but do not track renderer identity or later changes to
rendering state.

The buffer owns a native struct with two C `double` fields. The C adapter converts SDL's
single-precision results into these fields. Chez reads them directly, without separate C getter
calls. This changes storage, not SDL's calculation precision. Allocate the buffer once, outside the
loop. The raw coordinate bindings now use a typed struct pointer instead of `AnyPtr`.

A viewport is a drawing area with its own coordinate origin.  `setRenderViewport renderer (Just
(MkRect x y width height))` sets that area on the current render target.  Drawing starts at `(0, 0)`
within the viewport and clips to its bounds.  `Rect` uses signed 32-bit integers. Viewport width and
height must be nonnegative.  Use `setRenderViewport renderer Nothing` to restore the whole target.

`setRenderClipRect renderer (Just rect)` adds clipping relative to the viewport without moving the
drawing origin.  An empty clip rectangle blocks all drawing. `setRenderClipRect renderer Nothing`
disables this extra clipping, but does not remove viewport clipping.  Each render target retains its
own viewport and clip rectangle when you switch targets.  `clear` ignores both areas and clears the
entire current target. Use `fillRect` to clear only a drawing region.

`drawPoint renderer (MkPoint x y)` draws one point. The point type is `Point RenderSpace`.
`drawLine renderer start end` draws a line between two points in the same coordinate space.
Window-coordinate points must first be converted with `renderCoordinatesFromWindow`.

`drawRect renderer (Just (MkFRect x y width height))` draws a rectangle outline, not a filled
rectangle.  Pass `Nothing` to use SDL's default rectangle for a full-target outline.  `fillRect
renderer x y width height` remains the filled-rectangle call.

These shapes use the current drawing color and blend mode.  Viewport, clipping, drawing scale, and
logical presentation also apply.  Coordinates convert from `Double` to SDL `float`. Exact fractional
pixel coverage depends on SDL's rendering backend.  Each call requires the main thread and returns
`False` on failure. Read `getError` immediately after failure.  The adapters allocate no native heap
memory.

`newPointBuffer capacity` creates a reusable array of SDL floating-point positions and returns
`Either String PointBuffer`. Capacity is a `Bits32` value from 1 through 2147483647, subject to
native memory limits. Allocation size arithmetic is checked before allocation. All entries start at
`(0, 0)`. The buffer has fixed capacity and does not grow.

`setPoint buffer index point` replaces one zero-based entry with a `Point RenderSpace`.  It returns
`False` for an index outside capacity, without changing any entry.  Coordinates narrow from `Double`
to SDL `float`, as with scalar drawing. Use finite coordinates that fit SDL floats. The point type
does not track renderer identity or later rendering-state changes.

`drawPoints renderer buffer count` draws the first `count` entries independently.  `drawLines
renderer buffer count` joins consecutive entries into `count - 1` connected segments when `count` is
at least two. It does not close the path automatically. Repeat the first point at the end to close a
path. Counts use `Bits32` and cannot exceed capacity. An excessive count returns `False` before SDL
reads the array or draws anything. Zero points and fewer than two line points succeed without
drawing on a valid renderer.

Both draw calls use the current target, color, blend mode, viewport, clip, scale, and logical
presentation. Call them on the main thread. SDL consumes the input during the call, so the buffer
can be rewritten, reused with another renderer, or freed after the call returns.  Do not mutate or
free it while a draw is in progress. Unwritten entries remain valid zero points, not an indication
that they are outside the draw count.

Allocate the buffer outside the frame loop, then call `freePointBuffer` once during cleanup.
Alternatively, put the loop inside `withPointBuffer capacity`. This resource owns only CPU memory,
not a renderer. The write and draw adapters allocate no new point arrays.  Each `setPoint` still
makes one foreign call. Each batch uses one foreign draw call, but SDL can allocate internal command
storage and perform multiple GPU operations. This API does not promise a speed increase. See
`test/src/BatchTests.idr` for buffer reuse and scope examples.

`newRectBuffer capacity` creates a separate reusable array of SDL floating-point rectangles and
returns `Either String RectBuffer`. Capacity uses `Bits32` and must be from 1 through 2147483647,
subject to memory limits. Allocation size arithmetic is checked. Every entry starts as `MkFRect 0 0
0 0`. The buffer has fixed capacity and does not grow.

`setRect buffer index rect` replaces a zero-based entry with an `FRect` in drawing coordinates.  An
out-of-range index returns `False` without changing entries. Fields narrow to SDL `float`.  Use
finite values that fit that type. Width and height receive no extra validation.  Zero-size and
negative-size rectangles follow SDL semantics, as with scalar rectangle drawing.  `FRect` does not
track a coordinate space or renderer identity.

`drawRects renderer buffer count` outlines the first `count` rectangles.  `fillRects renderer buffer
count` fills them. Count uses `Bits32` and cannot exceed capacity.  An excessive count returns
`False` before SDL reads the array or draws anything. Zero count succeeds without drawing on a valid
renderer. Unlike `drawRect renderer Nothing`, an array entry cannot request an implicit full-target
rectangle. Unwritten entries are zero-valued rectangles, not skipped entries, so choose the count
explicitly.

Both calls require the main thread and use the current rendering state, including clipping and
logical presentation. SDL consumes the input during the call. Reuse, rewrite, or free the buffer
after the call returns, not during a draw. The buffer owns CPU memory and can serve different
renderers. It must not be shared between threads.

Allocate outside the frame loop and call `freeRectBuffer` once during cleanup, or put the loop
inside `withRectBuffer capacity`. The write and draw adapters allocate no new rectangle arrays.
Each write still makes one foreign call, and each batch makes one foreign draw call. SDL can
allocate command storage and perform multiple GPU operations, so no speed increase is promised.  See
`test/src/RectBatchTests.idr` for examples and failure cases.

`setDrawBlendMode renderer mode` selects blending for shapes such as filled rectangles, using the
same `BlendMode` type as textures.  It does not change texture blending. Use `setTextureBlendMode`
for that.  Viewport, clip, and draw blend controls require the main thread and return `False` on
failure.  Call `getError` immediately after failure. SDL can choose the closest supported draw blend
mode.

`getDrawBlendMode renderer` returns `IO (Either String BlendMode)` for shape drawing.  It does not
query texture blending. Call it on the main thread while the renderer and its window remain
alive. The result is copied and can outlive the renderer. Unknown and custom codes use
`OtherBlendMode`, as with texture queries. The adapter uses one stack mode value and returns the
unsigned 32-bit code through a signed 64-bit integer, with -1 reserved for failure.

`withDrawBlendMode renderer mode action`, exported by `SDL3.Scoped`, saves draw blending and
attempts restoration after an ordinary `Right` or `Left` return. Nested scopes save their own entry
mode. Draw blending belongs to the renderer, so target switches do not restore it.  The helper does
not restore draw color, texture state, viewport, clipping, or target selection.  It does not create
or destroy resources. Keep the renderer and its window alive on the main thread.

A failed query skips the action. A failed setting also skips the action but still triggers
restoration. Setting and action errors take precedence over restoration errors. If only restoration
fails, the helper returns that SDL error. A `Left` result does not guarantee restoration, and SDL
can select the closest supported mode. Runtime exceptions, process exit, and actions that never
return do not guarantee restoration either.

A successful scope makes three foreign state calls in addition to its action. It uses no native heap
storage for the saved mode. Use `withTextureBlendMode` for texture blending instead.

A render target is the destination for drawing commands.  `createTargetTexture renderer width
height` creates an RGBA32 texture for off-screen drawing.  Creation returns `Either String (Texture
TargetAccess)`. Dimensions must be positive 32-bit integers.  The texture starts with undefined
contents, so clear or draw into it before use.

`setRenderTarget renderer (Just texture)` directs drawing into a texture.  `setRenderTarget renderer
Nothing` restores the window as the destination.  `renderTexture renderer texture (Just (MkFRect x y
width height))` draws the whole source texture into the destination rectangle.  Pass `Nothing` as
the destination rectangle to use the whole current target.  Restore the window target before
`present`. Do not draw a texture into itself.

`withRenderTarget renderer target action`, exported by `SDL3`, temporarily selects a render target.
Pass `Just texture` for a target texture or `Nothing` for the window.  The action returns `IO
(Either String a)`. The helper saves the previous target before selection.  It attempts to restore
that target after either `Right` or `Left`, even if the action selects a different target.  Nested
calls restore the immediately preceding target, not always the window.

If target selection fails, the helper skips the action and attempts restoration.  Selection and
action errors take precedence over restoration errors.  If only restoration fails, the helper
returns that copied SDL error.  A `Right` result means the action and restoration succeeded. On
`Left`, do not assume restoration succeeded.  These helpers do not guarantee restoration after
runtime exceptions, process exit, or actions that never return.

Keep the renderer, the previous target, and the selected target alive until the helper returns.  The
helper does not own or destroy either target. Call it on the main thread.  It restores target
selection, not drawing color or changes made to a target's viewport, clipping, scale, or logical
presentation.  The example uses it while preparing its target texture, then destroys that texture
explicitly during cleanup.

Use a texture only with its creating renderer. The types distinguish access modes but do not track
renderer identity or resource lifetimes.  SDL rejects textures from another renderer. Switch away
from a texture as the current target before `destroyTexture`.  All texture calls require the main
thread. Render targets retain separate SDL viewport, clipping, scaling, and presentation state.

`createStreamingTexture renderer width height` creates a `Texture StreamingAccess` for pixel
uploads.  Dimensions must be positive 32-bit integers. Each pixel uses four bytes in red, green,
blue, alpha order.  This byte order is the same on both little-endian and big-endian systems.  The
texture starts with undefined contents. Upload all pixels before drawing it.  Streaming textures
cannot serve as render targets.

Import `Data.Buffer` to allocate and fill a `Buffer`.  `updateTextureRGBA texture pixels pitch`
uploads the entire texture from that buffer.  Pitch is the byte distance between the starts of
consecutive rows. It uses `Int32`.  Pitch must be at least `width * 4`, and the buffer must contain
at least `pitch * height` bytes.  This requirement includes padding after the final row.  The
adapter rejects short rows and buffers before SDL reads pixels.  The call returns `False` on
failure. Call `getError` immediately after failure.

`updateTextureRegionRGBA texture region pixels pitch` uploads only a rectangular part of a streaming
texture.  The `region` is a `Rect` in texture pixel coordinates, independent of rendering scale or
viewport state.  Its dimensions must be positive, and the whole rectangle must fit inside the
texture.  The binding rejects empty rectangles and rectangles outside the texture instead of
clipping them.  Pixels outside the rectangle remain unchanged.

Buffer byte zero supplies the rectangle's top-left pixel. The destination coordinates do not shift
the source pointer.  Pitch must be at least `region.width * 4`.  The buffer must contain at least
`pitch * region.height` bytes, including final-row padding.  For example, a one-pixel region needs
four bytes with pitch `4`, even in a large texture.  Partial uploads use the same main-thread,
buffer ownership, and error rules as full uploads.

Allocate the buffer once, initialize its contents, and reuse it for later uploads.  Keep all buffer
writes within its capacity. The write functions in `Data.Buffer` do not enforce bounds.  Call
uploads on the main thread. Do not modify the buffer concurrently with an upload.  SDL consumes the
source bytes during the call and does not retain their pointer.  You can change the buffer after the
call returns. Idris manages the buffer's memory.  Destroy the texture before its renderer, as with
other textures.

The binding passes the buffer directly to SDL without an extra staging copy or native allocation.
SDL still copies or uploads the pixels internally.  SDL documents `SDL_UpdateTexture` as slow and
recommends texture locking for frequent updates.  Texture locking is not yet bound. No upload
benchmarks are available.  `test/src/StreamingTests.idr` shows buffer reuse and rows with padding.

A surface stores image pixels in CPU memory. `loadBMP path` returns an owned `Surface` or a copied
SDL error.  `createTextureFromSurface renderer surface` copies those pixels into a `Texture
StaticAccess` on the main thread.  This call does not consume the surface. Call `destroySurface`
after conversion, on success or failure.  The texture remains usable after surface destruction. The
type system prevents using a static texture as a render target.  BMP loading can run on a worker
thread. Do not access a surface concurrently with conversion or destruction.

For example, this function loads a texture and releases its temporary surface:

```idris
import SDL3
import SDL3.Scoped

loadImage : Renderer -> String -> IO (Either String (Texture StaticAccess))
loadImage renderer path = withBMP path (createTextureFromSurface renderer)
```

The caller owns the returned texture and must destroy it before its renderer.

`getTextureSize texture` returns `IO (Either String (Size PixelUnits))` for static, streaming, and
target textures. The dimensions count pixels in that texture, not drawing units or display pixels.
Rendering scale, logical presentation, clipping, texture modulation, and target selection do not
change the stored dimensions. The unit type does not identify a particular texture or window.

Call the query on the main thread, with the texture and its renderer alive. The returned size is a
copied Idris record and remains valid after their destruction. A failed SDL query returns a copied
error. The example queries once before its frame loop and reuses the dimensions for drawing and
click bounds.

The adapter calls `SDL_GetTextureSize` with its optional outputs set to null. After success, Chez
reads the public integer `w` and `h` fields of `SDL_Texture`. This avoids conversion through SDL's
floating-point outputs and needs no native output storage. It does not remove managed allocations
for result values. SDL validation does not make use of a destroyed texture safe.

Raw texture bindings now use `NativeTexture`, the typed pointer to SDL3's public texture layout,
instead of `AnyPtr`. These pointers do not copy fields or track ownership. Do not change the fields,
read a null pointer, or retain a view past texture destruction. C layout assertions and field tests
cover this representation. Rebuild Idris clients when updating these raw signatures.

`renderTextureRegion renderer texture source destination` draws part of a texture.  The `source` is
an `FRect` in texture pixel coordinates. The `destination` is a `Maybe FRect` in the current
target's rendering coordinates.  Pass `Nothing` as the destination to fill the current target.  This
supports sprite sheets, images that contain several smaller images, without copying each sprite into
a new texture.

`renderTextureRotated renderer texture source destination angle center flip` adds rotation and
mirroring.  The source is a `Maybe FRect` in texture pixels. `Nothing` selects the whole texture.
The destination is a `Maybe FRect` in drawing coordinates. `Nothing` fills the current target.  The
angle uses degrees, with positive values rotating clockwise.

The center is a `Maybe RotationCenter`. `Nothing` rotates around the destination rectangle's
midpoint.  `Just (MkRotationCenter x y)` gives offsets from the destination's top-left corner before
rotation.  These offsets use destination drawing units, not source texture pixels or absolute window
coordinates.  Rectangle and center values convert to SDL `float`. The angle remains a `Double`.

The `TextureFlip` values are:

- `NoFlip` preserves pixel orientation.
- `FlipHorizontal` mirrors left and right.
- `FlipVertical` mirrors top and bottom.
- `FlipBoth` mirrors both axes, not diagonally.

Mirroring and rotation do not modify the texture's stored pixels.  Call on the main thread with the
texture's creating renderer. Do not draw a target texture into itself.  The call returns `False` on
failure. Read `getError` immediately after failure.  The C adapter uses stack rectangles and a
point, with no native heap allocation in the adapter.  `test/src/RotationTests.idr` shows source
rectangles, combined transformations, and a custom center.

Color modulation multiplies each source color channel during drawing.  `setTextureColorMod texture r
g b` uses byte values, with 255 preserving a channel and zero removing it.  `setTextureAlphaMod
texture alpha` multiplies source alpha, which controls opacity, by `alpha / 255`.  These controls do
not change the stored texture pixels. An alpha value of 255 preserves the original alpha, rather
than forcing opacity.

`getTextureAlphaMod texture` returns `IO (Either String Bits8)` for every texture access type.  It
copies the additional alpha multiplier, not the alpha values stored in the pixels. Call it on the
main thread, with the texture and renderer alive. Each call reads the current value, even when you
reuse an IO action. The adapter uses one stack byte and returns an integer from 0 through 255, or -1
on failure. The typed API copies the SDL error instead of exposing the failure marker.

`withTextureAlphaMod texture alpha action`, exported by `SDL3.Scoped`, temporarily changes this byte
value. It saves the previous alpha, sets the requested alpha, runs the action, and attempts
restoration after either `Right` or `Left`. Nested scopes restore the value present at their own
entry. The helper does not create or destroy a texture. Keep the texture and its renderer alive
throughout the action and restoration, on the main thread.

If the initial query fails, the helper skips the action without changing alpha. If the initial
setting fails, it skips the action but still attempts restoration. Setting and action errors take
precedence over restoration errors. If only restoration fails, the helper returns that SDL error.  A
`Left` result does not guarantee restoration. Runtime exceptions, process exit, and actions that
never return do not guarantee restoration either.

Only byte alpha is restored. The helper does not restore color modulation, blending, or target
selection. If external code sets floating-point alpha, avoid this helper when exact restoration is
required. Saving and restoring the byte representation can lose that precision.  For premultiplied
pixels, fading still requires matching changes to both RGB and alpha.  The helper makes three
foreign state calls on its successful path, in addition to the action.  It does not allocate native
heap storage for the saved alpha.

Blending combines source texture pixels with destination pixels. Use `setTextureBlendMode texture
mode` with one of these modes:

- `NoBlend` copies source color and alpha.
- `AlphaBlend` combines colors using source alpha.
- `PremultipliedAlphaBlend` uses source colors already multiplied by their alpha.
- `AdditiveBlend` adds source colors, scaled by source alpha, to destination colors.
- `PremultipliedAdditiveBlend` adds source colors without scaling them again.
- `ModulateBlend` multiplies source and destination colors.
- `MultiplyBlend` also preserves destination color based on source transparency.
- `OtherBlendMode code` preserves a custom or unknown SDL code as `Bits32`.

With `AlphaBlend`, alpha modulation of zero makes the texture invisible.  Premultiplied modes
require correctly prepared pixels. The binding does not convert their color values.  When fading a
premultiplied texture, scale RGB and alpha together.  For example, use 128 for all three color
multipliers and for alpha to reduce both by approximately half.

Filtering selects source pixels when drawing a scaled texture.  `setTextureScaleMode texture
NearestScale` selects individual pixels, which suits pixel art.  `LinearScale` interpolates
neighboring pixels and is SDL's default.  All four texture controls require the main thread and
return `False` on failure.  Call `getError` immediately after failure. SDL can choose the closest
supported blend or scale mode, so failure does not guarantee unchanged state. Color modulation
queries are not yet exposed.

`getTextureBlendMode texture` returns `IO (Either String BlendMode)` for every texture access type.
Call it on the main thread, with the texture and renderer alive. It reports texture blending, not
the renderer's draw blending. The copied result survives texture destruction. The adapter uses a
stack `SDL_BlendMode` and returns its unsigned 32-bit code through a signed 64-bit integer.  The
failure marker is -1, which cannot collide with any unsigned 32-bit code.

`BlendMode` now includes `OtherBlendMode Bits32`. Update exhaustive matches to handle it.  Both
`setTextureBlendMode` and `setDrawBlendMode` can pass this code to SDL, but support depends on the
renderer. Blend codes are complete modes, not independent flags to combine with bitwise OR.  `Eq
BlendMode` compares SDL codes, so `OtherBlendMode 1` equals `AlphaBlend`.

`composeBlendMode rgb alpha` returns `IO BlendMode` from two `BlendEquation` records.  Construct
each with `MkBlendEquation sourceFactor destinationFactor operation`.  The RGB equation applies to
red, green, and blue separately. The alpha equation applies to alpha.  Each equation combines
`source * sourceFactor` and `destination * destinationFactor`.

A blend factor multiplies a pixel component before the operation. `ZeroFactor` and `OneFactor`
select 0 and 1. `SourceColorFactor` and `DestinationColorFactor` select the corresponding color
components. `SourceAlphaFactor` and `DestinationAlphaFactor` select alpha. These four source and
destination factors have `OneMinus...Factor` counterparts that select 1 minus the value. In the
alpha equation, SDL uses the fourth component of the selected factor, as described in
`SDL_blendmode.h`.

`BlendAdd` adds the products. `BlendSubtract` subtracts the destination product from the source
product. `BlendReverseSubtract` reverses that subtraction. `BlendMinimum` and `BlendMaximum` select
the smaller or larger product. For example, this mode subtracts source RGB from destination RGB and
leaves destination alpha unchanged:

```idris
subtractSource : IO BlendMode
subtractSource = composeBlendMode
  (MkBlendEquation OneFactor OneFactor BlendReverseSubtract)
  (MkBlendEquation ZeroFactor OneFactor BlendAdd)
```

Composition calls `SDL_ComposeCustomBlendMode` directly, with no C adapter or native output buffer.
It is safe on any thread. It creates no SDL resource, changes no renderer state, and does not
prepare or premultiply pixel data. Cache the returned mode if you reuse the equations.  SDL codes
for predefined modes become named constructors. Other codes become `OtherBlendMode`.  Mathematically
equivalent equations do not necessarily produce the same SDL code.

Composition does not test renderer support. Apply the result with `setTextureBlendMode` or
`setDrawBlendMode` on the main thread, then handle failure. The software renderer does not support
custom modes. Hardware support depends on the renderer, factors, and operations. A rejected setting
can still change state. Use the scoped blend helpers when you need a restoration attempt.

`withTextureBlendMode texture mode action`, exported by `SDL3.Scoped`, saves the current mode and
attempts restoration after the action returns `Right` or `Left`. Nested scopes save their own entry
mode, including custom codes. Only texture blending is restored. Alpha, color modulation, filtering,
renderer draw blending, and target selection are not restored.  Keep the texture and renderer alive
on the main thread. The helper does not own either resource.

A failed query skips the action. A failed setting skips it but still triggers restoration, because
SDL can change the mode even when the setting fails. Setting and action errors take precedence over
restoration errors. If only restoration fails, the helper returns that SDL error. A `Left` result
does not guarantee restoration. Runtime exceptions, process exit, and actions that never return do
not guarantee restoration either.

A successful scope makes three foreign state calls in addition to its action. It does not allocate
native heap storage for the saved mode.

`getTextureScaleMode texture` returns `IO (Either String ScaleMode)` for every texture access type.
It reports the current filtering mode on the main thread, with the texture and renderer alive.  The
copied value survives texture destruction. The adapter uses one stack enum, with no native heap
allocation for output storage. It returns a signed 32-bit code through a 64-bit integer.  The
failure marker, -2147483649, lies outside that code range.

`ScaleMode` now includes `OtherScaleMode Int32` for SDL codes without named constructors.  Update
exhaustive matches to handle it. Passing an unknown code to `setTextureScaleMode` does not guarantee
support. SDL can reject it or choose a supported mode. `Eq ScaleMode` compares SDL codes, so
`OtherScaleMode 0` equals `NearestScale` and `OtherScaleMode 1` equals `LinearScale`.  This keeps
SDL 3.2.12 as the minimum version while preserving modes reported by newer versions.

`withTextureScaleMode texture mode action`, exported by `SDL3.Scoped`, saves the current filtering
mode and attempts restoration after the action returns `Right` or `Left`. It restores only
filtering, not alpha, color modulation, blending, or target selection. Nested scopes save their own
entry mode, including unknown codes. Keep the texture and renderer alive on the main thread.  The
helper does not own them.

A failed query skips the action. A failed setting also skips the action, but still triggers a
restoration attempt. Setting and action errors take precedence over restoration errors. If only
restoration fails, the helper returns that SDL error. A `Left` result does not guarantee
restoration, and SDL can select the closest supported mode. Runtime exceptions, process exit, and
actions that never return do not guarantee restoration.

A successful scope makes three foreign state calls, in addition to its action, without native heap
storage for the saved mode.

`pollEvent` returns only event types. `pollEventData` also returns timestamps and supported event
data.  Both return `Nothing` for an empty queue. Each call consumes one event, so use one polling
function, not both for the same event.  Returned data remains valid after buffer reuse or
destruction.

`waitEventData buffer` blocks until an event arrives, then returns `Either String Event`.  Use it
when the application has no work to do until the next event.  `waitEventDataTimeout buffer
timeoutMS` returns `Either String (Maybe Event)`.  It returns `Right (Just event)` for an event and
`Right Nothing` when the wait ends without an event or SDL error.  The timeout uses `Bits32`
milliseconds, from 0 through 2147483647. Zero does not wait.  Larger values return `Left` without
consuming an event. Use `waitEventData` for an indefinite wait.

Timed waits clear SDL's error before calling SDL.  If SDL returns no event and reports an error, the
binding copies that error into `Left`.  Read any earlier SDL error before starting a timed wait.
Actual waits can exceed the timeout because of operating system scheduling.

Both waits use the existing `EventBuffer` and copy data through the same decoder as `pollEventData`.
Reuse the buffer, then free it exactly once during cleanup. Returned data survives buffer reuse or
destruction.  Each successful wait consumes one event. Poll afterward only to receive further
events, not to decode the event already returned.  Call waits on the main thread that initializes
video. Do not share the buffer between threads.  Waiting blocks drawing on that thread, so keep
polling when the application must render continuously.

`WindowCloseEvent` contains a window identifier. Use `getWindowID` to match it to a live window.
Identifiers do not own windows or extend their lifetimes. A zero identifier in an event means no
associated window.

Keyboard focus identifies the window that receives keyboard input.  `raiseWindow window` requests
that SDL raise a window above others and give it keyboard focus.  It returns `IO Bool`. Call it on
the main thread with a live window. If it returns `False`, read `getError`
immediately. Window-manager policy can reject focus changes. A `True` result does not prove that
stacking or focus changed. Use `showWindow` separately when the window is hidden.

`hasKeyboardFocus window` returns `IO Bool` from SDL's `SDL_WINDOW_INPUT_FOCUS` flag.  Its result is
a state, not a success indicator. Call it on the main thread while the window is alive.  Process
events normally to keep SDL's reported state current. The query does not report mouse focus, window
visibility, or whether other windows cover it. Its copied result survives window destruction but
does not track later changes.

The raise adapter only converts SDL's boolean result to a C integer. The focus query uses the direct
window-flag binding, with its bit mask checked against the SDL header during the native build.
Neither allocates native output storage. Keep textures and their renderer alive while using them,
then destroy them before their window. Raising does not transfer resource ownership.

`WindowFocusGainedEvent timestamp identifier` and `WindowFocusLostEvent timestamp identifier` report
changes in that focus. Their copied values contain a nanosecond timestamp and `WindowID`.  They do
not report mouse entry, mouse exit, window visibility, or minimization.

Match the identifier to your window before changing application input state.  On lost focus, you can
clear your application's held-key state or pause keyboard-driven actions.  The binding does not
maintain that state or pause your application. A queued notification describes a past change, not a
query of current focus. Its identifier does not keep a window alive.

`pollEvent` returns `WindowFocusGained` or `WindowFocusLost` without payload data.  `pollEventData`,
`waitEventData`, and `waitEventDataTimeout` decode both payload constructors.  Call these functions
on the main thread and reuse the caller-owned event buffer.  Copied notifications survive buffer
reuse and destruction. No new native storage is allocated for each notification. Update exhaustive
matches for the two new type-only and two new payload constructors.

`WindowMouseEnterEvent timestamp identifier` reports that a window gained mouse focus.
`WindowMouseLeaveEvent timestamp identifier` reports that it lost mouse focus.  Both carry a copied
nanosecond timestamp and `WindowID`. They contain no position, mouse device identifier, movement, or
button state. They are distinct from keyboard-focus and mouse-motion events.

Match the window identifier before updating application hover state. A leave notification is not a
button release. The decoder does not clear application state or change SDL's input configuration.
Queued notifications describe past changes, and their identifiers do not keep windows alive.  A zero
identifier means no associated window.

`pollEvent` returns the type-only `WindowMouseEnter` or `WindowMouseLeave` constructor.  Payload
polling and both wait APIs decode the corresponding events through the shared decoder.  Use the
caller-owned buffer on the main thread. Copied values survive buffer reuse and destruction, without
new native storage for each notification. Update exhaustive matches for these four new
constructors. Actual pointer movement, mouse capture, and relative mouse mode need platform tests.

`minimizeWindow window`, `maximizeWindow window`, and `restoreWindow window` each return `IO Bool`.
They request minimization, maximization, or restoration of a minimized or maximized window's size
and position. Maximization requires a resizable window and is not fullscreen mode.  Minimize and
restore requests have no direct effect in fullscreen, but can affect the later windowed state. Use
`setWindowFullscreen window False` to request leaving fullscreen.

Call these functions on the main thread while the window is alive. If a request returns `False`,
read `getError` immediately. A successful request can be delayed or denied by the window system.
Use state-change events or `syncWindow` when waiting, then query the reported state.
Synchronization can block or time out, and it does not prove that the requested state was granted.
It does not wait for GPU work. The dummy driver rejects all three requests as unsupported.

`isWindowMinimized window` and `isWindowMaximized window` return `IO Bool` from SDL's corresponding
window flags. Call them on the main thread with a live window. Their booleans are states, not
success indicators. They are distinct from hidden and fullscreen state. Copied results survive
window destruction but do not track later changes. Query size separately when updating layout.

The request adapters only widen SDL's boolean results to C integers. Queries use the direct
window-flag binding, with masks checked against SDL headers during the native build.  No adapter
output storage is allocated. These calls do not transfer ownership or change cleanup order: destroy
textures before their renderer, then destroy the window.

`WindowMinimizedEvent timestamp identifier`, `WindowMaximizedEvent timestamp identifier`, and
`WindowRestoredEvent timestamp identifier` report SDL window-state changes. Restored means restored
to normal size and position. Each notification contains a copied nanosecond timestamp and
`WindowID`, not dimensions or coordinates. Use the size queries on a live window when you need its
current size.

Match the identifier to your window before changing application state. A queued notification records
a past change and does not prove the current state. It does not own the window or extend its
lifetime. Minimization is distinct from hiding and losing keyboard focus. Decoding these events does
not minimize, maximize, or restore windows, and does not pause or resume rendering.

Type-only polling returns `WindowMinimized`, `WindowMaximized`, or `WindowRestored`.  Payload
polling and both wait APIs use the same decoder. Update exhaustive matches for the three new
type-only and three new payload constructors. Process events on the main thread with the
caller-owned buffer. Copied notifications survive buffer reuse and destruction without new native
storage per notification. Do not assume a fixed order between these notifications and resize events.

`WindowShownEvent timestamp identifier` and `WindowHiddenEvent timestamp identifier` report SDL
visibility changes. They describe past changes, not current visibility, keyboard focus, or whether
another window covers the contents. Match their `WindowID` to a live window that you own.  The
identifier does not keep the window alive, and zero means no associated window.

`WindowExposedEvent timestamp identifier` asks the application to redraw the window.  It contains no
damaged rectangle. Redraw from application state through your normal rendering path.  Do not assume
that the previous backbuffer contents remain valid after presentation.  Decoding an exposed event
does not draw, present, or allocate rendering resources.

Type-only polling returns `WindowShown`, `WindowHidden`, or `WindowExposed`.  Payload polling and
both wait APIs copy the corresponding nanosecond timestamp and window identifier.  Use the
caller-owned event buffer on the main thread. Copied notifications survive its reuse and destruction
without new native storage per notification. Update exhaustive matches for the three new type-only
and three new payload constructors. This binding does not install SDL event watchers or draw from
callbacks.

`setWindowFullscreen window enabled` returns `IO Bool`. With `enabled = True`, it requests
fullscreen mode. With `enabled = False`, it requests windowed mode. Call it on the main thread with
a live window. If it returns `False`, read `getError` immediately. SDL uses borderless desktop
fullscreen by default. This function does not select or clear an exclusive display mode configured
through external SDL code.

A successful request can take effect later or be denied by the window system. Use transition events
or `syncWindow` when waiting for a change, then inspect the reported state. Synchronization can
block or time out. Neither request success nor synchronization alone proves that SDL reached the
requested state, and neither waits for GPU work.

`isWindowFullscreen window` reads SDL's `SDL_WINDOW_FULLSCREEN` flag and returns `IO Bool`.  Call it
on the main thread while the window is alive. Its result is a state, not a success indicator.  It
does not distinguish desktop and exclusive fullscreen or establish physical visibility. A hidden
window can carry the fullscreen flag without being shown. The copied boolean remains valid after
window destruction, but it does not track later changes.

The setter adapter converts the boolean input and result for the C interface. The query uses the
direct window-flag binding. Neither allocates native output storage. SDL and the window system can
perform work internally. Keep normal resource cleanup order: textures, renderer, then window.  Size
and scale can change during a transition, so query them when updating layout.

`WindowEnterFullscreenEvent timestamp identifier` reports that a window entered fullscreen mode.
`WindowLeaveFullscreenEvent timestamp identifier` reports that it left fullscreen mode.  Each
contains a copied nanosecond timestamp and `WindowID`. Neither includes a display mode, dimensions,
or a display-scale value. They do not distinguish desktop fullscreen from an exclusive display mode,
and leaving fullscreen does not itself report restored dimensions.

Match the identifier to a live window that you own before updating application state.  A queued
notification describes a past change, not necessarily the current state. It does not own the window,
request a transition, or wait for GPU work. Use size and scale queries separately when your layout
needs current values. Do not assume a fixed order with resize or display-scale events.

Type-only polling returns `WindowEnterFullscreen` or `WindowLeaveFullscreen`.  Payload polling and
both wait APIs use the shared decoder. Use the caller-owned event buffer on the main thread. Copied
notifications survive buffer reuse and destruction without new native storage per
notification. Update exhaustive matches for the two type-only and two payload constructors.

`showWindow window` and `hideWindow window` return `IO Bool`. Call them on the main thread while the
window is alive, and read `getError` immediately after `False`. Hiding does not destroy the window,
renderer, or textures. Keep their normal cleanup order and show the same window again when
needed. Creating a window with `hidden` lets you prepare resources before showing it.

`isWindowHidden window` returns `IO Bool` from SDL's `SDL_WINDOW_HIDDEN` flag. Its result is a
state, not a success indicator. Call it on the main thread with a live window. `False` does not
prove that the window is visible: it can be minimized or covered by other windows. Showing a window
does not guarantee keyboard focus or immediate display by the window manager.

The hidden-state query binds directly to `SDL_GetWindowFlags` and tests one bit of its 64-bit mask.
The show/hide adapters only convert SDL boolean results to C integers. These bindings allocate no
native output storage, but SDL and the window system can perform work internally.

`setWindowBordered window enabled` requests a border when `enabled` is `True` and removes it when
`False`. `setWindowResizable window enabled` requests whether the user can resize the window.
Neither call requests new client-area dimensions. Use `setWindowSize` for a programmatic size
request, even when user resizing is disabled. SDL cannot change these styles for fullscreen windows.
Repeating the current state does nothing.

Both setters require a live window on the main thread and return `Bool`. Read `getError` immediately
after `False`. A `True` result does not prove that a backend applied the change. In our dummy-driver
tests, SDL accepts both requests without changing the corresponding flags. The binding preserves
that behavior rather than storing the requested state itself.

`isWindowBordered window` tests that `SDL_WINDOW_BORDERLESS` is absent.  `isWindowResizable window`
tests that `SDL_WINDOW_RESIZABLE` is present. Both query SDL's current flags on the main
thread. Their boolean results are states, not success indicators. Border state does not guarantee
visible window-manager decorations, and resizability does not guarantee that a specific size request
will be granted.

The setter adapters convert an integer input to a C boolean and the C boolean result to an integer.
Queries use the direct flag binding. No adapter output buffer is allocated. Keep the window alive
throughout these calls and destroy its renderer and textures before destroying the window.

`getWindowTitle window` returns `IO String`. It copies SDL's UTF-8 title into an Idris string.  An
empty result is valid for an untitled window, not an error marker. The copy remains valid after
later title changes or window destruction. The getter binds directly to SDL, with no C adapter.
Call it on the main thread while the window is alive.

`setWindowTitle window title` replaces the stored title and returns `Bool`. Empty text clears the
title. Call it on the main thread and read `getError` immediately after `False`. SDL copies the
supplied string. As with `createWindow`, do not include embedded NUL characters, because C strings
end at the first NUL. The setter's adapter only converts SDL's boolean return value to a C integer.

SDL can allocate native storage when a title changes, and the getter creates an Idris string copy.
Update titles when needed rather than on every frame. The example adds its exit instructions once,
before creating the renderer. Stored title tests do not verify how a window manager displays text.

`getWindowSize window` returns `Either String (Size WindowUnits)` in window coordinates.
`getWindowSizeInPixels window` returns `Either String (Size PixelUnits)` in physical pixels.  Both
queries require the main thread and return copied `Int32` width and height fields.  Use them to
obtain initial dimensions before resize events arrive.  The two sizes can differ on high-density
displays.

These queries describe the window, regardless of the renderer's active texture target or logical
presentation.  A returned `Size` owns its values, not the window, and remains valid after window
destruction.  Its units do not track window identity or later resizing. If dimensions are zero,
defer size-dependent drawing or allocation. Errors return through `Left`.

`getWindowPixelDensity window` returns `IO (Either String Double)`. Pixel density is the ratio of
backing pixels to window coordinates. For example, a 1920×1080 window with a 3840×2160 pixel buffer
has a density of 2.0. The value describes the window, not the renderer's current drawing scale or
texture target.

`getWindowDisplayScale window` also returns `IO (Either String Double)`. Display scale combines
pixel density with the display's content scale and describes the expected content size in pixels.
At a scale of 2.0, each content dimension uses twice the pixels required at scale 1.0.  Display
scale and pixel density are not necessarily equal. Both use `Double`, so their types do not prevent
mixing them up. Neither query changes rendering state or converts input coordinates.

Call these queries on the main thread while the window is alive. Their results are copied values and
remain valid after destruction. Re-query after monitor moves or display-scaling changes rather than
treating a copied value as current state. Avoid applying display scaling twice if your layout
already accounts for it through logical presentation or rendering scale.

SDL returns these values as C `float`, with 0.0 for failure. The adapters widen them to C `double`
for Idris `Double` and allocate no native output storage. Widening does not add precision.  The
typed API copies the SDL error into `Left` on failure. Each query makes one foreign call.

`WindowDisplayScaleChangedEvent timestamp identifier` reports SDL's window display-scale change
notification. It contains a copied nanosecond timestamp and `WindowID`, not a scale value or size.
Match the identifier to a window that you still own, then query `getWindowDisplayScale` on the main
thread when updating your layout. Query `getWindowPixelDensity` separately if you need that ratio.
The current values can differ from the state when the notification was queued.

`pollEvent` returns the type-only `WindowDisplayScaleChanged` constructor for this notification.
`pollEventData`, `waitEventData`, and `waitEventDataTimeout` use the same payload decoder.  The
event buffer is reused without a new native allocation, and copied notifications survive its reuse
or destruction. An identifier does not own the window or keep it alive. Zero identifies no
window. The decoder does not query a window or reinterpret the event's integer fields as a scale.

Update exhaustive event matches for both new constructors. This event is distinct from window
resizing and pixel-size changes. Do not assume they arrive together or that the notification alone
provides new dimensions. Synthetic tests cover decoding, not actual monitor transitions.

`setWindowSize window (MkSize width height)` requests a new client-area size in window coordinates.
Its size argument has type `Size WindowUnits`, not `Size PixelUnits`. Both `Int32` dimensions must
be positive. Call it on the main thread while the window is alive. It returns `Bool`.  Read
`getError` immediately after `False`. The C adapter only converts SDL's boolean result.

A successful request does not guarantee an immediate or exact size change. The window system can
delay, adjust, or deny it. SDL ignores this request for fullscreen or maximized windows.  Query the
actual dimensions or handle resize events before updating size-dependent resources.  The request
does not change the meaning of drawing coordinates or texture dimensions.

`syncWindow window` waits for pending window state on the main thread and returns `Bool`.  It can
block for window-system animations, or return `False` on timeout. Read `getError` after failure. On
systems that apply changes immediately, it does nothing. It does not synchronize GPU work or
guarantee the exact requested dimensions. Avoid adding this wait to every frame.

When you need to wait before querying the result, use both calls explicitly:

```idris
resizeAndRead : Window -> Size WindowUnits -> IO (Either String (Size WindowUnits))
resizeAndRead window dimensions = do
  True <- setWindowSize window dimensions | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  getWindowSize window
```

Neither adapter allocates native output storage. SDL can still allocate internal window or rendering
resources. Existing copied sizes remain snapshots, not live views of the resized window.

Each window owns one native size struct, allocated during `createWindow` and freed by
`destroyWindow`. If SDL window creation fails, the binding frees this storage and preserves the
error.  Both queries reuse the same struct. C fills it and returns success separately. Chez reads
the `Int32` fields directly and copies them before another query can reuse the storage.  There is no
native output-buffer allocation per query, global scratch buffer, or frame reset.  The returned
Idris records can still require managed allocation. Do not call these queries concurrently or after
window destruction. The raw query signatures changed to accept output storage.  Renderer output-size
queries remain unbound pending investigation of software-driver behavior that differs from the
installed header documentation.

`WindowMovedEvent timestamp position` reports a window-position change through
`WindowPositionData`. Its `windowID` identifies the window. Its `x` and `y` fields copy SDL's signed
32-bit `data1` and `data2` values without conversion or validation. Negative positions remain
negative.  These coordinates describe window placement, not a mouse position inside the window or a
renderer point. The record is distinct from size records and `Point WindowSpace`.

Match the identifier to a window that you still own before using it for application state.  The
copied identifier does not keep the window alive. A queued position describes the reported move, not
necessarily the current position. Coordinate reporting depends on the window system.  This binding
does not move windows or infer a display scale from their positions.

`pollEvent` returns the type-only `WindowMoved` constructor. Payload polling and both wait APIs
return the copied position and nanosecond timestamp through the shared decoder. Process events on
the main thread with a caller-owned buffer. Returned records survive buffer reuse and destruction.
No new native output storage is allocated per move. Update exhaustive event matches for both new
constructors. Do not assume move, resize, and display-scale notifications arrive together or in a
fixed order.

`WindowResizedEvent timestamp dimensions` reports a size in window coordinates through
`WindowSizeData`.  `WindowPixelSizeChangedEvent timestamp dimensions` reports a size in physical
pixels through `PixelSizeData`.  Both records contain `windowID`, `width`, and `height`. Dimensions
use signed `Int32` values.  The distinct record types prevent direct substitution of pixel
dimensions for window-coordinate dimensions.

A high-density display can use several physical pixels per window coordinate.  Do not assume that
these two sizes are equal or that both events always arrive together.  Match the event's window
identifier before updating your application layout or textures.  Dimensions describe the queued
event, not a fresh size query. Copied values survive buffer reuse or destruction.  The binding
preserves zero and negative dimensions without validation.  If a dimension is non-positive, skip
size-dependent drawing or allocation until a usable size is available.

`pollEvent` reports the corresponding `WindowResized` and `WindowPixelSizeChanged` types.
`pollEventData` and both wait functions return the typed payloads.  These events no longer appear as
unknown events. Update exhaustive event matches to include the new constructors.  The binding does
not recreate textures or change application layout automatically.

`KeyboardEvent` contains the window identifier, press or release action, physical key position,
layout key value, modifier bits, and repeat status.  `Scancode` represents a physical key
position. `Keycode` represents a key value from the keyboard layout, not text input.  `escapeKey` is
the Escape key value. `KeyModifiers` contains SDL's modifier bits, such as `Shift` and `Ctrl`.

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

Event timestamps use nanoseconds since SDL initialization. `ticksNS` uses the same units, while
`ticks` uses milliseconds.  `UnknownEvent` preserves the timestamp and numeric type, but discards
unsupported event data.  Keyboard device identifiers and platform-specific key codes are not exposed
yet.

## Timing and frame pacing

Frame pacing controls the time between rendered frames.  `ticksNS : IO Bits64` returns nanoseconds
since SDL initialization.  A nanosecond is one billionth of a second. The clock's actual resolution
depends on the platform.  `ticks : IO Bits64` returns milliseconds instead. These values are not
calendar timestamps.

`performanceCounter : IO Bits64` reads SDL's high-resolution counter.  `performanceFrequency : IO
Bits64` returns its increments per second.  Only differences between counter samples are
meaningful. Do not compare counter values with `ticksNS` or event timestamps.  To calculate seconds,
subtract counter samples first, then convert the difference and frequency to `Double` before
division.  This avoids losing small differences when converting large absolute counter values.

`delay ms` waits at least the requested milliseconds and takes `Bits32`.  `delayNS ns` waits at
least the requested nanoseconds and takes `Bits64`.  `delayPrecise ns` also takes `Bits64` and
attempts to wait close to the requested interval.  It can keep the CPU active while waiting. All
delays can return late because of operating system scheduling.  Nanosecond units do not guarantee
nanosecond scheduling accuracy.

All timing functions are safe on any thread. Delays block only the calling thread.  Avoid long waits
on the main thread. They stop event processing and drawing.  The example measures event handling and
drawing time, then waits for the remainder of a 16,666,667-nanosecond frame budget.  This targets
roughly 60 frames per second without a fixed extra delay after drawing.  It does not guarantee that
rate or synchronize frames with the display.

If a frame exceeds its time budget, skip the delay.  Subtracting a larger unsigned elapsed time from
a smaller budget wraps to a large delay.  The example tests the elapsed time before subtraction.

### Display synchronization

VSync synchronizes frame presentation with display refreshes.  `setRenderVSync renderer mode`
selects a `VSyncMode` and returns `Bool`.  The available modes are:

- `VSyncDisabled` disables synchronization. This is SDL's default for new renderers.
- `VSyncInterval n` requests presentation every `n` refreshes. Use `1` for every refresh or `2` for
  every second refresh.
- `VSyncAdaptive` allows late frames without waiting for the next refresh.

Adaptive mode can cause tearing, which shows parts of different frames in one refresh.  Intervals
use `Bits32`, but valid values range from 1 through 2147483647.  The binding rejects zero and larger
intervals before SDL changes the renderer.  Use `VSyncDisabled` instead of `VSyncInterval 0`.

Drivers do not support every mode or interval.  If the setter returns `False`, read `getError`
immediately before another SDL call replaces it.  `getRenderVSync renderer` returns the configured
mode through `Either String VSyncMode`.  It copies the SDL error on failure and needs no
caller-owned output buffer.  Both calls require the main thread. VSync belongs to the renderer, not
to individual render targets.

The example keeps its timer-based frame pacing.  If you enable VSync in your application, account
for the time spent inside `present` before adding another delay.  Large intervals can make `present`
wait a long time.  The dummy-driver tests do not measure physical display synchronization or
tearing. These need manual testing on a display.

## Performance and native code

The C adapter converts SDL boolean results to C integers and accesses SDL's event union, which
stores different event layouts.  The compiler reads struct sizes and event constants from the
installed headers.  Static assertions compare the exposed flag constants with the Idris definitions.

Allocate an event buffer once and reuse it in the event loop.  The adapter performs no heap
allocation per draw or poll call. SDL and the Idris runtime can still allocate internally.
Rendering rectangle values use Idris `Double` and convert to SDL `float` values on the C stack.
Text input areas use `Int32` fields and a stack-allocated SDL rectangle, with no extra native heap
allocation. Event waits also reuse the caller-owned buffer without a new native allocation in the
adapter.  Text events allocate Idris strings when polling or waiting copies their text. The C
adapter does not allocate an additional text buffer.

Create textures outside the frame loop and reuse them. Texture destination rectangles use stack
storage in the C adapter.  The example creates one target texture before its loop. The tests read
pixels back to compare rendered colors, but normal rendering does not.

No resource registry, finalizer, or automatic error-string copy runs on each successful rendering
call. Event polling uses multiple native calls and constructs Idris values.  A successful point
conversion uses one foreign call and two direct struct field reads. The adapter allocates no native
memory per conversion when you reuse a coordinate buffer. Idris still constructs result values.
Texture-size queries use one foreign validation call and two direct reads of SDL's public integer
fields. They allocate no native output buffer. There are no general performance guarantees, and this
project does not claim zero overhead.

## Use from another package

Add this project as a local package in your application's `pack.toml`, then add `depends = sdl3` to
its `.ipkg` file.  The C library is separate from pack's Idris package installation.  Keep it
available when you run the application.

Build the application with `--cg=chez`. Include this project's `cbits` directory and the SDL library
directory in `LD_LIBRARY_PATH`. The root Makefile sets this path for builds, tests, and examples.
Rebuild clients and the native library together after this update. Raw size-query signatures and
coordinate-buffer layout changed, although the public typed query signatures remain unchanged.

## Tests and next steps

The tests cover native event classification, unknown events, empty queues, flag combinations, window
creation, drawing, and timers.

Target scope tests cover nested window and texture selection, successful and failed actions, and
actions that change the selected target.  They also cover failed selection, skipped actions,
preserved results, and drawing color that is not restored.

Texture helper tests cover drawing, callback errors, invalid dimensions, and caller-owned surface
reuse.

Cleanup tests cover skipped callbacks after creation failure, preserved results, and nested cleanup
after successful and failed callbacks.  They inspect window and renderer state through window
identifiers, without using destroyed handles.  They also test copied events, points, and textures
after their source resources are released.

Timing tests cover clock units, counter frequency, zero delays, and clock progress during nanosecond
delays.  They enforce no upper duration limit because scheduling can resume the test late.  These
tests are not timing-accuracy benchmarks.

Texture tests read pixels from off-screen and window targets. They test destination rectangles,
target reset, invalid dimensions, and rejection of textures from another renderer.

BMP tests create temporary image files and remove them after each test.  They test missing and
invalid files, pixel colors, source rectangles, and texture use after surface destruction.

VSync tests cover mode queries, supported-mode selection, unsupported-mode errors, and interval
bounds.  They restore disabled synchronization before presenting another frame.

Shape tests cover point placement, line endpoints, outline edges, unfilled interiors, clipping,
scaling, and alpha blending.  They also cover a default outline on a target texture.  Compile-time
tests reject window-coordinate points and integer outline rectangles.

Renderer tests cover viewport origins, clipping, empty clip rectangles, per-target state, and shape
alpha blending. They also test that `clear` ignores viewport and clip state.

Scaling tests cover every logical presentation mode, independent axis scaling, and scale and logical
state retained across target switches.

Coordinate tests cover inverse conversion, scaling, viewport offsets, letterbox borders, combined
transforms, and copied point lifetime.  Compile-time tests reject mixed point spaces and buffer
types.

Streaming tests cover RGBA byte order, row padding, buffer reuse, and source data consumption.  They
also cover short buffers, invalid pitch, size multiplication beyond 32 bits, and rejected upload
preservation.

Partial upload tests cover source origin, padded rows, texture edges, and preservation of
neighboring pixels.  They reject invalid rectangles, extreme coordinates, short buffers, and invalid
pitch.  Compile-time tests reject floating-point upload rectangles and partial uploads to
render-target textures.  Compile-time tests reject uploads to static textures and uploads from the
wrong buffer type.

Rotation tests cover every flip mode, clockwise and counterclockwise rotation, combined rotation and
mirroring, source rectangles, and default destinations.  They also cover custom centers and
unchanged pixels outside the destination.  Compile-time tests reject unrelated flip modes and
absolute points used as rotation centers.

Pixel tests cover all exposed blend modes, color and alpha modulation, and nearest and linear
filtering.  Tests allow small rounding differences for fractional blending and interpolation.
Compile-time tests reject mixed handle types, mixed flag types, forged handles, and static textures
used as render targets.

Wait tests cover queued and delayed events, zero and expired timeouts, timeout bounds, old SDL
errors, and copied text lifetime.  A test-only C timer queues delayed events without calling Idris
from another thread.

Size query tests cover initial dimensions, non-square windows, independence from texture targets and
logical presentation, and copied values after window destruction.  Native tests cover query
failure. Compile-time tests reject mixed size units and handle types.

Resize tests cover distinct window and pixel dimensions, zero sizes, signed limits, timestamps, and
buffer reuse.  They test typed polling, type-only polling, and timed waits. Compile-time tests
reject mixed size units.  These use synthetic events. Display-density changes on real monitors still
need manual testing.

Event tests cover keyboard data, repeat status, window identifiers, timestamps, and data retained
after buffer reuse.

Mouse tests cover fractional coordinates, relative motion, presses, releases, click counts, unknown
buttons, and button-state bits.

Wheel tests cover normal, flipped, and unknown directions, fractional values, pointer position, and
signed 32-bit limits.

Text tests cover Unicode, empty and long text, composition selections, string ownership, and
per-window start and stop controls.

Area tests compare the stored SDL rectangle and cursor against the Idris values. They also test area
reset and composition cancellation without disabling text input.

The test-only native library inserts known events into SDL's queue. It is not part of the binding
library.  The example builds in the test environment, but interactive display behavior needs a
manual test.

Size-storage tests cover the native struct layout, signed field limits, repeated queries after
resizing, multiple windows, and copied values after storage reuse and destruction.  The event tests
use values above 32 bits to test timestamp preservation.  Rotation option flags remain packed
because they represent independent bits, not a multi-field result.  Event unions still use C
accessors. Idris `Double` describes a C `double`, not a C `float`.  Coordinate adapters therefore
convert SDL float results into a separate double-valued result struct.  They do not reinterpret
`SDL_FPoint` memory as doubles.

Target-texture ownership tests observe SDL property cleanup on the main thread, without inspecting
freed texture handles or calling Idris from C. They cover nested ownership and selection scopes,
cleanup after successful and failed callbacks, preserved results, and skipped callbacks on creation
failure. Compile-time tests reject streaming-only uploads inside a target-texture callback.

Batch tests cover initialized entries, count prefixes, index and count rejection, queued input
consumption, buffer reuse and release, connected lines, empty batches, clipping, scaling, blending,
and texture targets. Compile-time tests reject window-space points, coordinate buffers used as point
arrays, and signed draw counts. Native tests cover null pointers and capacity limits.

Rectangle batch tests cover outlines, fills, count prefixes, bounds rejection, empty batches,
clipping, fractional scaling, logical presentation, blending, renderer reuse, and texture targets.
They also cover input consumption before buffer mutation or release, scope results, and skipped
callbacks on allocation failure. Compile-time tests reject integer rectangles, mixed buffer types,
signed counts, and forged rectangle-buffer handles.

Texture-size tests cover all access types, uploads, independent textures, rendering state, and
copied sizes after texture, renderer, and window destruction. Layout tests cover every public
texture field and signed dimension limits on a fabricated object, without calling SDL with it.
Null-query tests cover failure, and compile-time tests reject wrong units, handles, and raw
pointers.  Existing rendering, upload, rotation, and target-restoration tests also exercise typed
texture pointers.

Texture-alpha tests cover all 256 byte values, cached query actions, all texture access types,
nested scopes, action errors, preserved results, independent textures, and rendered opacity.  Pixel
tests show that restoration changes only alpha, not color modulation. Native and raw tests cover
null-query failure. Compile-time tests reject wrong handles, result types, and wide alpha
arguments. The software renderer does not exercise unsupported modulation or restoration failures.

Texture-filtering tests cover defaults, cached queries, all texture access types, nested scopes,
action errors, invalid-mode rejection, skipped actions, and preservation of unrelated alpha state.
Pixel tests compare scoped linear filtering with restored nearest filtering. Tests also try a newer
mode and restore the actual code that SDL reports. Native and raw tests cover null-query failure.
Compile-time tests reject wrong handles, result types, and blend modes used as filtering modes.
Restoration failures and differences between hardware renderers still need separate testing.

Texture-blend tests cover every named mode, cached queries, all texture access types, nested scopes,
action errors, invalid codes, skipped actions, independent textures, and copied mode lifetime.  They
also test that alpha and filtering changes survive a blend scope. Pixel tests compare scoped alpha
blending with restored additive blending. Native and raw tests cover null-query failure.
Compile-time tests reject wrong handles, result types, and filtering modes used as blend modes.
Successful custom-mode restoration and restoration failures still need tests on suitable renderers.

Draw-blend tests cover every named mode, cached queries, nested scopes, action errors, invalid-code
rejection, skipped actions, independent renderers, and copied mode lifetime. Target-switch tests
show that draw blending belongs to the renderer and does not change texture blending.  Pixel tests
cover scoped alpha blending, restored additive blending, and unchanged draw color.  Native and raw
tests cover null-query failure. Compile-time tests reject textures used as renderers and filtering
modes used as draw blend modes. Custom-mode restoration and restoration failures still need tests on
suitable renderers.

Blend-composition tests compare all ten factors and five operations against SDL header constants,
with each varied in every argument position. They cover all seven predefined recipes, custom codes,
and repeated composition. Integration tests apply a composed mode through both scoped blend helpers
and handle either support or rejection. Compile-time tests reject swapped factors and operations,
and filtering modes used as equations. The software tests cover custom-mode rejection, not hardware
rendering with custom equations.

Window-resize tests use the public size request and synchronization calls instead of a private
fixture. They cover repeated actions, one-unit dimensions, rejected zero and negative dimensions,
unchanged size after rejection, stable window identifiers, and independent windows. A renderer test
resizes a window while a texture target is selected, then checks the window, pixel, and texture
sizes.  It also receives the real resize event through a reusable buffer, across SDL poll-cycle
boundaries.  Native tests cover null-window failures. Compile-time tests reject pixel-unit sizes and
wrong handles.

These tests use the dummy window system, which applies size changes immediately. Window-manager
adjustments, denied requests, synchronization timeouts, fullscreen behavior, and real
display-density changes still need manual tests.

Window-title tests cover initial values, Unicode, empty and long strings, repeated updates, cached
query actions, independent windows, stable identifiers, and copies retained after window
destruction.  They also change the title with an active texture target and confirm that dimensions
stay unchanged.  Native tests cover setter failure for a null window. Compile-time tests reject
renderer and texture handles used as windows. Visible title rendering still needs manual testing
with a window manager.

Window-visibility tests cover hidden and shown creation, other flag bits, repeated show/hide calls,
cached actions, independent windows, copied state, and stable identity, title, and dimensions.  A
pixel test uses an existing renderer and texture after hide/show. Native tests cover null-window
failures. Compile-time tests reject wrong handles and flag values used as windows. The dummy driver
tests SDL state, not focus, occlusion, minimization, or physical display behavior.

Window-style tests cover creation flags, repeated requests, cached actions, independent windows, and
queries compared with SDL's actual flags. They also cover programmatic resizing with user resizing
disabled, stable identifiers and titles, and use with an active texture target.  Native tests cover
null windows and zero/nonzero input conversion. Compile-time tests reject wrong handles and flag
values used instead of booleans. The dummy driver does not apply style changes.  Actual border
changes, interactive resizing, and fullscreen restrictions need manual testing.

Window-scale tests cover the dummy driver's density and display scale of 1.0, repeated query
actions, resizing, independent windows, and the high-density creation flag. They compare pixel
density with window and pixel dimensions and query while a scaled texture target is active.  Copied
values survive resource cleanup. Native and raw tests cover null-window failures, and compile-time
tests reject wrong handles and density values used as dimensions.

These tests do not establish behavior on real high-density displays. Fractional factors, different
pixel-density and display-scale values, monitor moves, and live scale changes need manual testing.

Display-scale event tests cover type-only polling, payload polling, timed and blocking waits,
identifiers with high bits or zero, and timestamps above 32 bits. They also cover copied values
after buffer reuse and destruction. Unused integer payload fields contain extreme values to catch
accidental size or scale decoding. Native tests cover classification and window access.
Compile-time tests reject size records or owned windows used instead of event identifiers.

Keyboard-focus tests cover both notifications through payload polling, type-only polling, timed
waits, and blocking waits. They preserve wide timestamps, distinct window identifiers, zero
identifiers, and copied values after buffer cleanup. Native tests cover the SDL event constants and
window fields. Compile-time tests reject owned windows or keycodes used as focus-event identifiers.
Synthetic events do not establish window-manager focus behavior. Actual focus transfers between
windows or applications need manual testing.

Mouse-focus tests cover entry and departure through type-only polling, payload polling, and both
wait APIs. They preserve distinct high-bit identifiers, zero identifiers, and timestamps above 32
bits. Copied values survive buffer reuse and destruction. Synthetic window events contain extreme
unused integer fields, not mouse-motion payloads. Native tests cover classification and window
access. Compile-time tests reject owned windows and motion records as event identifiers.  These
tests do not simulate real pointer movement or establish mouse-capture behavior.

Window-state event tests cover all three notifications through both polling APIs and both wait APIs.
They preserve distinct identifiers, zero identifiers, and timestamps above 32 bits. Copied values
survive buffer reuse and destruction. Unused integer fields contain extreme values, not dimensions.
Native tests use SDL's event constants. Compile-time tests reject handles and size records used as
notification identifiers. Synthetic events do not establish real minimization, maximization,
restoration, or resize-event ordering. Those behaviors need manual window-manager tests.

Shown, hidden, and exposed event tests cover both polling APIs and both wait APIs. They preserve
wide timestamps, distinct identifiers, zero identifiers, and copied values after buffer cleanup.
Native tests use SDL's event constants. Compile-time tests reject handles, flags, and rectangles
used as notification identifiers. Dummy-driver integration tests also match real shown and hidden
notifications to the window after `showWindow` and `hideWindow` calls. Exposed-event tests use
synthetic notifications. Actual covering, uncovering, and redraw behavior need manual platform
tests.

Window-move tests cover both polling APIs and both wait APIs. They preserve negative positions, zero
coordinates, signed 32-bit extremes, wide timestamps, and high-bit or zero window identifiers.
Copied positions survive buffer reuse and destruction. Native tests use SDL's moved-event constant
and signed window fields. Compile-time tests reject size and motion records used as move payloads,
and window positions used as local points. These synthetic tests do not establish actual window
movement or cross-monitor coordinate reporting. Those behaviors need manual platform tests.

Fullscreen event tests cover both notifications through both polling APIs and both wait APIs.  They
preserve wide timestamps, high-bit or zero identifiers, and copied values after buffer cleanup.
Native tests use SDL's event constants. Compile-time tests reject owned windows and size records as
notification identifiers. These synthetic events do not switch a window into fullscreen mode.
Actual fullscreen transitions, display-mode selection, and related event ordering need manual tests.

Fullscreen-control tests cover windowed and hidden-fullscreen creation, repeated requests, cached
actions, independent windows, stable identifiers and titles, and copied state after cleanup.
Dummy-driver tests match real entry and exit notifications to the requesting window. They also
retain a selected texture target and its pixels across transitions. Native tests cover zero/nonzero
input conversion and null-window failure. Compile-time tests reject wrong handles and flag
arguments.  These tests do not establish exclusive display-mode changes, GPU resource survival on
all backends, or window-manager denial and synchronization failures. Those paths need manual tests.

Raise and focus-query tests cover hidden and shown windows, repeated requests, cached actions,
stable identifiers and titles, and copied states after cleanup. Under the dummy driver, showing
windows transfers keyboard focus, but raising succeeds without changing it. Tests preserve that
behavior rather than assuming successful requests gain focus. They also draw with an existing
renderer and texture target after raising. Native tests cover null-window failure and hidden-window
raising. Compile-time tests reject wrong handles. Real stacking, focus-policy decisions, and focus
changes between applications need manual testing.

Minimize, maximize, and restore tests cover dummy-driver rejection, SDL errors, repeated requests,
cached actions, independent windows, and copied false state flags after cleanup. They distinguish
hidden and fullscreen flags from minimized and maximized flags. Native tests cover null-window
failures with cleared error state. Tests also preserve window identity, title, dimensions, and use
of an existing renderer and texture target after rejected requests. Compile-time tests reject wrong
handles and identifiers. Successful requests, true state flags, real state-change events, and
window-manager restrictions remain manual-test cases because the dummy driver lacks these
operations.

Next work includes texture locking and audio streams.  Keep each addition close to SDL's API and
test its failure paths.  Measure call overhead and allocations before adding performance claims or a
larger abstraction layer.
