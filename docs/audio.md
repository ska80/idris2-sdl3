# Core audio playback

Import `SDL3` for core playback and WAV data. Import `SDL3.Scoped` for resource scopes.  Initialize
SDL with `audio`, or `video <+> audio` when the application also draws windows. The binding supports
default-device playback. It does not record audio, enumerate devices, or install callbacks that run
Idris code on an SDL audio thread.

## Streams and formats

PCM is audio represented as individual numeric samples. A sample frame contains one sample for each
channel. For example, stereo signed 16-bit audio uses four bytes per frame.  `MkAudioSpec format
channels frequency` describes the application's input, not the physical device.  The binding accepts
1 through 8 channels and a positive frequency in sample frames per second.  SDL can impose further
limits and reports failures through `Left` when opening a stream.

`AudioFormat` supports unsigned and signed 8-bit samples, signed 16-bit and 32-bit samples, and
32-bit floating-point samples. The multibyte constructors specify byte order explicitly:
`AudioS16LE`, `AudioS16BE`, `AudioS32LE`, `AudioS32BE`, `AudioF32LE`, and `AudioF32BE`.  The 8-bit
constructors are `AudioU8` and `AudioS8`. Channels use SDL's interleaved channel order.  Zero-filled
samples are silence for signed and floating-point formats. `AudioU8` silence uses 128.

`openPlaybackStream spec` returns `IO (Either String PlaybackStream)`. It opens a default playback
device, creates a stream, and binds them through `SDL_OpenAudioDeviceStream`. The device starts
paused. `playbackSpec stream` returns the copied input specification. SDL converts input to the
device's format when consuming it. Do not reformat or rebind this stream through external SDL calls.

Each `PlaybackStream` owns a separate logical device. SDL combines streams that use the same
physical device. Separate streams can therefore play background music and sound effects with
independent pause and volume controls. Destroying one stream also closes its owned logical device,
not another stream's device. This convenience type is not an unbound conversion stream or mixer
track.

## Queueing samples

`queueAudio stream buffer offset count` copies PCM bytes from an Idris `Buffer` into SDL.  Offset
and count are `Bits32` byte values. Both must align to whole sample frames. The range must fit the
buffer, and count must not exceed 2147483647. A zero count is a no-op when the offset is
valid. Invalid ranges fail before copying. The buffer's bytes must match `playbackSpec stream`.

Allocate source buffers outside the update loop and reuse them. Do not modify a source during a
queue call. After it returns, the buffer can be reused or released because SDL owns a copy.  The
adapter creates no temporary heap buffer, but SDL allocates queue storage and later converts or
copies samples internally. This is not a zero-copy API. No audio performance measurements exist.

Queueing does not start a paused device. Use `resumePlayback` after filling its queue.
`flushPlayback` signals the end of the current input so SDL can emit buffered conversion data.  It
does not discard samples or start playback. More input is allowed afterward, but repeated flushes
between continuous chunks can introduce gaps. For continuous audio, refill ahead of consumption and
flush only at the end of the input sequence.

`getPlaybackQueued stream` returns `IO (Either String Bits32)` for input bytes still queued.  SDL
clamps the count at 2147483647. The count can change while playback runs. It excludes audio that SDL
already converted or handed to the device. Zero is not proof of audible silence or exact playback
completion. The binding provides no finished-track notification or automatic refill.

## Playback controls

`pausePlayback` retains queued samples. `resumePlayback` continues consumption and does not restart
an empty stream. `isPlaybackPaused` returns a state, not a success indicator or a test for audible
sound. It requires a live stream. Pausing one owned logical device does not pause the others.

`clearPlayback` discards pending stream data without pausing its device. `stopPlayback` first
pauses, then clears. These calls cannot recall samples already handed to the device, so a short
audible tail can remain. Stop is not a fade or an atomic transaction. If a step fails, it returns
immediately and leaves partial state. It does not reset volume.

`setPlaybackGain stream gain` controls linear sample amplitude. Zero is silent, one leaves amplitude
unchanged, and values above one amplify and can distort the output. Start at a low gain when testing
real output.  NaN means "not a number". The binding rejects negative, infinite, NaN, and
out-of-float-range gains before conversion.

`getPlaybackGain` returns a copied `Double` or an SDL error in `Left`.  SDL uses float precision, so
widening to `Double` adds no precision. Gain applies during consumption, not when samples are
queued. Changing gain does not discard the queue.

The setters and controls return `IO Bool`. If they return `False`, read `getError` immediately.
Queries that can distinguish failure copy the error into `Left`. A successful call is not a promise
that a particular physical device is audible or available forever.

## WAV files, music, and sounds

