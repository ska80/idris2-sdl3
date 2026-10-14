# Geometry and bulk updates

A vertex combines a position, a color, and texture coordinates.  `GeometryBuffer` owns reusable
native arrays for vertices and triangle indices. Indices refer to vertices by zero-based position.
Import `SDL3` for operations and `SDL3.Scoped` for ownership helpers.

## Triangle storage

`newGeometryBuffer vertexCapacity indexCapacity` allocates both arrays once. Each capacity must fit
a signed 32-bit count.  Vertex capacity must be positive. Index capacity can be zero. Allocation
also depends on available memory and native address limits.  Vertices and indices start at
zero. Initialize the entries that drawing needs, then reuse the buffer.

`setVertex buffer index (MkVertex position color u v)` replaces one vertex.  The position uses
`Point RenderSpace`. The color uses `MkColor red green blue alpha` with byte channels.  The adapter
converts these channels to SDL float colors. Texture coordinates normally range from zero through
one across the texture.  Coordinates must fit finite SDL floats. Rejected values leave the vertex
unchanged.

`setGeometryIndex buffer slot vertexIndex` replaces one index. Both indices must fit their
corresponding capacities.  A triangle uses three indices. Different triangles can share vertices,
which avoids duplicating their data.  An index setter does not allocate native storage.

`drawGeometry renderer buffer vertexCount indexCount` submits untextured triangles.  `renderGeometry
renderer texture buffer vertexCount indexCount` submits textured triangles.  Both counts select
array prefixes. Zero indices uses consecutive groups of three vertices instead of the index array.
The submitted count must describe whole triangles. Referenced vertices must lie inside the submitted
vertex prefix.

The adapter scans indices when the vertex prefix is shorter than capacity. Full-capacity submissions
use the bounds established by the setters.  Drawing uses per-vertex color, not the renderer draw
color. SDL ignores texture color and alpha modulation for geometry.  Use the texture with its
creating renderer. Do not sample the active render target.  SDL can reject unsupported rendering or
texture coordinates. After `False`, read `getError` immediately.

## Ownership and threads

`freeGeometryBuffer` releases the arrays once. `withGeometryBuffer` releases them after ordinary
callback returns.  Do not free or retain a scoped buffer. Exceptions and callbacks that never return
do not guarantee cleanup.  Types distinguish geometry from point and rectangle storage, but do not
enforce lifetime or renderer identity.

Geometry storage does not belong to a renderer. Its updates need exclusive access, and rendering
must run on the main thread.  SDL consumes the arrays during submission, so reuse them after return,
not during the call.  Keep unchanged vertices and indices between frames. SDL and the Idris runtime
can still allocate internally.

## Bulk point and rectangle updates

`copyPoints destination firstIndex source byteOffset count` copies packed doubles from an Idris
`Data.Buffer`.  Each point uses 16 bytes for `x` and `y`. `copyRects` uses 32 bytes for `x`, `y`,
`width`, and `height`.  The format matches `Data.Buffer.setDouble` on Chez: native-endian 64-bit
doubles. It is not a portable file format.  Source byte offsets use `Bits64`. Destination indices
and entry counts use `Bits32`.

The adapters validate the actual source capacity, destination bounds, arithmetic, and finite-float
conversion before writing.  Invalid input leaves the destination unchanged. Zero entries permits an
end-of-buffer position.  The calls copy the values without retaining the source or allocating a
temporary native array.  Do not modify source or destination concurrently with a copy. Rectangle
sizes otherwise follow SDL semantics.

This function copies two point entries into existing storage:

```idris
import SDL3
import Data.Buffer

writeTwoPoints : PointBuffer -> Buffer -> IO Bool
writeTwoPoints points bytes = do
  -- The caller must supply at least 32 bytes before these Data.Buffer writes.
  setDouble bytes 0 10
  setDouble bytes 8 20
  setDouble bytes 16 30
  setDouble bytes 24 40
  copyPoints points 0 bytes 0 2
```

Keep the source buffer around the loop too. Make sure that each direct `Data.Buffer` write stays
within its capacity before calling the copy.  For small changes, compare individual setters with
rebuilding a packed source. Fewer foreign calls alone do not establish faster frames.

## CPU timing example

[BatchTiming](../examples/BatchTiming.idr) measures preparation and submission separately.
Preparation includes Idris loops, value construction, and storage updates. Submission measures the
SDL draw call, not GPU completion.  Clear and present run outside both measured intervals. Timer and
call overhead remain in the reported times.

From the repository root, run:

```sh
make example-batches
SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software \
  LD_LIBRARY_PATH="$PWD/cbits:/usr/local/lib:${LD_LIBRARY_PATH:-}" \
  examples/build/exec/sdl3-batch-timing
```

Each case uses 20 warm-up iterations and 200 measured iterations. The following ranges cover means
from three separate runs.  The machine used Linux x86-64, an Intel i7-1165G7, Chez 10.4.1, Idris
`0.8.0-b6cbc25d5`, and SDL 3.4.16.  The adapter used `-O2`. The CPU was not isolated or
frequency-locked.

| Work per iteration | Preparation, microseconds | Submission, microseconds |
| --- | ---: | ---: |
| 4096 individual point updates | 1216–1394 | 2.0–2.6 |
| 4096 packed points, including source writes and copy | 136–144 | 1.4–1.5 |
| 4096 points copied from an existing packed source | 8.3–8.6 | 1.4–1.5 |
| 4096 individual rectangle updates | 1225–1248 | 7.4–8.3 |
| 4096 packed rectangles, including source writes and copy | 246–249 | 7.2–7.3 |
| 4096 rectangles copied from an existing packed source | 14.5–16.0 | 6.8–7.9 |
| 1024 indexed quads, 4096 vertex updates, reused indices | 1323–1353 | 101–104 |

Packed updates reduced preparation time in this workload. Geometry still uses one foreign call per
vertex update.  Its preparation cost supports reusing unchanged data rather than rebuilding every
vertex each frame.  The cases do different drawing work and are not a comparison of geometry against
sprites.

These are local CPU measurements with the software renderer, not GPU timings or frame-time
guarantees.  Deferred rendering, presentation, and display synchronization are excluded. No
accelerated renderer was measured.  Use the same separation of preparation and submission for the
actual application, then measure full frames on its target hardware.
