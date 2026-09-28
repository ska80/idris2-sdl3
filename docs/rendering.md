# 2D rendering

Import `SDL3` and initialize `video`. Create a renderer for a live window with `createRenderer`, or
use `withRenderer` from `SDL3.Scoped`.  Use rendering functions on the main thread. Controls report
failure with `False`.  Read `getError` immediately after failure.

## Drawing a frame

`setDrawColor renderer r g b a` selects byte-sized color channels for shapes and clearing.  `clear
renderer` clears the entire current target, regardless of viewport or clipping.  `present renderer`
displays a frame after you restore the window as the render target.  Redraw from application state
rather than relying on previous presented pixels.

The scalar shape calls use floating-point drawing coordinates:

- `drawPoint renderer (MkPoint x y)` draws a `Point RenderSpace`.
- `drawLine renderer start end` draws between two render-space points.
- `drawRect renderer (Just (MkFRect x y width height))` draws an outline.
- `drawRect renderer Nothing` uses SDL's default full-target outline.
- `fillRect renderer x y width height` draws a filled rectangle.

Shapes use the current drawing color, blend mode, viewport, clip, and scale.  Coordinates narrow
from Idris `Double` to SDL `float`. Use finite values that fit SDL floats. Fractional pixel coverage
depends on the renderer.  See [textures](textures.md) for images, source rectangles, and rotation.

## Viewport and clipping

A viewport is a drawing region with its own origin.  `setRenderViewport renderer (Just (MkRect x y
width height))` sets it on the current target.  Drawing starts at `(0, 0)` within that region and
clips to its bounds.  Dimensions must be nonnegative. Pass `Nothing` to restore the whole target.

`setRenderClipRect renderer (Just rect)` adds clipping relative to the viewport without moving its
origin. An empty clip blocks drawing. `Nothing` disables this extra clip, not viewport clipping. Use
`fillRect` rather than `clear` to clear only a region.  Each render target retains its own viewport
and clip rectangle.

## Logical resolution and scale

A logical resolution is a fixed coordinate size for drawing.  `setRenderLogicalPresentation renderer
width height mode` fits that size to the current target.  Enabled modes require positive `Int32`
dimensions. Available modes are:

- `PresentationDisabled`: Use target pixels and pass zero dimensions.
- `PresentationStretch`: Stretch each axis to fill the target.
- `PresentationLetterbox`: Preserve proportions and add borders.
- `PresentationOverscan`: Preserve proportions and crop excess content.
- `PresentationIntegerScale`: Fit with integer scale factors.

`setRenderScale renderer scaleX scaleY` adds scaling to drawing coordinates.  Use `1 1` to reset
it. Each target retains its own scale and logical presentation.  Configure only the intended targets
to avoid scaling an off-screen image twice.  These controls do not transform input events.

## Coordinate conversion

Mouse event positions use window coordinates, even when drawing uses a logical resolution.
`renderCoordinatesFromWindow renderer buffer point` converts `Point WindowSpace` to `Point
RenderSpace`. `renderCoordinatesToWindow` performs the inverse conversion.  Both return copied
points through `Either String`.

Allocate a `CoordinateBuffer` once with `newCoordinateBuffer` and free it with
`freeCoordinateBuffer`. Alternatively, keep the event loop inside `withCoordinateBuffer`.  Use the
intended render target and match the event's `WindowID` to the renderer's window.  Conversion
includes window dimensions, logical presentation, scale, and viewport state.

Points outside the scene are not clamped. Compare results with scene bounds before handling
clicks. Clipping does not restrict conversion. The functions convert positions, not relative motion
distances. Returned points survive buffer reuse, but their types do not track renderer identity or
later changes to rendering state.

## Point and rectangle batches

`newPointBuffer capacity` and `newRectBuffer capacity` allocate fixed-capacity arrays.  Capacity is
a `Bits32` value from 1 through 2147483647, subject to memory limits.  Entries start at
zero. `setPoint buffer index point` and `setRect buffer index rect` replace zero-based
entries. Out-of-range writes fail without changing entries.

`drawPoints renderer buffer count` draws a prefix of independent points.  `drawLines renderer buffer
count` joins that prefix into connected segments.  It does not close the path automatically. Repeat
the first point at the end to close it.  Zero points and fewer than two line points draw nothing on
a valid renderer.

`drawRects` outlines a rectangle prefix and `fillRects` fills it.  Counts use `Bits32` and cannot
exceed capacity. Unwritten entries are zero values, not skipped entries. A rectangle array cannot
request the implicit rectangle used by `drawRect renderer Nothing`. Rectangle dimensions follow SDL
semantics without extra validation.

Batches use the current rendering state. SDL consumes the array during the call.  Reuse or free it
after the call, not during drawing. Allocate outside the frame loop, then call `freePointBuffer` or
`freeRectBuffer` exactly once. Scoped alternatives are `withPointBuffer` and `withRectBuffer`. These
buffers own CPU memory, not a renderer.

## Blending

Blending combines source and destination pixels. `setDrawBlendMode renderer mode` controls shapes,
while `setTextureBlendMode texture mode` controls that texture.  Their queries return `Either String
BlendMode`. Available modes are:

- `NoBlend`: Copy source color and alpha.
- `AlphaBlend`: Combine colors using source alpha.
- `PremultipliedAlphaBlend`: Use source colors already multiplied by alpha.
- `AdditiveBlend`: Add source colors scaled by source alpha.
- `PremultipliedAdditiveBlend`: Add source colors without scaling them again.
- `ModulateBlend`: Multiply source and destination colors.
- `MultiplyBlend`: Also preserve destination color based on source transparency.
- `OtherBlendMode code`: Preserve a custom or unknown SDL code.

Prepare premultiplied pixels yourself. The binding does not convert their colors.  Blend codes are
complete modes, not independent flags. Equality compares SDL codes.  SDL can choose the closest
supported mode, so a rejected setting does not guarantee unchanged state.

`composeBlendMode rgb alpha` creates a mode from two `BlendEquation` values.  Use `MkBlendEquation
sourceFactor destinationFactor operation` for each equation.  Factors select zero, one, source or
destination color or alpha, or their one-minus counterparts.  Operations are `BlendAdd`,
`BlendSubtract`, `BlendReverseSubtract`, `BlendMinimum`, and `BlendMaximum`.

Composition is safe on any thread and does not test renderer support or change rendering state.
Cache the result if you reuse it. Apply it on the main thread and handle failure.  The software
renderer does not support custom modes.

`withDrawBlendMode renderer mode action` temporarily changes shape blending.  Draw blending belongs
to the renderer, not its selected target. The helper restores only that mode after an ordinary
return. See [temporary state](resources.md#temporary-state) for failure and restoration rules.

## Ownership, examples, and tests

Destroy textures before their renderer, then destroy its window.  Do not share drawing buffers
between threads or mutate them during drawing.  See [resource ownership](resources.md) for scope
limits and [timing](timing.md) for VSync.

[Hello](../examples/Hello.idr) demonstrates logical resolution, texture drawing, and click
conversion.  `make test` uses the software renderer to test pixels, clipping, scaling, batches, and
blending.  Hardware rendering and custom-mode support need separate tests. A batch call does not
promise one GPU operation or a speed increase.
