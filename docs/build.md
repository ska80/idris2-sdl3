# Build, test, and run

## Requirements

- Backend/platform: Chez only. Tested on Linux x86-64. Other platforms are untested.
- Tools: Idris 2 0.8.0+, Chez, pack, a C compiler, Make, pkg-config.
- Native dependencies: development headers and shared libraries for the selected packages below.

| Idris package | pkg-config name | Minimum native version | Native adapter |
| --- | --- | --- | --- |
| `sdl3` | `sdl3` | 3.2.12 | `libidris2_sdl3.so` |
| `sdl3-image` | `sdl3-image` | 3.2.0 | `libidris2_sdl3_image.so` |
| `sdl3-ttf` | `sdl3-ttf` | 3.2.0 | `libidris2_sdl3_ttf.so` |
| `sdl3-mixer` | `sdl3-mixer` | 3.2.0 | `libidris2_sdl3_mixer.so` |

Tested setup: pack `nightly-261014`, Idris `0.8.0-b6cbc25d5`, Chez 10.4.1, SDL 3.4.16, Image 3.4.6,
TTF 3.2.2, Mixer 3.2.4. The repository does not pin the pack collection.

## Application setup

Add this local entry to the application's `pack.toml`:

```toml
[custom.all.sdl3]
type = "local"
path = "/path/to/idris2-sdl3"
ipkg = "sdl3.ipkg"
```

For each selected extension, repeat the entry with its package name and matching `.ipkg` filename.
Add those package names to the application's `.ipkg` `depends` field. Extensions depend on
`sdl3`. Core-only builds do not need them.

- Typed imports: `SDL3`, `SDL3.Image`, `SDL3.TTF`, `SDL3.Mixer`.
- Cleanup imports: append `.Scoped` to the corresponding module name.
- Build backend: `--cg=chez`.
- Runtime: deploy the selected native adapters and SDL libraries. Pack's Idris installation does not
  install these shared libraries.

For commands below, run from the repository root and set the library path once:

```sh
export LD_LIBRARY_PATH="$PWD/cbits:/usr/local/lib:${LD_LIBRARY_PATH:-}"
```

Use the actual installed SDL library directory if it differs. Make targets set this path themselves.

## Targets and tests

| Command | Action |
| --- | --- |
| `make` | Build core Idris modules and the core adapter |
| `make image`, `make ttf`, `make mixer` | Build the selected optional package |
| `make test` | Core native, Idris, and compile-time rejection tests |
| `make test-image`, `make test-ttf`, `make test-mixer` | Optional package tests |
| `make clean` | Remove generated Idris and native artifacts without prompts |

Full validation:

```sh
make test test-mixer test-image test-ttf example example-mixer example-media example-batches
git diff --check
```

- Tests use dummy video/audio and software rendering. They need no display or audio device.
- TTF tests need `SDL3_TEST_FONT` or DejaVu Sans in a standard Linux font directory.
- If `pack run` hides compiler errors, use `pack --no-prompt --cg=chez build test/test.ipkg` (or the
  failing test package).
- Package builds share directories. Make serializes them. Do not run separate pack processes
  concurrently in this checkout.
- Hardware behavior and dependency leak limits: [testing limits](internals.md#tests).

## Examples

Set the runtime path above before running executables directly.

| Source | Build | Run / arguments |
| --- | --- | --- |
| [Hello](../examples/Hello.idr) | `make example` | `make run-hello` |
| [Locking](../examples/Locking.idr) | `make example` | `make run-locking` or direct run with `--smoke` |
| [Audio](../examples/Audio.idr) | `make example` | `examples/build/exec/sdl3-audio music.wav sound.wav` |
| [MixerExample](../examples/MixerExample.idr) | `make example-mixer` | `examples/build/exec/sdl3-mixer-example music-file sound-file` |
| [Media](../examples/Media.idr) | `make example-media` | `examples/build/exec/sdl3-media picture.png font.ttf [--smoke]` |
| [BatchTiming](../examples/BatchTiming.idr) | `make example-batches` | `examples/build/exec/sdl3-batch-timing` |

- Hello: close, Escape, or click the blue rectangle to exit.
- Locking/Media: Close or Escape. `--smoke` stops after three frames. Media needs both Image and
  TTF.
- Audio/Mixer: Enter submits a command. Controls and exit commands: [Audio](audio.md#example),
  [Mixer](mixer.md#limits-and-example).

Headless rendering smoke test:

```sh
SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software examples/build/exec/sdl3-locking --smoke
```
