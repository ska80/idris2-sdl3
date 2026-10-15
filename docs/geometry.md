# Geometry and bulk updates

Core API. [Resource/error rules](resources.md). Allocate buffers outside the frame loop and reuse
them.  Buffers own CPU memory, not a renderer. Updates need exclusive access. Drawing requires the
main thread.

## Point and rectangle batches

| Operation | Contract |
| --- | --- |
| `newPointBuffer`, `newRectBuffer` | `Bits32` capacity 1..2147483647, subject to native memory limits. Zero-initialized entries |
| `setPoint buffer index point` | `Point RenderSpace`. Checked zero-based index |
| `setRect buffer index rect` | `FRect`. Checked index. Dimensions follow SDL semantics |
| `drawPoints renderer buffer count` | Draw a prefix. Zero draws nothing on a valid renderer |
| `drawLines renderer buffer count` | Connected prefix. Fewer than two points draws nothing. Repeat the first point to close |
| `drawRects`, `fillRects` | Outline/fill a prefix. No implicit full-target rectangle |

Counts cannot exceed capacity. Unwritten entries remain zero, not skipped.  Release with matching
`free...` functions or `withPointBuffer` / `withRectBuffer`.

## Triangle storage

A vertex contains position, color, and texture coordinates. An index refers to a vertex's zero-based
position.

| Operation | Contract |
| --- | --- |
| `newGeometryBuffer vertexCapacity indexCapacity` | Fixed arrays. Positive vertex capacity, nonnegative index capacity. Both ≤2147483647 |
| `setVertex buffer index (MkVertex position color u v)` | `Point RenderSpace`, byte `MkColor r g b a`, normalized texture coordinates normally 0..1 |
| `setGeometryIndex buffer slot vertexIndex` | Slot and referenced vertex must fit their capacities |
| `drawGeometry renderer buffer vertices indices` | Untextured triangles |
| `renderGeometry renderer texture buffer vertices indices` | Textured triangles |

- Arrays start at zero. Initialize needed entries. Keep unchanged data between frames.
- Coordinates must fit finite SDL floats. Rejected vertex/index writes leave entries unchanged.
- Counts select prefixes and must describe whole triangles. Zero indices uses consecutive groups of
  three vertices.
- References must fit the submitted vertex prefix. Shorter-than-capacity vertex prefixes require an
  index scan.
- Geometry uses per-vertex color, ignoring renderer draw color and texture color/alpha modulation.
- Use the creating renderer for textures. Never sample the active target. SDL can reject rendering
  or texture coordinates.
- SDL consumes arrays during submission. Reuse/free only after return. Release with
  `freeGeometryBuffer` or `withGeometryBuffer`.

## Bulk point and rectangle updates

`copyPoints destination firstIndex source byteOffset count`. `copyRects` has the same arguments.
Source is `Data.Buffer`. Byte offset is `Bits64`. Destination index/count are `Bits32`.

| Layout | Bytes per entry |
| --- | --- |
| Point: x, y | 16 |
| Rectangle: x, y, width, height | 32 |

- Use native-endian 64-bit doubles, matching Chez `Data.Buffer.setDouble`. This is not a portable
  file format.
- Capacity, destination bounds, overflow, and finite-float conversion are validated before
  writes. Invalid input leaves the destination unchanged.
- Zero entries permits end-of-buffer positions. The adapter neither retains the source nor allocates
  a temporary native array.
- Direct source writes need their own bounds discipline. Do not modify either buffer during a copy.
- Example of packed preparation and submission: [BatchTiming](../examples/batches/Main.idr).

## CPU timing example

From the repository root ([example build rules](build.md#examples)):

```sh
SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software make -C examples/batches run
```

Historical measurements, before the helper refactor:

- Method: 20 warm-up + 200 measured iterations. Range of means across three runs.
- Setup: Linux x86-64, i7-1165G7, Chez 10.4.1, Idris `0.8.0-b6cbc25d5`, SDL 3.4.16 software
  renderer, adapter `-O2`.
- Preparation includes Idris loops, values, and writes. Submission times only the SDL draw
  call. Timer/call overhead remains included.
- Clear, present, GPU completion, and display synchronization are excluded. CPU frequency/affinity
  were not controlled.

| Per iteration | Prepare, µs | Submit, µs |
| --- | ---: | ---: |
| 4096 individual point updates | 1216–1394 | 2.0–2.6 |
| 4096 packed points, source writes + copy | 136–144 | 1.4–1.5 |
| 4096 points, copy only | 8.3–8.6 | 1.4–1.5 |
| 4096 individual rectangle updates | 1225–1248 | 7.4–8.3 |
| 4096 packed rectangles, source writes + copy | 246–249 | 7.2–7.3 |
| 4096 rectangles, copy only | 14.5–16.0 | 6.8–7.9 |
| 1024 indexed quads, 4096 vertex writes, reused indices | 1323–1353 | 101–104 |

Packed updates reduced preparation time in this workload. Geometry still makes one foreign call per
vertex write.  Different drawing workloads are not a geometry-versus-sprites comparison. These
numbers do not establish GPU call counts or faster full frames.
