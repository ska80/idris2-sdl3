# Implementation map

Contributor reference. Public contracts: [resources](resources.md). Commands and dependencies:
[build](build.md).

## Source layout

| Path | Purpose |
| --- | --- |
| `src/SDL3.idr` | Typed core handles and operations |
| `src/SDL3/Raw.idr` | Foreign calls: `prim__lowerCamelCase` |
| `src/SDL3/Events.idr`, `Flags.idr` | Copied event data and typed flags |
| `src/SDL3/Scoped.idr` | Core acquisition and temporary-state helpers |
| `src/SDL3/{Image,TTF,Mixer}*` | Independent optional packages with typed, raw, and scoped modules |
| `src/SDL3/Internal/Resource.idr` | Shared acquisition, cleanup, initialization, and state restoration |
| `src/SDL3/Internal/Result.idr` | Nullable pointers, owned-pointer results, nonnegative signed results |
| `src/SDL3/Internal/Audio.idr` | Shared audio-format codes via an internal interface |
| `src/SDL3/Internal/Handles.idr` | Unsafe pointer conversion for extension/core interoperability |
| `cbits/{core,image,ttf,mixer}.{c,h}` | Native adapters, separate shared libraries |
| `cbits/internal.h` | Shared finite-float and overflow-safe buffer-range tests |
| `cbits/runtime.mk` | Shared pkg-config discovery for runtime library paths |
| `vendor/` | [SDL3 and extension header references, versions, and checksums](../vendor/README.md) |
| `test/*.c`, `test/*.h`, `test/src` | Core native, Idris, and compile-time rejection tests. Shared WAV fixtures |
| `test/{image,ttf,mixer}/` | Each extension's native tests, fixtures, `Main.idr`, package, and Makefile |
| `test/common.mk` | Shared extension test build/run rules |

## Native boundary

- Prefer direct SDL calls when Chez supports their calling convention and value representation.
- Adapters handle booleans, float/double conversion, macros, structs/unions, and range validation.
- Use the [vendored SDL3 headers](../vendor/README.md) as API references, never SDL2 signatures.
- Native builds use installed headers through pkg-config. Keep enum/layout assertions against those
  build headers.
- Preserve private handle constructors. Normal imports must not expose internal pointer conversion.
- Keep type-only event polling separate from payload decoding. Payload decoding uses multiple
  foreign calls and constructs copied Idris values.
- Scalar error sentinels must lie outside valid ranges. Copy SDL errors before cleanup can replace
  them.
- `ResourceHelperTests` covers acquisition failure, cleanup order, state-setting failure, and error
  precedence.

## Storage and performance

- Pack owns `build/` directories and can replace them after compiler changes.
- Each test suite keeps native fixtures/executables in its own `native-build/`, outside its `build/`
  directory. Make dependencies track shared headers.
- Windows and text objects own reusable query storage. Other buffers are explicit resources around
  application loops.
- Texture-size queries validate through SDL before reading its public dimensions.
- Lock generations do not wrap. They reject stale views only while metadata remains alive, not after
  free.
- SDL and Idris can still allocate. Reused adapter storage does not imply allocation-free execution
  or zero overhead.
- Batch calls reduce foreign draw calls, not necessarily GPU operations. [Measured CPU workload and
  limits](geometry.md#cpu-timing-example).

## Tests

- Native tests: representations, bounds, enum/layout agreement, pixel results, and cleanup.
- Idris tests: typed calls, copied values, cached-query freshness, scopes, state restoration, and
  error precedence.
- Compile-time tests: wrong handles/units/access modes and private-constructor access.
- Build-directory regression: remove a suite's `build/.idrisCommit`, rerun it, and retain native
  fixtures outside that directory. Each extension has a separate pack build directory.
- Dummy/synthetic tests do not establish physical input, window policy, density, audio latency,
  display synchronization, or accelerated rendering.
- AddressSanitizer/UndefinedBehaviorSanitizer test native memory/arithmetic behavior, not Idris
  exceptions or full-stack correctness.
- SDL3_mixer 3.2.4 reports 104 leaked bytes during FluidSynth loading. Direct `MIX_Init` /
  `MIX_Quit` / `SDL_Quit` reproduces this without adapters.
- Mixer native sanitizer tests pass with only `FLUIDSYNTH_init` leaks suppressed. The full
  dependency stack is not leak-free.

Unfinished hardware, minimum-version, and deployment validation: [TODO](../TODO.md).
