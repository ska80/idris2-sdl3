# Project guidance

Build with `pack --no-prompt --cg=chez build sdl3.ipkg`.  Run `make test` before you submit changes.

Chez is the primary backend. Prioritize its correctness, performance, and examples.  RefC is
secondary. Preserve compatibility where practical without limiting Chez support.  For changes to
native bindings or build rules, also run `make test CG=refc`.

Use `/usr/local/include/SDL3` as the API reference. Do not use SDL2 signatures.  Keep the bindings
thin. Use fixed-width values and distinct opaque handle types.  Keep C adapters limited to ABI
conversion, macros, and struct or union access.  Do not allocate native memory per frame or
event. Reuse caller-owned buffers.

Document ownership, cleanup order, thread rules, and safety limits.  Add tests for new bindings. Do
not claim zero overhead without measurements.
