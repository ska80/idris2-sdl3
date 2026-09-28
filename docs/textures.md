# Textures and BMP images

Import `SDL3` for textures and surfaces. Import `SDL3.Scoped` for ownership and pixel-locking
scopes.  A surface stores pixels in CPU memory. A texture belongs to a renderer.  Use texture
operations on the main thread with the creating renderer alive.

## Creating textures

Access types restrict the operations available on a texture:

- `Texture StaticAccess`: Create with `createTextureFromSurface renderer surface`.
- `Texture StreamingAccess`: Create with `createStreamingTexture renderer width height` for pixel
  updates.
- `Texture TargetAccess`: Create with `createTargetTexture renderer width height` for off-screen
  drawing.

Streaming and target textures require positive dimensions and use RGBA32 pixels.  Each pixel
contains red, green, blue, and alpha bytes in that order on both byte orders.  New texture contents
are undefined. Initialize them before drawing the texture.  `getTextureSize` returns copied `Size
PixelUnits` dimensions for any access type.  Rendering state does not change these stored
dimensions.

`loadBMP path` returns an owned `Surface`. Conversion copies its pixels without consuming the
surface. Destroy the surface afterward, on success or failure.  The texture remains usable after
surface cleanup:

```idris
import SDL3
import SDL3.Scoped

loadImage : Renderer -> String -> IO (Either String (Texture StaticAccess))
loadImage renderer path = withBMP path (createTextureFromSurface renderer)
```

The caller owns the returned texture. BMP loading can run on a worker thread, but texture conversion
requires the main thread. Do not access the surface concurrently with conversion or
destruction. Other image formats are not bound.

## Drawing textures

`renderTexture renderer texture destination` draws the whole texture.  The destination is `Maybe
FRect` in drawing coordinates. `Nothing` fills the current target.  `renderTextureRegion renderer
texture source destination` selects an `FRect` in texture pixels, for example a sprite within a
larger image.

`renderTextureRotated renderer texture source destination angle center flip` adds rotation.  The
source is `Maybe FRect`, with `Nothing` selecting the whole texture.  Positive angles rotate
clockwise in degrees. `Nothing` for the center uses the destination midpoint.  `Just
(MkRotationCenter x y)` gives offsets from the destination's top-left corner in drawing units.
Flips are `NoFlip`, `FlipHorizontal`, `FlipVertical`, and `FlipBoth`.

## Render targets

`setRenderTarget renderer (Just texture)` selects a `Texture TargetAccess` for drawing.  Pass
`Nothing` to restore the window before `present`. Do not draw a texture into itself.  Targets retain
separate viewport, clipping, scale, and logical presentation state.  Draw color and draw blending
belong to the renderer.

