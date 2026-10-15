# Image decoding

Package `sdl3-image`. Imports `SDL3.Image`, `SDL3.Image.Scoped`.  [Build/setup](build.md),
[resource/error rules](resources.md). No image-specific initialization/shutdown.

## Loaders

All loaders return `Either String` and decode before returning. Formats depend on the installed
SDL3_image build. PNG/JPEG are tested.

| Loader | Result | Scope |
| --- | --- | --- |
| `loadSurface path` | Core `Surface` | `withSurface path` |
| `loadTexture renderer path` | Core `Texture StaticAccess` | `withTexture renderer path` |
| `loadSurfaceIO stream` | Core `Surface` | `withSurfaceIO stream` |
| `loadTextureIO renderer stream` | Core `Texture StaticAccess` | `withTextureIO renderer stream` |

- Release results with core `destroySurface` / `destroyTexture`. No pointer conversion is needed in
  applications.
- Texture operations require the creating renderer and main thread. Static textures cannot use
  streaming locks.
- Surface decoding can run on a worker thread. Serialize modification/destruction with every surface
  user.
- Load once around repeated drawing, not per frame. File loaders leave no source file open.

## Stream ownership

- Borrow only during the call. Never retain or close the source, including on failure.
- Position can change on success or failure. Seek before decoding again. Serialize access during
  decoding.
- Decoded resources can outlive the stream and any buffer copied into `openMemoryIO`.
- Scopes own only the decoded result, not the stream or renderer.

Example with a borrowed file stream:

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

## Limits and example

- No animation, image saving, or format-specific controls in this subset.
- Treat arbitrary images as untrusted. Encoded file size does not bound decoded memory use.
- [Media](../examples/Media.idr) combines image loading and reusable
  text. [Build/run](build.md#examples).
