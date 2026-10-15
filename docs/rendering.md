# 2D rendering

Initialize `video`. Create a renderer for a live window. Main thread only. [Resource/error
rules](resources.md).

## Drawing a frame

| API | Contract |
| --- | --- |
| `setDrawColor renderer r g b a` | Byte RGBA for shapes and clearing |
| `clear renderer` | Clear the entire active target, ignoring viewport and clip |
| `drawPoint renderer (MkPoint x y)` | `Point RenderSpace` |
| `drawLine renderer start end` | Render-space endpoints |
| `drawRect renderer (Just (MkFRect x y w h))` | Outline. `Nothing` uses the full-target outline |
| `fillRect renderer x y w h` | Filled rectangle |
| `present renderer` | Present after restoring the window target. Redraw each frame from application state |

Coordinates narrow to SDL floats. Use finite representable values. Fractional coverage depends on
the renderer.  Textures: [texture reference](textures.md). Reusable arrays: [batches and
geometry](geometry.md).

## Viewport and clipping

| Setter | Effect on current target |
| --- | --- |
| `setRenderViewport renderer (Just rect)` | Nonnegative dimensions. Changes origin and clips to the region |
| `setRenderViewport renderer Nothing` | Automatic full-target viewport |
| `setRenderClipRect renderer (Just rect)` | Extra clip relative to the viewport, without moving its origin |
| `setRenderClipRect renderer Nothing` | Disable extra clipping, not viewport clipping |

An enabled empty clip blocks drawing. Use `fillRect`, not `clear`, to clear a region.  Each target
retains its own viewport, clip, scale, and logical presentation. Draw color/blend state belongs to
the renderer.

## Logical resolution and scale

`setRenderLogicalPresentation renderer width height mode`: positive `Int32` dimensions when enabled.

| Mode | Effect |
| --- | --- |
| `PresentationDisabled` | Use target pixels. Pass zero dimensions |
| `PresentationStretch` | Stretch each axis |
| `PresentationLetterbox` | Preserve proportions, add borders |
| `PresentationOverscan` | Preserve proportions, crop excess |
| `PresentationIntegerScale` | Fit using integer scale factors |

`setRenderScale renderer x y` adds dimensionless drawing scale. `1 1` resets it.  Configure only
intended targets to avoid scaling off-screen images twice. These setters do not transform input
events.

## Queries and temporary state

Allocate `RenderStateBuffer` once with `newRenderStateBuffer` or `withRenderStateBuffer`.  The
following queries take `renderer buffer` and return copied values through `Either String`:

| Query | Value | Restoration helper |
| --- | --- | --- |
| `getRenderViewport` | `Maybe Rect`. `Nothing` means automatic, not an explicit full-size rectangle | `withRenderViewport` |
| `getRenderClipRect` | `Maybe Rect`. `Nothing` means disabled, not an enabled empty clip | `withRenderClipRect` |
| `getRenderScale` | `(Double, Double)` | `withRenderScale` |
| `getDrawColor` | `MkColor r g b a`, byte channels | `withDrawColor` |

- [State-scope failure rules](resources.md#temporary-state) apply to all helpers.
- Keep the same target selected throughout viewport, clip, and scale scopes.
- Automatic viewport restoration preserves automatic resizing. Byte colors cannot preserve external
  float/HDR precision (a wider brightness range).
- Texture color, alpha, filtering, and blend queries/scopes: [texture
  state](textures.md#color-alpha-and-filtering).

## Output dimensions

| Query (`renderer buffer`) | SDL-documented result |
| --- | --- |
| `getRenderOutputSize` | `Size PixelUnits`, ignoring targets and logical presentation |
| `getCurrentRenderOutputSize` | `Size RenderOutputUnits`, including target and logical presentation |

Neither subtracts the viewport or applies draw scale. Both return SDL results without a workaround.
With SDL 3.4.16 software rendering, the physical query reported active texture dimensions. The
current query also differed from the documented logical adjustment.  For physical window pixels, use
`getWindowSizeInPixels`. Recovery notifications: [renderer reset
events](input.md#renderer-reset-events).

## Coordinate conversion

- `renderCoordinatesFromWindow renderer buffer point`: `Point WindowSpace` to `Point
  RenderSpace`. `renderCoordinatesToWindow` is the inverse.
- Allocate `CoordinateBuffer` once (`newCoordinateBuffer` / `withCoordinateBuffer`). Queries return
  copied `Either String` results.
- Select the intended target and match event `WindowID` to the renderer's window.
- Conversion includes window size, logical presentation, scale, and viewport. It does not clamp to
  the scene or clip rectangle.
- Convert positions, not relative motion distances. Results do not track later renderer-state
  changes.

## Blending

`setDrawBlendMode` controls shapes. `setTextureBlendMode` controls a texture. Corresponding getters return `Either String BlendMode`.

| Mode | Effect |
| --- | --- |
| `NoBlend` | Copy source color/alpha |
| `AlphaBlend`, `PremultipliedAlphaBlend` | Alpha combination with ordinary / already-premultiplied source colors |
| `AdditiveBlend`, `PremultipliedAdditiveBlend` | Add ordinary / already-premultiplied source colors |
| `ModulateBlend` | Multiply source and destination colors |
| `MultiplyBlend` | Multiply with source-transparency contribution |
| `OtherBlendMode code` | Preserve custom/unknown SDL codes |

- Premultiply pixels yourself. Blend values are complete modes, not flags. Equality compares SDL
  codes.
- SDL can select a supported alternative. Failed setting does not prove unchanged state.
- `composeBlendMode rgb alpha` accepts two `MkBlendEquation sourceFactor destinationFactor
  operation` values.
- Factors: zero, one, source/destination color/alpha, and their one-minus values. Operations: add,
  subtract, reverse-subtract, minimum, maximum.
- Composition is safe on any thread and does not test support. Cache the result. Apply it on the
  main thread.
- The software renderer rejects custom modes. `withDrawBlendMode` restores only renderer-wide draw
  blending.

Example: [Basic](../examples/basic/Main.idr). Commands: [build/run](build.md#examples).
