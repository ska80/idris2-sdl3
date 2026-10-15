# Project guidance

Build with `pack --no-prompt --cg=chez build sdl3.ipkg`.  Run `make test` before you submit changes.
Before each commit, remove completed items from `TODO.md`. Keep only remaining work in that file.

Chez is the only supported backend. Prioritize its correctness, performance, and examples.  Do not
add compatibility code or build targets for other backends.

Use `/usr/local/include/SDL3` as the API reference. Do not use SDL2 signatures.  Keep the bindings
thin. Use fixed-width values and distinct opaque handle types.  Keep C adapters limited to ABI
conversion, macros, and struct or union access.  Do not allocate native memory per frame or
event. Reuse caller-owned buffers.

Document ownership, cleanup order, thread rules, and safety limits. Keep documentation as concise
reference material. Link shared contracts instead of repeating them. Add tests for new bindings.  Do
not claim zero overhead without measurements.

Build/test reference: `docs/build.md`. Source map: `docs/internals.md`. Shared contracts:
`docs/resources.md`.
