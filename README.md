# SDL3 for Idris 2

Thin typed bindings. Chez only. Tested on Linux x86-64.

| Package | Features |
| --- | --- |
| `sdl3` | Windows, 2D rendering, textures, input/events, timers, WAV/PCM playback, file/memory I/O |
| `sdl3-image` | Optional image decoding |
| `sdl3-ttf` | Optional fonts and reusable text |
| `sdl3-mixer` | Optional audio assets, tracks, loops, and fades |

## Build and run

Install the [build requirements](docs/build.md#requirements). From the repository root:

```sh
pack --no-prompt --cg=chez build sdl3.ipkg
make test
cd examples/hello
make
make run
```

[Application setup, optional packages, tests, and examples](docs/build.md).

## API reference

Import `SDL3` and `SDL3.Scoped` for core operations and cleanup helpers.  Read the [resource
contract](docs/resources.md) before using handles or scopes.  Types distinguish resources and units,
but do not enforce lifetimes or renderer identity.

| Topic | Reference |
| --- | --- |
| Windows and display sizes | [Video](docs/video.md) |
| Drawing, coordinates, renderer state | [Rendering](docs/rendering.md) |
| Reusable batches and CPU measurements | [Geometry](docs/geometry.md) |
| BMP, textures, uploads, locks | [Textures](docs/textures.md) |
| Image files and streams | [Image](docs/image.md) |
| Fonts, measurement, text drawing | [TTF](docs/ttf.md) |
| Keyboard, mouse, text entry, clipboard, drops | [Input and events](docs/input.md) |
| Gamepad discovery, state, labels, rumble | [Gamepads](docs/gamepads.md) |
| File/memory transfers | [I/O](docs/io.md) |
| Core playback | [Audio](docs/audio.md) |
| Shared audio assets and tracks | [Mixer](docs/mixer.md) |
| Clocks, delays, VSync | [Timing](docs/timing.md) |

For contributors and agents: [AGENTS.md](AGENTS.md), [implementation map](docs/internals.md),
[remaining work](TODO.md).  The SDL GPU API, game engines, widgets, scene graphs, and application
policy are outside this library.
