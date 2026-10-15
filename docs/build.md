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
TTF 3.2.2, Mixer 3.2.4. The repository does not pin the pack collection.  [Vendored header copies
and versions](../vendor/README.md) are references, not build dependencies.

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

Make targets get each required SDL library directory from `pkg-config --variable=libdir`.  They
preserve the existing `LD_LIBRARY_PATH`. Core-only targets do not query optional packages.  Set
`PKG_CONFIG_PATH` for nonstandard installations, or override `PKG_CONFIG` to select another
pkg-config command.  After changing SDK installations, clean and rebuild.

For direct core-only executable runs from the repository root:

```sh
sdl_libdir=$(pkg-config --variable=libdir sdl3) || exit 1
export LD_LIBRARY_PATH="$PWD/cbits${sdl_libdir:+:$sdl_libdir}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

For direct extension runs, also add each selected extension's `libdir`. These directories can differ
from SDL3's.

## Targets and tests

| Command | Action |
| --- | --- |
| `make`, `make all` | Build core, Mixer, Image, and TTF packages and native adapters |
| `make core` | Build only core Idris modules and the core adapter |
| `make image`, `make ttf`, `make mixer` | Build the selected optional package |
| `make test` | Core native, Idris, and compile-time rejection tests |
| `make test-image`, `make test-ttf`, `make test-mixer` | Optional package tests |
| `make clean` | Remove library/test artifacts without prompts. Clean examples in their own directories |

Extension tests live in `test/image`, `test/ttf`, and `test/mixer`. Each directory contains
`Main.idr`, native tests, a Makefile, and a package file that matches its package name.  Package and
executable names are `image-test`, `ttf-test`, and `mixer-test`.  The core test package and
executable use `test`.  Each suite owns its `build/` and `native-build/` directories. Mixer reuses
the WAV fixture source in `test/`, but builds its own fixture library.

From an extension's test directory, `make` builds its tests and required packages. `make run` builds
and runs its native and Idris tests. `make native` runs only its native tests.  `make clean` removes
only that suite's outputs. Shared rules live in `test/common.mk`.

Full validation:

```sh
make test test-mixer test-image test-ttf
for example in basic locking audio mixer media batches; do
  make -C "examples/$example" || exit 1
done
git diff --check
```

- Tests use dummy video/audio and software rendering. They need no display or audio device.
- TTF tests need `SDL3_TEST_FONT` or DejaVu Sans in a standard Linux font directory. Use an absolute
  path for `SDL3_TEST_FONT`.
- If `pack run` hides compiler errors, use `pack --no-prompt --cg=chez build test/test.ipkg` (or the
  failing test package).
- Package builds share directories. Make serializes them. Do not run separate pack processes
  concurrently in this checkout.
- Hardware behavior and dependency leak limits: [testing limits](internals.md#tests).

## Examples

Each directory contains `Main.idr`, a Makefile, and a `.ipkg` file whose base name matches its
package name.  From the repository root:

```sh
cd examples/basic
make
make run
```

- `make` builds the example and its required library packages.
- `make run` builds if needed and sets the native library path. Pass program arguments with `ARGS`.
- `make clean` removes only that example's build output. Each example has its own `build/` directory.

| Directory | Extra packages | Run from that directory |
| --- | --- | --- |
| [basic](../examples/basic) | None | `make run` |
| [locking](../examples/locking) | None | `make run` |
| [audio](../examples/audio) | None | `make run ARGS="music.wav sound.wav"` |
| [mixer](../examples/mixer) | Mixer | `make run ARGS="music-file sound-file"` |
| [media](../examples/media) | Image, TTF | `make run ARGS="picture.png font.ttf"` |
| [batches](../examples/batches) | None | `make run` |

Asset paths are relative to the example directory. Shared rules live in `examples/common.mk`.

- Basic: close, Escape, or click the blue rectangle to exit. It waits for events when idle.
  `--smoke` draws one frame and exits.
- Locking: close or Escape. It requests VSync and falls back to timer pacing if the request fails.
  Motion follows elapsed time, not frame count. `--smoke` draws three frames and exits.
- Media: close or Escape. It waits for events or the next text update. `--smoke` draws three frames
  and exits. It needs both Image and TTF.
- Audio/Mixer: Enter submits a command. Controls and exit commands: [Audio](audio.md#example),
  [Mixer](mixer.md#limits-and-example).

Basic repaints its target texture after a target reset. Basic, Locking, and Media exit with an error
after a renderer device reset. Media also stops on target resets rather than assuming its text
engine can still draw. Restart the example after these errors. These examples do not implement
device recovery.

Headless rendering smoke test, from the repository root:

```sh
SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software make -C examples/locking run ARGS="--smoke"
```
