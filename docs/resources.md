# Initialization and resource ownership

Import `SDL3` for the typed API. Import `SDL3.Scoped` for resource scopes.  A scope creates a
resource and releases it when its callback returns.  A callback is the function that receives the
resource.

## Initialization and errors

`init flags` returns `IO Bool`. Combine initialization flags with `<+>`, such as `video <+>
audio`. `neutral` supplies empty flags. Initialization flags and window flags have distinct
types. Initialize SDL on the main thread.

Creation functions return `IO (Either String resource)` and copy errors into `Left`.  Many controls
return `IO Bool`, with `False` for failure. After such a failure, call `getError` immediately on the
same thread. Another SDL call can replace the error.  A boolean state query, such as
`isWindowHidden`, is not a success indicator.

Call `quit` after releasing owned resources, even if initialization fails.  Copy an error before
cleanup if you need to report it afterward.  This example opens and closes a window without an event
loop:

```idris
import SDL3
import SDL3.Scoped

openAndClose : IO (Either String ())
openAndClose = do
  ok <- init video
  result <- if not ok then Left <$> getError else
    withWindow "SDL3" 640 480 resizable (\window => pure (Right ()))
  quit
  pure result
```

## Manual ownership

Destroy textures before their renderer, and renderers before their window.  Switch away from a
texture before destroying it as a render target.  Destroy playback streams before `quit`. Each
stream also closes its owned logical audio device.

Free surfaces, WAV data, event buffers, coordinate buffers, point buffers, rectangle buffers, and
texture-lock buffers exactly once. Use the matching destroy or free function. Do not use a handle
after destruction. The types prevent handle confusion, not access to freed memory, duplicate
cleanup, or renderer mismatches.

Events, strings, sizes, and points returned as copied values can outlive their source resource. A
copied identifier does not keep a window alive. A copied size does not track later changes. A
texture copied from a surface can outlive that surface.

## Scoped resources

Resource helpers return `IO (Either String a)` and take a callback with the same result
form. Acquisition failure returns `Left` without calling the callback.  Ordinary `Right` and `Left`
callback returns both trigger cleanup. Helpers preserve the result unless cleanup reports failure,
as with I/O stream closing. Callback errors take precedence over close errors. Runtime exceptions,
process exit, and nonreturning callbacks do not guarantee cleanup.

The helpers cover these resources:

- `withWindow` and `withRenderer` own windows and renderers.
- `withStreamingTexture`, `withTargetTexture`, and `withTextureFromSurface` own textures.
- `withBMP` and `withWAV` own loaded image and audio data.
- `withGamepad` owns one open gamepad reference, including after disconnection.
- `withSystemCursor` owns a cursor, without selecting it or restoring previous selection.
- `withFileIO` and `withMemoryIO` own streams that become invalid even after close failure.
- `withPlaybackStream` owns a playback stream and its logical device.
- `withEventBuffer` and `withCoordinateBuffer` own reusable event and conversion storage.
- `withPointBuffer`, `withRectBuffer`, and `withTextureLockBuffer` own reusable drawing storage.

Do not destroy a supplied resource or retain it after the callback returns.  Do not store functions
that use it later. Nest dependent resources inside their owners' scopes. Keep buffers around the
update loop, not inside each frame or event handler. Each helper entry creates a resource, rather
than reusing an earlier allocation.

`withTargetTexture` owns a texture but does not select it for drawing.  Nest `withRenderTarget`
inside its callback and finish selection before texture cleanup.  See [textures](textures.md) for
selection and pixel-locking rules.

## Temporary state

`withRenderTarget` is exported by `SDL3`. The other state helpers are exported by `SDL3.Scoped`:
`withDrawBlendMode`, `withTextureAlphaMod`, `withTextureBlendMode`, and
`withTextureScaleMode`. These helpers borrow existing resources and restore only their named
state. They do not own or destroy the resource.

A failed initial query skips the action. A failed setting also skips the action but still attempts
restoration. Setting and action errors take precedence over restoration errors. If only restoration
fails, the helper returns that error.  A `Left` result does not guarantee restoration.

Nested scopes save their own entry state. Ordinary callback returns trigger a restoration attempt,
but exceptions and nonreturning actions do not. Keep all borrowed resources alive throughout the
action and restoration. `withTextureLockRGBA` instead releases a pixel lock and submits writes, even
after a callback error. It does not undo writes.

## Thread rules and raw bindings

Run window, rendering, and event operations on the main thread. Do not share reusable event or
drawing buffers between threads. Audio operations have separate rules in the [audio
guide](audio.md). Timing functions can run on any thread.

`SDL3.Raw` exposes the unsafe foreign-function interface, which calls native C functions.  It does
not enforce pointer validity, buffer capacity, or resource lifetimes.  Use it only when you can
enforce the corresponding SDL and adapter requirements.  Mixing raw calls with typed handles can
break ownership and format assumptions.

## Examples and tests

[Hello](../examples/Hello.idr) nests texture and renderer ownership inside a window scope.
[Audio](../examples/Audio.idr) keeps playback streams inside loaded WAV scopes.  `make test`
exercises cleanup, skipped callbacks, preserved results, and rejection of wrong handle types. It
does not establish cleanup after runtime exceptions.
