# File and memory I/O

`IOStream` reads/writes bytes. It is not an audio stream. Video/audio initialization is not
required.  [Resource/error rules](resources.md). Serialize all operations, including close, on each
stream.

## Opening streams

`openFileIO path mode` returns `Either String IOStream`. Modes use binary I/O:

| Mode | Effect |
| --- | --- |
| `ReadFile` | Read existing file |
| `WriteFile` | Create/truncate, then write |
| `AppendFile` | Create if absent. Writes append |
| `ReadWriteFile` | Read/write existing file without truncation |
| `RewriteFile` | Create/truncate, then read/write |
| `AppendReadFile` | Read/append. Create if absent |

- Do not use `WriteFile` or `RewriteFile` for data to preserve. Opening discards existing contents.
- Append writes stay at the end even after seeking.
- `newMemoryIO`: empty growable SDL-owned stream. Read/write supported. Growth can allocate.
- `openMemoryIO buffer`: copy the whole buffer into owned storage and rewind. No retained managed
  pointer or borrowed view.
- Scopes: `withFileIO path mode`, `withMemoryIO buffer`.

## Transfers

| API | Direction |
| --- | --- |
| `readIO stream buffer offset count` | Stream → destination buffer range |
| `writeIO stream buffer offset count` | Source buffer range → stream |

- Offset/count: `Bits64` bytes. Actual buffer/native address bounds. Count
  ≤9223372036854775807. Invalid ranges return `Left` before transfer.
- `Right IOTransfer` means validated arguments, not a complete transfer. Always inspect
  `transferred`, `status`, and `error`.
- Partial progress is preserved. No automatic retry. Only the returned read prefix contains new
  data.
- Zero-byte requests preserve the old status but set `error = Nothing`.
- No buffer retention after return. Do not access transfer bytes concurrently. Keep direct
  `Data.Buffer` writes within capacity.

| `IOStatus` | Meaning |
| --- | --- |
| `IOReady` | Ready. An exact read to the end can remain ready until the next read |
| `IOFailure` | I/O failure |
| `IOEndOfFile` | No more input |
| `IONotReady` | Nonblocking operation not ready |
| `IOReadOnly` | Write attempted on read-only stream |
| `IOWriteOnly` | Read attempted on write-only stream |
| `OtherIOStatus code` | Unknown SDL code |

Nonzero failure/read-only/write-only requests include a copied error. Backends can report general
failure instead of a direction-specific status.

## Position and cleanup

| API | Contract |
| --- | --- |
| `getIOSize`, `tellIO` | `Either String Bits64`, bytes |
| `seekIO stream offset origin` | Signed `Int64` byte offset. `FromStart`, `FromCurrent`, `FromEnd`. Returns resulting position |
| `flushIO` | Request flushing, without closing or rewinding |
| `closeIO` | Releases stream/file/storage even on failure. Never retry or use afterward |

- Seek/size support and positions beyond existing data depend on the stream. These calls need not
  preserve previous transfer status.
- Flush/close success does not guarantee physical media completion.
- Scope callback errors precede close errors. Otherwise failed close becomes the result error.
- Separate streams can run on separate threads. No custom callback enters Idris from C.
- Stream-consuming extensions: [Image](image.md#stream-ownership). Typed Mixer/TTF loaders currently
  accept paths only.