`withRenderTarget renderer target action` temporarily selects a target and attempts to restore the
previous one after an ordinary callback return. It does not own either target.  Keep the renderer,
old target, and selected target alive throughout the scope.  See [temporary
state](resources.md#temporary-state) for failure rules.

`withTargetTexture` owns a texture without selecting it. Nest selection inside ownership.  Switch
away from a texture before its ownership scope ends, even if restoration failed.  The ownership
helper still destroys its texture after an ordinary callback return.

## Color, alpha, and filtering

`setTextureColorMod texture r g b` multiplies each source color channel by its byte value scaled to
0..1. `setTextureAlphaMod texture alpha` does the same for source alpha.  A value of 255 preserves
the original channel, rather than forcing opacity.  Neither operation changes stored pixels. Fade
premultiplied pixels by scaling RGB and alpha together.

`setTextureScaleMode texture NearestScale` selects individual pixels for pixel art.  `LinearScale`
interpolates neighboring pixels and is SDL's default.  `OtherScaleMode code` preserves unknown
modes. Equality compares SDL codes, not constructor names.  SDL can reject a mode or choose a
supported alternative.

`getTextureAlphaMod`, `getTextureBlendMode`, and `getTextureScaleMode` return copied results through
`Either String`. `setTextureBlendMode` controls texture blending independently of shapes.  See
[blending](rendering.md#blending) for modes and custom equations.  Controls return `Bool`, so read
`getError` immediately after `False`.

Scoped state helpers are `withTextureAlphaMod`, `withTextureBlendMode`, and `withTextureScaleMode`.
Each restores only its named state and borrows a live texture.  The alpha helper saves byte
precision. Avoid it if external code requires exact restoration of floating-point alpha. Color
modulation has no query or restoration helper.

## Uploading pixels

`updateTextureRGBA texture buffer pitch` uploads a whole streaming texture from `Data.Buffer`.
Pitch is the byte distance between row starts. It uses `Int32` and must cover at least `width * 4`
bytes. Capacity must cover `pitch * height`, including padding after the final row.

`updateTextureRegionRGBA texture region buffer pitch` updates a positive `Rect` wholly inside the
texture. The binding rejects invalid regions instead of clipping them.  Source byte zero supplies
the region's top-left pixel. Destination coordinates do not shift the source pointer. Capacity must
cover `pitch * region.height`, including final-row padding.  Pixels outside the region stay
unchanged.

Allocate source buffers outside the frame loop and reuse them.  Keep writes within capacity because
`Data.Buffer` writes do not enforce bounds.  Do not modify a buffer during upload. SDL consumes the
source during the call, so it can be reused afterward. SDL recommends locking for frequent texture
updates.

## Locking pixels

`withTextureLockRGBA storage texture region action` borrows write-only RGBA pixels.  Only streaming
textures support it. `Nothing` locks the whole texture, while `Just rect` locks a positive rectangle
wholly inside it. Create storage once with `withTextureLockBuffer` and reuse it across frames.

`LockedRGBA` is an opaque borrowed view. `lockedRGBASize` copies its region dimensions and
`lockedRGBAPitch` copies the byte stride between rows. These values can outlive cleanup.  Do not
assume the pitch equals width times four or that row padding is writable.  Pixel operations use
coordinates relative to the locked region:

- `setLockedPixelRGBA view x y r g b a` writes one checked pixel.
- `fillLockedRGBA view r g b a` initializes the entire region.
- `copyLockedRGBA view buffer pitch` copies the entire region from a source buffer.

The copy requires source capacity of at least `pitch * height`, including final-row padding.  Source
pitch must cover width times four bytes. Writes preserve destination row padding and pixels outside
the region. The source can be reused after copying, not during the call.

Initialize every pixel before unlocking, including on error paths. SDL does not promise old
contents, and the binding does not clear or track initialized pixels.  Fill or copy the whole region
before later work that can fail:

```idris
import SDL3
import SDL3.Scoped

paint : TextureLockBuffer -> Texture StreamingAccess -> IO (Either String ())
paint storage texture = withTextureLockRGBA storage texture Nothing $ \view => do
  True <- fillLockedRGBA view 20 40 60 255 | False => Left <$> getError
  pure (Right ())
```

Acquisition failure skips the callback. Both ordinary `Right` and `Left` returns unlock and submit
writes. Cleanup does not undo partial writes or wait for GPU completion.  Callback errors take
precedence over unlock errors. Exceptions and nonreturning callbacks do not guarantee unlock.

Do not render, upload, destroy, or re-lock the texture while locked.  A second storage buffer does
not make concurrent locks safe. Do not manually unlock, free storage, or retain the view inside a
scoped callback. Stale-view checks work only while the storage is alive. They cannot protect access
after storage destruction.

Manual operations are `newTextureLockBuffer`, `lockTextureRGBA`, `unlockTextureRGBA`, and
`freeTextureLockBuffer`. Freeing storage also releases an outstanding lock, so the texture must
remain alive and its locked pixels must be initialized.  A successful unlock means SDL was called,
not that a GPU upload succeeded.

## Ownership, examples, and tests

Finish each lock before rendering the texture. Release lock storage before its texture, then destroy
the renderer and window. Use a texture only with its creating renderer.  Types restrict access modes
but do not enforce lifetimes or renderer identity.  See [resource ownership](resources.md) for scope
limits.

Run `make run-locking` for a reusable-lock example. For three frames without a display, build with
`make example`, then run from the repository root:

```sh
SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software \
  LD_LIBRARY_PATH="$PWD/cbits:/usr/local/lib:${LD_LIBRARY_PATH:-}" \
  examples/build/exec/sdl3-locking --smoke
```

`make test` covers pixel results, upload bounds, padding, copied values, lock reuse, and cleanup.
Hardware-specific pitch and failures need separate testing. Per-pixel writes each cross the foreign
interface. Fill and bulk copy reduce call counts, but copying still moves bytes.  Neither uploads
nor locks promise zero-copy rendering or a speed increase.
