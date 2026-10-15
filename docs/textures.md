# Textures and surfaces

Surface: CPU pixel storage. Texture: renderer-owned image. Texture operations require the creating
renderer and the main thread.  [Ownership/error rules](resources.md). Other image formats: [Image
package](image.md).

## Creating textures

| Type | Creation | Use |
| --- | --- | --- |
| `Surface` | `loadBMP path` | BMP loading can run on a worker thread |
| `Texture StaticAccess` | `createTextureFromSurface renderer surface` | Copies pixels without consuming the surface |
| `Texture StreamingAccess` | `createStreamingTexture renderer w h` | Uploads and write-only locks |
| `Texture TargetAccess` | `createTargetTexture renderer w h` | Off-screen rendering |

- Streaming/target dimensions must be positive. Format: RGBA32, red/green/blue/alpha bytes in that
  order on either byte order.
- Initialize new texture contents before drawing them. SDL leaves them undefined.
- `getTextureSize` returns copied `Size PixelUnits`, independent of rendering state.
- Surface cleanup can precede cleanup of a texture copied from it. Do not access a surface during
  conversion or destruction.

## Drawing textures

| API | Parameters |
| --- | --- |
| `renderTexture renderer texture destination` | Whole image. `Maybe FRect` destination in render coordinates |
| `renderTextureRegion renderer texture source destination` | `FRect` source in texture pixels |
| `renderTextureRotated renderer texture source destination angle center flip` | Optional source. Clockwise degrees. Optional `RotationCenter` |

- `Nothing` source means the whole texture. `Nothing` destination fills the current target.
- `Nothing` center means destination midpoint. `MkRotationCenter x y` is relative to destination
  top-left, in drawing units.
- Flips: `NoFlip`, `FlipHorizontal`, `FlipVertical`, `FlipBoth`.

## Render targets

- `setRenderTarget renderer (Just texture)` requires `TargetAccess`. `Nothing` restores the window
  before `present`.
- Do not sample the active target. Target-specific state:
  [rendering](rendering.md#viewport-and-clipping).
- `withTargetTexture` owns without selecting. Nest `withRenderTarget` inside ownership. Keep the old
  and new targets alive.
- Switch away before destroying the texture, including after failed restoration. The ownership scope
  still destroys it on ordinary return.
- Restoration/error precedence: [temporary state](resources.md#temporary-state).

## Color, alpha, and filtering

| Set / get / scope | Contract |
| --- | --- |
| `setTextureColorMod` / `getTextureColorMod` / `withTextureColorMod` | Byte RGB. Getter returns `MkRGB r g b`. Leaves alpha unchanged |
| `setTextureAlphaMod` / `getTextureAlphaMod` / `withTextureAlphaMod` | Byte alpha only |
| `setTextureScaleMode` / `getTextureScaleMode` / `withTextureScaleMode` | `NearestScale`, default `LinearScale`, or `OtherScaleMode code` |
| `setTextureBlendMode` / `getTextureBlendMode` / `withTextureBlendMode` | [Blend modes](rendering.md#blending), independent of shape blending |

- Modulation multiplies channels by byte/255. A value of 255 preserves source alpha. It does not
  force opacity.
- Modulation does not change stored pixels. Fade premultiplied pixels by scaling RGB and alpha
  together.
- Getters return copied values through `Either String`. Byte color/alpha scopes do not restore
  external float/HDR precision.
- Scale-mode equality compares SDL codes. SDL can reject a mode or select an alternative.

## Uploading pixels

| API | Source layout |
| --- | --- |
| `updateTextureRGBA texture buffer pitch` | Whole streaming texture |
| `updateTextureRegionRGBA texture rect buffer pitch` | Positive, fully contained region. Byte zero supplies its top-left pixel |

- Pitch: `Int32` bytes between row starts, at least region width × 4.
- Capacity: at least pitch × region height, including final-row padding. Invalid regions fail rather
  than clip.
- Destination coordinates do not offset the source pointer. Pixels outside a partial update remain
  unchanged.
- Reuse buffers after return, not during upload. Keep direct `Data.Buffer` writes within capacity.

## Locking pixels

Allocate `TextureLockBuffer` outside the loop. `lockTextureRGBA storage texture region` returns a
borrowed `LockedRGBA` or copied error.  Only RGBA32 streaming textures are accepted. `Nothing`
selects the whole texture, `Just rect` a positive contained region.

| Operation | Contract |
| --- | --- |
| `lockedRGBASize`, `lockedRGBAPitch` | Copied region dimensions / row stride. Stride need not equal width × 4 |
| `setLockedPixelRGBA view x y r g b a` | Checked coordinates relative to the region |
| `fillLockedRGBA view r g b a` | Initialize the whole region |
| `copyLockedRGBA view source pitch` | Whole-region copy. Source capacity includes final-row padding |
| `unlockTextureRGBA` | Submit writes and invalidate the view. Not a GPU-completion report |
| `freeTextureLockBuffer` | Unlocks an active view before freeing metadata |

- Initialize every pixel before unlock, including error paths. Old contents are unavailable. The
  binding does not clear or track initialization.
- Copies preserve destination padding and pixels outside the region. Raw source and destination must
  not overlap.
- While locked, do not render, upload, destroy, or re-lock the texture. Another buffer does not make
  simultaneous locks safe.
- `withTextureLockRGBA` unlocks after ordinary returns, including `Left`. No rollback. Do not
  manually unlock or retain its view.
- Keep the texture alive and initialized through lock-storage cleanup. Generation checks require
  live storage and do not protect freed memory.
- Finish locks before rendering. Cleanup order: lock storage, texture, renderer, window.

Example: [Locking](../examples/Locking.idr). [Build/run and three-frame smoke
test](build.md#examples).  Fill/copy use fewer foreign calls than per-pixel writes. No zero-copy or
speed guarantee.
