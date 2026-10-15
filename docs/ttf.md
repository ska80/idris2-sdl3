# Fonts and reusable text

Package `sdl3-ttf`. Imports `SDL3.TTF`, `SDL3.TTF.Scoped`. Main thread only.
[Build/setup](build.md), [resource/error rules](resources.md).

## Resources

| API | Contract / scope |
| --- | --- |
| `initTTF`, `quitTTF` | Balance each successful initialization. `withTTF` |
| `openFont path pointSize`, `closeFont` | Finite positive size representable as a positive SDL float. `withFont` |
| `createRendererTextEngine renderer`, `destroyRendererTextEngine` | SDL_ttf manages glyph storage. `withRendererTextEngine` |
| `createText engine font string`, `destroyText` | Copies UTF-8 content. `withText` |

- Glyph: drawn form of a character. Reuse engines/text objects. Do not rebuild a surface/texture for
  each frame.
- Cleanup: Text before font/engine. Engine before renderer. Fonts before `quitTTF`. SDL `quit` last.
- `quitTTF` does not close fonts. Types do not enforce engine/renderer identity or lifetime.

## Updates and drawing

| API | Contract |
| --- | --- |
| `setTextString text value` | Replace copied content only when it changes |
| `setTextWrapWidth text width` | `Bits32` text pixels, 0..2147483647. Zero wraps only at newlines |
| `setTextColor text r g b a` | Byte RGBA |
| `getTextSize text` | `Either String (Size PixelUnits)` before renderer scaling. Reuses text-owned query storage |
| `drawText text (MkPoint x y)` | `Point RenderSpace`, finite SDL-float coordinates. Current renderer state. No clear/present |

Copied measurements survive cleanup but do not track later updates.  SDL_ttf can allocate/rebuild
internal data on updates or drawing. Reuse is not an allocation-free guarantee.

```idris
import SDL3
import SDL3.TTF
import SDL3.TTF.Scoped

paintLabel : RendererTextEngine -> Font -> IO (Either String (Size PixelUnits))
paintLabel engine font = withText engine font "Hello, café" $ \text => do
  True <- setTextWrapWidth text 300 | False => Left <$> getError
  True <- setTextColor text 240 220 160 255 | False => Left <$> getError
  Right size <- getTextSize text | Left err => pure (Left err)
  True <- drawText text (MkPoint 20 30) | False => Left <$> getError
  pure (Right size)
```

For repeated drawing, keep `withText` around the application loop.

## Limits and example

- No font-stream loading, fallback configuration, shaping controls, hit testing, or editable widgets
  in this subset.
- Layout and event handling belong to the application. Future font-stream APIs need retention rules
  distinct from Image's call-only borrowing.
- [Media](../examples/media/Main.idr) reuses an image/font/engine/text and updates text once per
  second. [Build/run and test-font setup](build.md).
