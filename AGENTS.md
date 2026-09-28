# Project guidance

Build with `pack --no-prompt --cg=chez build sdl3.ipkg`.  Run `make test` before you submit changes.

Chez is the only supported backend. Prioritize its correctness, performance, and examples.  Do not
add compatibility code or build targets for other backends.

Use `/usr/local/include/SDL3` as the API reference. Do not use SDL2 signatures.  Keep the bindings
thin. Use fixed-width values and distinct opaque handle types.  Keep C adapters limited to ABI
conversion, macros, and struct or union access.  Do not allocate native memory per frame or
event. Reuse caller-owned buffers.

Document ownership, cleanup order, thread rules, and safety limits.  Add tests for new bindings. Do
not claim zero overhead without measurements.
