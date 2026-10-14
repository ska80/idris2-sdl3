# Fonts and reusable text

`sdl3-ttf` uses SDL3_ttf fonts, renderer text engines, and text objects.  A text engine manages
glyph storage for a renderer. A glyph is a drawn form of a character.  Create text once and reuse
it. The binding does not rebuild a surface and texture for each draw.  Core-only applications do not
need SDL3_ttf.

## Build and use

Install SDL3_ttf 3.2.0 or newer and its development files. From the repository root, run:

```sh
pkg-config --modversion sdl3-ttf
make ttf test-ttf
```

Add `sdl3-ttf` alongside `sdl3` in the application dependencies. Add this entry alongside the core
entry in `pack.toml`:

```toml
[custom.all.sdl3-ttf]
type = "local"
path = "/path/to/idris2-sdl3"
ipkg = "sdl3-ttf.ipkg"
```

Import `SDL3.TTF` and `SDL3.TTF.Scoped`. At runtime, include `cbits` and the SDL library directory
in `LD_LIBRARY_PATH`.  The optional adapter is `libidris2_sdl3_ttf.so`. Use this entire subset on
the main thread.

## Fonts, engines, and text

Each successful `initTTF` needs one `quitTTF`. Close fonts and release engines and text before
shutdown.  `quitTTF` does not close fonts for you. `withTTF` balances initialization after an
ordinary return.

`openFont path pointSize` opens an owned font. The size must be finite, positive, and representable
as a positive SDL float.  Paths use UTF-8 and end at embedded NUL. `closeFont` releases the font
after all its text objects are destroyed.

`createRendererTextEngine renderer` creates an owned engine for a live core renderer.  `createText
engine font value` creates an owned text object. SDL_ttf copies the UTF-8 string and ends it at
embedded NUL.  Destroy text before its font or engine. Destroy the engine before its renderer, then
destroy the window.

This function draws one label through an existing engine and font:

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

For an application loop, keep `withText` outside the loop and draw the same object repeatedly.  All
scoped helpers skip their callback after failed acquisition. They preserve ordinary callback results
through cleanup.  They do not guarantee cleanup after exceptions, process exit, or callbacks that
never return.  Do not destroy or retain their supplied handles. Types do not prevent stale handles
or enforce engine and renderer identity.

## Updates, measurement, and drawing

`setTextString text value` replaces the copied content. Update only when content changes.  SDL_ttf
can allocate or rebuild internal data after an update. Reuse does not imply allocation-free drawing
or updates.

`setTextWrapWidth text width` uses text pixels and accepts `Bits32` values through 2147483647.  Zero
wraps only at newline characters. `setTextColor` takes four byte channels for red, green, blue, and
alpha.  These setters report success, not a text value. After `False`, read core `getError`
immediately.

`getTextSize` returns a copied `Size PixelUnits` through `Either String`.  Dimensions describe text
before renderer scaling. Each text object owns reusable native storage for this query.  The returned
size survives cleanup and does not change after later text updates.

`drawText text (MkPoint x y)` uses `Point RenderSpace` and the creating engine and renderer.
Coordinates must fit finite SDL floats. Drawing uses current renderer state and does not clear or
present the frame.  Application code still owns layout, widgets, event handling, and the draw loop.

## Example and tests

`make example-media` builds [Media](../examples/Media.idr), which also requires `sdl3-image`.  It
keeps the image, font, engine, and text alive around its draw loop. It updates text once per second.
Run it with an image path and a font path:

```sh
LD_LIBRARY_PATH="$PWD/cbits:/usr/local/lib:${LD_LIBRARY_PATH:-}" \
  examples/build/exec/sdl3-media picture.png /path/to/font.ttf
```

Escape closes the example. Add `--smoke` to stop after three frames.  The example stretches the
image to a fixed rectangle. It is not an image viewer or layout engine.

`make test-ttf` needs a font. It uses `SDL3_TEST_FONT` or searches standard DejaVu Sans paths on
Linux.  Tests cover copied UTF-8 strings, updates, wrapping, measurement, colors, drawing, cleanup,
failures, and type restrictions.  Tests use dummy video and the software renderer. Font appearance
and accelerated rendering need separate manual tests.

Font I/O streams, font fallback configuration, shaping controls, hit testing, and editable widgets
are outside this subset.  A future stream loader must define retained stream lifetime separately
from Image's call-only borrowing.  The current package does not expose a generic close-stream flag.