`loadWAV path` loads and decodes an entire WAV file into owned native memory. It returns `IO (Either
String WAV)`. `wavSpec` and `wavByteLength` return copied metadata that survives cleanup.  `freeWAV`
releases both samples and metadata. `withWAV path action` handles cleanup on ordinary callback
returns. Paths are UTF-8 C strings, so embedded NUL characters end the path.

`queueWAV stream wav` copies the whole asset into a matching playback stream without starting it.
The WAV format, channel count, and sample rate must equal the stream's input specification.
`queueWAVRange stream wav offset count` copies an aligned byte range. The same per-call count limit
applies, so large assets need multiple ranges. Queued data survives WAV cleanup. Keep the WAV alive
through each queue call, but not necessarily throughout playback.

`playWAV stream wav` restarts one asset: pause, clear, queue, flush, then resume.  It replaces that
stream's pending audio and leaves other streams alone. It stops on the first failure without
rollback. For example, a format mismatch occurs after the old queue was cleared.  Replay with
another `playWAV` call. Pause and resume do not reload the file or reset its position.

A WAV can be loaded once and played repeatedly on matching streams. Use separate streams for music
and sounds. Retriggering a sound on one stream replaces its previous playback. For overlapping sound
instances, reuse a pool of separate streams rather than opening a device for every effect.  There is
no automatic voice allocation in this layer.

WAV loading is not incremental disk streaming. Large music files occupy native memory, and queueing
adds SDL-owned copies. The binding does not decode MP3, Ogg, or other compressed music containers.
It does not automatically loop music, seek, fade, or manage tracks. Applications can feed PCM
chunks, but gapless looping and a full music player are better handled by the planned mixer layer.

```idris
import SDL3
import SDL3.Scoped

-- SDL audio must already be initialized. The caller owns both loaded WAVs.
backgroundAndSound : WAV -> WAV -> IO (Either String ())
backgroundAndSound musicData soundData =
  withPlaybackStream (wavSpec musicData) $ \music =>
    withPlaybackStream (wavSpec soundData) $ \sound => do
      True <- setPlaybackGain music 0.25 | False => Left <$> getError
      True <- playWAV music musicData | False => Left <$> getError
      True <- playWAV sound soundData | False => Left <$> getError
      -- Real applications keep these scopes around their update loop.
      -- This delay is not an exact playback-completion test.
      delayNS 1000000000
      True <- stopPlayback music | False => Left <$> getError
      True <- stopPlayback sound | False => Left <$> getError
      pure (Right ())
```

## Ownership and threading

`withPlaybackStream spec action` destroys the stream and closes its device after an ordinary `Right`
or `Left` callback return. Do not destroy or retain the supplied handle. Its callback runs on the
caller's thread, not SDL's audio thread. Runtime exceptions, process exit, and callbacks that do not
return do not guarantee cleanup. These scopes do not enforce lifetimes in Idris types.  See
[resource ownership](resources.md) for shared scope and error rules.

Destroy playback streams before calling SDL `quit`. Free WAV resources exactly once and before final
SDL shutdown. Queued copies do not borrow their source WAV or buffer. No separate device handle
needs cleanup for these streams. Destroying a stream discards its remaining queued data.

SDL permits these individual audio operations from application threads. Serialize compound controls
on the same stream, especially restart and stop. Do not destroy a stream while another thread uses
it. Do not free a WAV while another thread queues it, or mutate a source buffer during a queue
call. The binding installs no audio callbacks and never passes managed data for deferred use by an
SDL audio thread. External raw calls can break these ownership and format assumptions.

## Example and tests

Build with `make example`, then run from the repository root:

```sh
LD_LIBRARY_PATH="$PWD/cbits:/usr/local/lib:${LD_LIBRARY_PATH:-}" \
  examples/build/exec/sdl3-audio music.wav sound.wav
```

`examples/Audio.idr` plays music once and accepts commands on standard input.  Use `p` to pause
music, `r` to resume, `m` to restart, and `s` to stop it.  Use `f` to play or retrigger the
independent sound stream and `x` to stop it.  Use `0` to mute music, `1` to restore its gain to
0.25, and `q` to quit.  Each command needs Enter. An empty line or end of input also exits.  The
example initializes only SDL audio and needs no window.

`make test` sets `SDL_AUDIO_DRIVER=dummy` and produces no audible output.  Native tests cover queue
copies, byte-range and frame alignment, WAV lifetime, format mismatch, invalid gains, stream
controls, and closure of owned logical devices. Idris tests cover all input format widths, scoped
results and errors, independent streams, WAV replay, queue counts, and copied metadata. Compile-time
tests reject wrong handles and formats. The example also runs with piped commands under the dummy
driver. Real sound quality, latency, hotplug, backend failures, and device policy need manual
testing. The tests do not establish audible timing or mixer behavior.
