# Core audio playback

Core `SDL3` / `SDL3.Scoped`. Initialize `audio` (optionally with `video`).  Default-device playback
only. [Resource/error rules](resources.md). Tracks, compressed assets, loops, and fades:
[Mixer](mixer.md).

## Streams and formats

PCM stores numeric samples. A sample frame contains one sample per channel.  `MkAudioSpec format
channels frequency` describes input, not the physical device: 1..8 interleaved channels and a
positive frame rate.

| `AudioFormat` | Bytes/sample | Silence |
| --- | ---: | --- |
| `AudioU8` | 1 | 128 |
| `AudioS8` | 1 | 0 |
| `AudioS16LE`, `AudioS16BE` | 2 | 0 |
| `AudioS32LE`, `AudioS32BE` | 4 | 0 |
| `AudioF32LE`, `AudioF32BE` | 4 | 0.0 |

- `openPlaybackStream spec` / `withPlaybackStream spec`: paused stream owning a separate logical
  default device.
- `playbackSpec` copies input metadata. SDL converts to the device format. Further format limits can
  fail acquisition.
- Do not rebind or reformat through raw SDL calls. This is not an unbound conversion stream or mixer
  track.
- Reuse independent streams for music/effects or overlapping sounds. No automatic voice pool.

## Queues and controls

| API | Contract |
| --- | --- |
| `queueAudio stream buffer offset count` | Copy PCM bytes into SDL. Does not start playback |
| `getPlaybackQueued` | Queued input bytes, clamped to 2147483647. Excludes converted/submitted device audio |
| `pausePlayback`, `resumePlayback`, `isPlaybackPaused` | Pause retains queued samples. Resume consumes them. Query reports state |
| `clearPlayback` | Discard pending stream data without pausing |
| `flushPlayback` | Mark current input end to drain conversion data. Neither clear nor start |
| `stopPlayback` | Pause, then clear. Stop on first failure, no rollback or gain reset |
| `setPlaybackGain`, `getPlaybackGain` | Linear amplitude multiplier. Finite nonnegative SDL-float range |

- Queue offset/count: `Bits32` bytes, whole input-frame alignment, actual capacity bounds. Count
  ≤2147483647.
- Zero count is a no-op with a valid offset. Samples must match `playbackSpec`.
- Reuse source buffers after return, not during queueing. SDL owns a copy and can allocate/convert
  internally.
- For continuous audio, refill ahead and flush only at input end. More input after flush is allowed,
  but repeated flushes can create gaps.
- Empty queue, pause, or stop does not prove audible completion. Already-submitted audio can remain.
- Gain 0 is silent, 1 unchanged, >1 can distort. Start low on real output. Changes apply during
  consumption and retain the queue.

## WAV files

| API | Contract |
| --- | --- |
| `loadWAV path` / `withWAV path` | Decode the entire file into owned memory, not incremental streaming |
| `wavSpec`, `wavByteLength` | Copied metadata |
| `queueWAV stream wav` | Copy the entire asset without starting playback |
| `queueWAVRange stream wav offset count` | Same alignment/count limits as PCM queueing. Split large assets into ranges |
| `playWAV stream wav` | Pause → clear → queue → flush → resume. Stops on first failure without rollback |

- WAV format, channel count, and rate must exactly match stream input. Queued copies survive
  `freeWAV`.
- Replay replaces that stream's pending audio. A format failure can occur after the old queue is
  cleared.
- Load once and reuse. Large assets plus queue copies consume memory. Feed PCM chunks for
  application-managed streaming.

## Threads and limits

- Individual audio operations can run on application threads. Serialize compound stop/restart
  operations and cleanup with all users.
- Never free a WAV during queueing or modify source bytes during a queue call.
- No Idris callbacks on SDL audio threads and no retained managed buffers.
- No recording, device enumeration/selection, compressed-file decoding, automatic refill, seeking,
  or finished notification in core.

## Example

[Audio](../examples/Audio.idr), [build/run arguments](build.md#examples). No window required.

| Command + Enter | Action |
| --- | --- |
| `p`, `r`, `m`, `s` | Pause, resume, restart, stop music |
| `f`, `x` | Retrigger / stop independent sound |
| `0`, `1` | Mute / restore music gain to 0.25 |
| `q`, empty line, EOF | Exit |
