# Image loading

`sdl3-image` adds SDL3_image decoding to the existing core `Surface` and `Texture StaticAccess`
types.  Formats depend on the installed SDL3_image build. PNG and JPEG are tested. Core-only
applications do not need SDL3_image.

## Build and use

Install SDL3_image 3.2.0 or newer and its development files. From the repository root, run:

```sh
pkg-config --modversion sdl3-image
make image test-image
```

Add `sdl3-image` alongside `sdl3` in the application dependencies. Add this entry alongside the core
entry in `pack.toml`:

```toml
[custom.all.sdl3-image]
type = "local"
path = "/path/to/idris2-sdl3"
ipkg = "sdl3-image.ipkg"
```

Import `SDL3.Image` for loading and `SDL3.Image.Scoped` for cleanup helpers.  At runtime, include
`cbits` and the SDL library directory in `LD_LIBRARY_PATH`.  The optional adapter is
`libidris2_sdl3_image.so`. No image-specific initialization or shutdown call is required.

## Files and streams

`loadSurface path` returns an owned core surface. `loadTexture renderer path` returns an owned
static texture.  Both return `Either String` with a copied error on failure. Paths use UTF-8 and end
at embedded NUL.  The loaders decode the whole image before returning. File loaders leave no source
file open.

`loadSurfaceIO stream` and `loadTextureIO renderer stream` borrow a core `IOStream` during the call.
They never retain or close it, including on failure. The stream position can change on either
result.  Before another load, seek to the required position. Serialize all access to the stream
during decoding.

This function loads and draws through a borrowed file stream:

```idris
import SDL3
import SDL3.Scoped
import SDL3.Image.Scoped

paintImage : Renderer -> String -> IO (Either String ())
paintImage renderer path = withFileIO path ReadFile $ \stream =>
  withTextureIO renderer stream $ \texture => do
    True <- renderTexture renderer texture Nothing | False => Left <$> getError
    pure (Right ())
```

For repeated drawing, keep the texture alive around the application loop. Do not decode the file
every frame.  The decoded resource can outlive the stream. It does not refer to a managed buffer
passed to `openMemoryIO`.

## Ownership and threads

Release a surface with core `destroySurface`. Release a texture with core `destroyTexture`, before
its renderer.  Use textures on the main thread and with their creating renderer. A static texture
cannot use streaming texture locks.  Surface decoding can run on a worker thread. Do not modify or
destroy a surface while another thread uses it.

`withSurface`, `withTexture`, `withSurfaceIO`, and `withTextureIO` own only the decoded resource.
The caller still owns the stream and renderer. Failed acquisition skips the callback.  Cleanup
follows ordinary `Right` and `Left` returns, not exceptions, process exit, or callbacks that never
return.  Do not manually destroy a scoped resource or retain it after the callback.

Applications do not need pointer conversion. The extension uses an unsafe internal bridge between
binding modules.  The normal API does not export pointer access. See [resource
ownership](resources.md) for the limits of opaque handles.

## Example and limits

`make example-media` builds [Media](../examples/Media.idr) with both Image and TTF dependencies.  It
loads an image once and reuses a text object. The [TTF guide](ttf.md#example-and-tests) gives its
run command.

`make test-image` covers PNG/JPEG files, memory and file streams, pixel results, failure paths, and
type restrictions.  The tests also make sure that borrowed streams remain open after successful and
failed decoding.  Animation, format-specific controls, image saving, and decoder security limits are
outside this subset.  Do not treat arbitrary images as safe input. File size alone does not bound
decoded memory use.
