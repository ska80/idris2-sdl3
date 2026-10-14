# Native implementation and testing

Most applications need only `SDL3` and `SDL3.Scoped`.  `SDL3.Raw` is the foreign-function interface
to SDL and `cbits/core.c`.  This page describes implementation constraints, not additional public
API guarantees.  See [resource ownership](resources.md) before using raw pointers.

## The C boundary

Direct bindings call SDL when the calling convention and value representation permit it.  C adapters
convert SDL boolean results to integers and floating-point values to `Double`.  They also access
event unions, expand macros, and validate storage bounds.  Definitions in `cbits/core.h` use SDL3
headers, not SDL2 signatures.

Idris `Double` represents C `double`, not C `float`.  Drawing values narrow to SDL
floats. Coordinate results widen into a separate double-valued structure. Widening does not add
precision. Event fields are copied through C accessors because different event types use different
members of SDL's union.

Native assertions and tests compare layout, flags, and enum values with SDL headers.  Some scalar
adapters use out-of-range failure values instead of output allocations.  The typed layer converts
failures to copied errors where its result type permits it.  Raw callers must enforce pointer
validity, capacity, alignment, and ownership themselves.

## Reusable storage

Windows own size-query storage. Coordinate conversion uses caller-owned storage.  Chez reads the
corresponding fields and the typed API returns copied Idris records.  Texture-size queries validate
through SDL, then read the public integer texture dimensions.  Never inspect these pointers after
their owner is destroyed.

Event, coordinate, point, rectangle, geometry, input snapshot, render-state, and texture-lock
buffers are explicit resources.  Allocate them outside update loops and reuse them. A texture-lock
buffer owns metadata, while SDL owns the locked pixels. Generation checks reject stale views only
while the metadata remains alive. Generations do not wrap, so an exhausted buffer rejects new locks.

Audio queue calls copy source samples into SDL-owned storage.  Texture uploads pass the source
buffer to SDL for consumption during the call.  Neither operation keeps a managed source pointer for
later use.  Raw lock copies additionally require nonoverlapping source and destination memory.

## Performance limits

The adapters reuse storage rather than allocating event or drawing arrays per call.  SDL and the
Idris runtime can still allocate internally. Event decoding makes multiple foreign calls and
constructs Idris values. Text events create copied Idris strings.  There is no claim of zero
overhead or allocation-free application execution.

Batch drawing reduces foreign draw calls, not necessarily GPU operations.  Each pixel setter makes a
foreign call, while a fill or bulk copy handles a region.  Bulk copies still move bytes, and
unlocking can cause an SDL upload.  Measure the workload on the target system before choosing an
update strategy.

The [batch timing example](geometry.md#cpu-timing-example) measures CPU preparation and submission
separately.  Its packed point and rectangle updates reduced preparation time in the measured
software-renderer workload.  Those results do not establish GPU call counts, frame-time
improvements, or allocation-free execution.

## Tests

Run `make test` from the repository root. It builds the package, native tests, and Idris tests.
Dummy video and audio drivers avoid display and sound-device requirements.  Rendering tests use the
software renderer. `make example` builds the core examples separately. Optional mixer tests and
examples use `make test-mixer` and `make example-mixer`. Image and TTF tests use `make test-image`
and `make test-ttf`.  `make example-media` builds their combined example. TTF tests require DejaVu
Sans or a font path in `SDL3_TEST_FONT`.

Native executables and fixture libraries live in `test/native-build`, outside pack's `test/build`
directory.  Pack can replace its entire build directory after a compiler change. The separate native
directory survives this replacement.  Clean builds and a rebuild after removing
`test/build/.idrisCommit` exercise this boundary.  The root Makefile serializes package builds,
including with `make -j`.  Do not start separate pack processes against a shared build directory at
the same time.

Native tests cover adapter validation, byte layout, enum mappings, and resource cleanup.  Idris
tests cover typed operations, copied values, scopes, state restoration, and pixel results.
Compile-time tests in `test/src/TypeSafety.idr` reject handle confusion and invalid access types.
Test fixtures are separate from the binding library.

Synthetic events establish decoding, not physical input or event ordering.  Dummy drivers do not
establish real window-manager policy, display density, audio latency, GPU behavior, or restoration
failures on hardware. Runtime exceptions and nonreturning callbacks are outside ordinary-return
scope guarantees. Use manual tests and measurements for those cases.

The installed SDL3_mixer 3.2.4 build reports 104 leaked bytes during FluidSynth loading under
LeakSanitizer. A direct `MIX_Init`/`MIX_Quit`/`SDL_Quit` program reproduces this without binding
code.  The mixer native tests pass AddressSanitizer and UndefinedBehaviorSanitizer with only
`FLUIDSYNTH_init` leaks suppressed. This is not a leak-free result for the full dependency stack.
