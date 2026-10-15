# Mixer

Package `sdl3-mixer`. Imports `SDL3.Mixer`, `SDL3.Mixer.Scoped`.  [Build/setup](build.md),
[resource/error rules](resources.md). Core formats: [audio](audio.md#streams-and-formats).

## Resources and assets

| API | Contract / scope |
| --- | --- |
| `initMixer`, `quitMixer` | Balance each successful initialization. `withMixerLibrary` |
| `createMixer` | `Mixer DeviceOutput`. Default logical playback device. Initializes SDL audio internally. `withMixer` |
| `createMemoryMixer spec` | `Mixer MemoryOutput`. Fixed format, no device/background processing. `withMemoryMixer` |
| `loadAudio mixer path mode` | Whole file in memory. Loading mixer is a format hint. `withAudio` |
| `createTrack mixer` | Reusable playback of one assigned input. `withTrack` |
| `newPlayOptions` | Reusable playback properties. `withPlayOptions` |
| `getAudioDuration` | `KnownFrames count`, `UnknownDuration`, or `InfiniteDuration`, in asset sample frames |
| `getAudioDecoders` | Copied initialized decoder names, not guaranteed file extensions |

- `DecodeOnPlayback` retains encoded data. `Predecode` retains decoded samples. Neither is
  incremental disk streaming.
- Formats depend on installed decoders. Multiple tracks/mixers can share one asset. Assets can
  outlive the loading mixer.
- Input/asset frames contain one sample per input channel. They are not necessarily output frames.

## Playback and options

| API | Contract |
| --- | --- |
| `setTrackAudio track (Just asset)` | Retain input. Assignment alone does not start a stopped track |
| `setTrackAudio track Nothing` | Remove input. A playing track stops on subsequent processing |
| `playTrack track Nothing` | Start/restart one play from the beginning, no fade. Restarts paused tracks too |
| `playTrack track (Just options)` | Read properties during the call. Do not retain them |
| `pauseTrack`, `resumeTrack` | Hold/continue position |
| `stopTrack track fadeFrames` | Zero stops immediately. Positive input-frame count starts an asynchronous fade |
| `setTrackPlaybackPosition` | Seek input without starting. Support/precision depend on decoder |
| `getTrackPlaybackPosition` | `Either String Bits64`, input frames |
| `trackMSToFrames track milliseconds` | Convert `Bits32` milliseconds using currently assigned input rate |
| `trackPlaying`, `trackPaused` | State, not success or exact audible completion. Paused is not playing |

| Option setter | Value |
| --- | --- |
| `setPlayLoops` | `PlayOnce`, `Repeat n` additional plays, `LoopForever`. `Repeat 0` is one play. n ≤2147483647 |
| `setPlayStartFrames` | Initial input-frame position |
| `setPlayLoopStartFrames` | Input-frame position for later repeats |
| `setPlayFadeInFrames` | Input frames from silence. Zero disables fade |

- Frame values must fit nonnegative signed 64-bit range. Invalid setters preserve the old property.
- Allocate/configure options outside the update loop. Changes affect later play calls, not current
  playback.
- Restart after replacing active input/configuration. Later `playTrack` resets seek position from
  its options.
- A decoder can accept looping but stop when seeking fails. Paused tracks do not advance fades.
- Reuse separate tracks for overlapping sounds. No automatic track pool. Submitted device audio can
  remain after stopping.

## Gain

- `setMixerGain` / `getMixerGain`: whole output. `setTrackGain` / `getTrackGain`: one track,
  excluding master gain and fades.
- Linear amplitude: 0 silent, 1 unchanged, >1 can distort. Setters require finite nonnegative values
  that fit SDL float.
- Getters return `Double` with SDL float precision. Gain does not report audible completion.

## Output to memory

`generateMixer mixer buffer offset count` accepts only `Mixer MemoryOutput` and advances playback
explicitly.

- Offset/count: `Bits32` bytes, aligned to whole output frames. Actual capacity/native address
  bounds. Count ≤2147483647.
- Success initializes the entire requested range. Returned bytes exclude appended silence and can be
  zero.
- Reuse the buffer after return, not during generation. No temporary native heap buffer in the
  adapter. SDL/decoders can allocate internally.

## Ownership and threads

- Tracks retain assigned assets. `destroyAudio` releases only the caller's reference. Do not use
  that caller handle afterward.
- Destroy tracks before their mixer. `destroyMixer` also destroys remaining tracks and closes its
  owned device. Child handles then become invalid.
- Release assets/options before final `quitMixer`. SDL `quit` last. Final mixer quit destroys
  remaining mixer objects and invalidates handles.
- Create/destroy device mixers on the main thread. Serialize library initialization/shutdown.
- Individual asset/track/memory operations can run on application threads. Serialize compound
  changes and destruction with other users.
- No Idris callbacks on SDL audio threads. No managed buffer remains borrowed after a call.

## Limits and example

No streaming I/O input, groups, tags, spatial effects, callbacks, or advanced decoder configuration
in this subset.  Dependency sanitizer qualification: [testing limits](internals.md#tests).

[Ownership/playback example](../examples/mixer/Main.idr). It releases each caller-owned asset
reference after assigning it to a track. The tracks retain their inputs and stop on scoped cleanup.
[Build/run arguments](build.md#examples).

| Command + Enter | Action |
| --- | --- |
| `p`, `r`, `m`, `s` | Pause, resume, restart, stop music |
| `d` | One-second fade-out |
| `f`, `x` | Retrigger / stop independent sound |
| `q`, empty line, EOF | Exit |
