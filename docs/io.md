# File and memory I/O streams

Import `SDL3` for `IOStream` and its operations. I/O means reading or writing bytes.  Import
`SDL3.Scoped` for `withFileIO` and `withMemoryIO`.  These streams are separate from audio playback
streams and do not require SDL video or audio initialization.

## Opening streams

`openFileIO path mode` returns `Either String IOStream`.  Paths are UTF-8 C strings, so an embedded
NUL ends the path.  The file modes use binary I/O:

- `ReadFile`: Read an existing file.
- `WriteFile`: Create a file or truncate an existing file, then write.
- `AppendFile`: Create if absent and append writes.
- `ReadWriteFile`: Read and write an existing file without truncating it.
- `RewriteFile`: Create or truncate a file, then read and write.
- `AppendReadFile`: Read and append, creating the file if absent.

Do not use `WriteFile` or `RewriteFile` for data you need to preserve.  Both modes discard existing
file contents when opening succeeds.  Append modes write at the end even after seeking elsewhere.

`newMemoryIO` creates an empty, growable stream owned by SDL.  `openMemoryIO buffer` copies the
whole Idris `Buffer` into such a stream and rewinds it.  The source can then be reused or
released. SDL does not retain a managed pointer.  Memory streams permit reading and writing, and SDL
allocates storage as they grow.  This is not a borrowed or zero-copy view of the buffer.

## Reading and writing

`readIO stream buffer offset count` writes into a checked destination byte range.  `writeIO stream
buffer offset count` reads from a checked source byte range.  Offset and count use `Bits64`. The
range must fit the actual buffer and native address size.  A single count cannot
exceed 9223372036854775807. Invalid arguments return `Left` before transfer.

Successful validation returns `Right IOTransfer`, not a guarantee of complete I/O.  The record
contains `transferred : Bits64`, `status : IOStatus`, and `error : Maybe String`.  Always inspect
the count and status. A short operation can make progress and still fail.  The binding does not
retry or discard that partial progress.

The status constructors describe SDL's result:

- `IOReady`: The stream is ready.
- `IOFailure`: An I/O error occurred.
- `IOEndOfFile`: No more input is available.
- `IONotReady`: A nonblocking operation is not ready to complete.
- `IOReadOnly`: A write was attempted on a read-only stream.
- `IOWriteOnly`: A read was attempted on a write-only stream.
- `OtherIOStatus code`: Preserve an unknown SDL status.

Failures, read-only errors, and write-only errors include a copied SDL error string.  A file backend
can report a general `IOFailure` rather than a direction-specific status.  An exact read to the end
can remain `IOReady` until the next read.  A zero-byte request preserves the stream's earlier
status, including an earlier error or end-of-file state.  Its `error` field is `Nothing` because no
new transfer error occurs.

Reuse buffers across operations. Do not modify a write source or read destination concurrently with
the operation. After return, SDL no longer borrows those bytes.  Only the reported destination
prefix contains newly read data. Keep direct `Data.Buffer` writes within capacity because those
writes do not enforce bounds.

## Position, size, and flushing

`getIOSize stream` returns a copied size in bytes.  `tellIO stream` returns the current byte
position.  `seekIO stream offset origin` returns the resulting position, not a boolean.  All three
return `Either String Bits64` and preserve SDL failures in `Left`.

Seek offsets use signed `Int64` and origins are `FromStart`, `FromCurrent`, and `FromEnd`.  A
negative offset can move backward from the current position or end.  Support for seeking, size
queries, and positions beyond the data depends on the stream.  These functions do not promise to
preserve the previous transfer status.

`flushIO stream` requests flushing and returns `Bool`.  Read `getError` immediately after
`False`. Flushing is a separate operation from closing or rewinding. A successful operation is
subject to the underlying storage system's guarantees.

## Ownership and threading

`closeIO` releases the stream and its owned file or memory storage.  The handle becomes invalid even
if close returns `False`, for example after a failed output flush.  Do not retry close or access the
handle afterward. Copy the error immediately when close fails.  Closing a file does not itself
guarantee that bytes reached physical media.

`withFileIO path mode action` and `withMemoryIO buffer action` close after ordinary callback
returns.  If acquisition fails, the callback does not run. Callback errors take precedence over
close errors.  If the callback succeeds but close fails, the helper returns the close error.  Do not
close or retain the supplied handle. Exceptions and nonreturning callbacks do not guarantee cleanup.

Serialize all operations on the same stream, including close. Separate streams can be used from
separate application threads. Copied transfer results survive stream cleanup.  The binding installs
no custom I/O callbacks that enter Idris from C.  See [resource ownership](resources.md) for general
scope limits.

## Example and tests

This function copies a source buffer into a stream, then reads into a reusable destination:

```idris
import SDL3
import SDL3.Scoped
import Data.Buffer

copyThroughIO : Buffer -> Buffer -> Bits64 -> IO (Either String IOTransfer)
copyThroughIO source destination count = withMemoryIO source $ \stream =>
  readIO stream destination 0 count
```

`make test` covers file modes, memory copying and growth, bounds, seek offsets, end-of-file, partial
results, scoped errors, and closed-stream cleanup. Native fixtures exercise partial write errors and
close failures without reusing the invalid handle.  Disk failures, permissions, and
platform-specific file behavior need separate tests.

## Extension loaders

These are SDL core I/O streams, not decoder objects. The optional [Image package](image.md) borrows
them during decoding.  Its loaders never close or retain the stream, including on failure. Decoding
can change its position.

The typed mixer and font loaders currently take paths, not streams. Future stream loaders need
separate ownership and retention rules.  Do not pass a scoped stream to a consumer that retains it
past the scope or closes it independently.
