# SDL3 for Idris 2

Thin SDL3 bindings for windows, 2D rendering, textures, keyboard, mouse, gamepads, text input,
clipboard text, file drops, timers, audio playback, and file/memory I/O. BMP images and WAV audio
are supported. Optional packages add image decoding (`sdl3-image`), reusable text (`sdl3-ttf`), and
audio tracks, looping, and fades (`sdl3-mixer`). The SDL GPU API is not bound.

Chez is the only supported backend. The current build targets Linux and produces a shared
library. Other platforms are not tested.

## Build and run

Install Idris 2 0.8.0 or newer, Chez Scheme, `pack`, a C compiler, Make, `pkg-config`, and SDL3
development files. SDL 3.2.12 or newer is required.  From the repository root, run:

```sh
pkg-config --modversion sdl3
pack --no-prompt --cg=chez build sdl3.ipkg
make test
make run-hello
```

The package build also compiles `cbits/libidris2_sdl3.so`. The Makefile sets the library search
path. Tests use dummy video and audio drivers and need no display or audio device.

`make example` builds these examples:

- [Hello](examples/Hello.idr): Window, texture drawing, resizing, and mouse input. Run with `make
  run-hello`.
- [Locking](examples/Locking.idr): Reusable storage for texture pixel updates. Run with `make
  run-locking`.
- [Audio](examples/Audio.idr): Independent music and sound playback. See the [audio
  guide](docs/audio.md#example-and-tests) for WAV arguments and controls.

## Use in your project

Add a local package entry to your application's `pack.toml`:

```toml
[custom.all.sdl3]
type = "local"
path = "/path/to/idris2-sdl3"
ipkg = "sdl3.ipkg"
```

Add `sdl3` to your `.ipkg` dependencies and build with `--cg=chez`.  Import `SDL3` for the typed API
and `SDL3.Scoped` for cleanup helpers.  At runtime, include this project's `cbits` directory and the
SDL3 library directory in `LD_LIBRARY_PATH`. The native library is separate from pack's Idris
installation.

## Safety

The types distinguish resources but do not enforce their lifetimes. Destroy textures before their
renderer, then destroy the window. Release all owned resources before `quit`. Use window, rendering,
and event functions on the main thread.

Creation functions return `Either String a`. For controls that report failure with `False`, call
`getError` immediately on the same thread. State queries that return `Bool` report state, not
success.

Scoped helpers clean up after ordinary `Right` and `Left` returns, not runtime exceptions or
callbacks that never return. Do not keep their handles after cleanup.  See [resource
ownership](docs/resources.md) before using manual cleanup or raw bindings.

## Guides

The subsystem guides describe the APIs, ownership, thread rules, and limits:

- [Video](docs/video.md): Windows, dimensions, display scaling, and window controls.
- [Rendering](docs/rendering.md): Drawing, coordinates, state queries, clipping, and blending.
- [Geometry](docs/geometry.md): Reusable triangle buffers, bulk updates, and CPU measurements.
- [Textures](docs/textures.md): BMP loading, render targets, uploads, and pixel locking.
- [Image](docs/image.md): Optional image decoding from files and borrowed streams.
- [TTF](docs/ttf.md): Optional fonts, reusable text, measurement, wrapping, and drawing.
- [Input and events](docs/input.md): Keyboard, mouse, cursors, text entry, clipboard, and drops.
- [Gamepads](docs/gamepads.md): Discovery, controls, connection events, and rumble.
- [I/O streams](docs/io.md): File and memory access, partial transfers, and cleanup.
- [Audio](docs/audio.md): PCM queues, WAV files, and playback controls.
- [Mixer](docs/mixer.md): Optional SDL3_mixer package, shared audio assets, tracks, loops, and fades.
- [Timing](docs/timing.md): Clocks, frame pacing, and display synchronization.
- [Resource ownership](docs/resources.md): Initialization, errors, cleanup, and scopes.
- [Native implementation](docs/internals.md): C adapters, reusable storage, and test limits.
