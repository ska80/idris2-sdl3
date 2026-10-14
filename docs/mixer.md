# SDL3_mixer

`SDL3.Mixer` provides reusable audio assets, independent tracks, looping, fades, and gain controls.
An asset holds audio data. A track plays one assigned input. Multiple tracks can share an asset and
play it at the same time. The mixer combines their output.

This extension uses a separate `sdl3-mixer` package. Core-only applications still depend only on
`sdl3` and do not load SDL3_mixer. See [core audio](audio.md) for PCM queues and WAV playback
without this extension.

## Build and use

Install SDL3_mixer 3.2.0 or newer development files, plus the [core build
requirements](../README.md#build-and-run).  From the repository root, run:

```sh
pkg-config --modversion sdl3-mixer
make mixer
make test-mixer
make example-mixer
```

For another project, add this entry alongside its existing `sdl3` entry in `pack.toml`:

```toml
[custom.all.sdl3-mixer]
type = "local"
path = "/path/to/idris2-sdl3"
ipkg = "sdl3-mixer.ipkg"
```

Add `sdl3-mixer` to the application package dependencies. Import `SDL3.Mixer` for the typed API and
`SDL3.Mixer.Scoped` for cleanup helpers. Import `SDL3` for `getError` and `AudioSpec`.  Build with
Chez. At runtime, include `cbits` and the installed SDL library directory in `LD_LIBRARY_PATH`. The
extension build creates `cbits/libidris2_sdl3_mixer.so`.

## Assets and output

`initMixer` initializes SDL3_mixer. Each successful call needs a matching `quitMixer` after resource
cleanup. `withMixerLibrary action` handles this pair on ordinary return. Initialization and final
shutdown are not thread-safe.

`createMixer` opens the default playback device and returns `Mixer DeviceOutput`. SDL_mixer
initializes SDL audio internally. It converts loaded audio to the device format. The mixer owns its
logical audio device, so `destroyMixer` closes that device without closing unrelated playback
devices.

`loadAudio mixer path mode` loads the whole file into native memory. `DecodeOnPlayback` stores the
encoded data and decodes it during playback. `Predecode` decodes it during loading and stores the
samples. Neither mode keeps a file open for incremental disk access. Paths use UTF-8 C strings, so
an embedded NUL ends the path.

A decoder converts a file format to audio samples. Supported formats depend on the installed
SDL3_mixer build. `getAudioDecoders` copies the available decoder names, not file extensions.
`loadAudio` returns a copied error if no decoder accepts the file. The binding does not promise that
MP3, Ogg, or any other optional format is available.

`getAudioDuration` returns `KnownFrames count`, `UnknownDuration`, or `InfiniteDuration`.  A sample
frame contains one sample for each channel. These frames use the asset format, not necessarily the
output format. The copied duration survives asset cleanup. Loaded assets can be shared across mixers
and can outlive the mixer used during loading.

## Playback and configuration

Create tracks once with `createTrack mixer`. Assign an asset with `setTrackAudio track (Just
asset)`.  Assignment to a stopped track does not start playback. Replacing input on a playing track
can leave its old position and loop configuration unsuitable. Call `playTrack` to restart with the
new configuration. `setTrackAudio track Nothing` removes input. The mixer marks a playing track as
stopped when it next processes that missing input.

`playTrack track Nothing` starts or restarts one play from the beginning, without a fade.  It also
restarts a paused track. `pauseTrack` holds its position, and `resumeTrack` continues it.  Separate
tracks have independent controls. For overlapping copies of a sound, reuse several
tracks. Restarting one track replaces its previous playback. There is no automatic track pool.

`newPlayOptions` creates reusable playback configuration. `playTrack track (Just options)` reads
that configuration during the call. The caller can then reuse or free it. Changes affect later play
calls, not current playback. These setters return `IO Bool`:

- `setPlayLoops`: `PlayOnce`, `Repeat n` for n additional plays, or `LoopForever`.
- `setPlayStartFrames`: The initial input position, with zero for the beginning.
- `setPlayLoopStartFrames`: The input position for later repeats, with zero for the beginning.
- `setPlayFadeInFrames`: The input frames for a fade from silence, with zero to disable the fade.

`Repeat 0` means one play. Repeat counts must not exceed 2147483647. Frame values must fit the
nonnegative signed 64-bit range. Invalid values fail without replacing that property.  Allocate and
configure these properties outside the update loop. The adapter does not allocate per-play
configuration. SDL_mixer and its decoders can allocate internally.

Positions and fades use the current input frame rate. `trackMSToFrames track milliseconds` converts
`Bits32` milliseconds after input assignment. Input changes can change this conversion.
`setTrackPlaybackPosition` seeks the input without starting playback. Some inputs cannot seek, and
some decoders only approximate a frame position. A later `playTrack` resets the initial position
from its configuration. SDL_mixer can accept a loop request but stop at the loop point if the input
cannot seek.

`stopTrack track fadeFrames` stops immediately when `fadeFrames` is zero. A positive value starts a
fade-out and does not wait for completion. Paused tracks cannot advance their fade until they
resume. `getTrackPlaybackPosition`, `trackPlaying`, and `trackPaused` report mixer state, not
audible completion. Samples already sent to a device can still play after a stop.

Gain multiplies sample amplitude. `setTrackGain` controls one track, and `setMixerGain` controls the
whole mix. Zero produces silence, and one leaves amplitude unchanged. Values above one can distort
the output. NaN means "not a number". The setters reject negative, infinite, NaN, and
out-of-float-range values.  `getTrackGain` excludes fades and master gain. Gain queries widen SDL
floats to `Double` without adding precision.

Creation functions and position queries return `Either String a`. If a control returns `False`, read
`getError` immediately on the same thread. State queries return state, not success.  Successful
playback does not prove that a physical device produces sound.

## Ownership and threads

Destroy tracks before their mixer. Release asset references and playback configuration before final
`quitMixer`. Call SDL `quit` last. `destroyMixer` also destroys any remaining child tracks, so do
not use or destroy those handles afterward. Final `quitMixer` destroys remaining mixer objects and
invalidates their handles. Prefer explicit cleanup instead of relying on that fallback.

`destroyAudio` releases the caller's reference. Tracks retain their own references after assignment,
so they can continue after this call. Do not use the caller's handle afterward, even if a track
still retains the underlying data. Copying an Idris handle does not acquire another reference.  An
asset does not require its loading mixer to remain alive.

`withMixer`, `withMemoryMixer`, `withAudio`, `withTrack`, and `withPlayOptions` own their supplied
handles. They clean up after ordinary `Right` and `Left` callback returns and preserve the result.
Failed acquisition skips the callback. Do not manually destroy or retain supplied handles.  Runtime
exceptions, process exit, and nonreturning callbacks do not guarantee cleanup.  Types distinguish
resources but do not enforce lifetimes or track-to-mixer identity.

Create and destroy device mixers on the main thread. SDL permits individual asset, track, and
memory-mixer operations from application threads. Serialize compound controls and configuration
changes on shared objects. Do not destroy resources during another call that uses them.  No callback
enters Idris from an SDL audio thread. No managed buffer remains borrowed after a call.

```idris
import SDL3
import SDL3.Mixer
import SDL3.Mixer.Scoped

loopForAWhile : String -> IO (Either String ())
loopForAWhile path = withMixerLibrary $ withMixer $ \mixer =>
  withAudio mixer path DecodeOnPlayback $ \asset =>
    withTrack mixer $ \track => withPlayOptions $ \options => do
      True <- setTrackAudio track (Just asset) | False => Left <$> getError
      True <- setTrackGain track 0.25 | False => Left <$> getError
      True <- setPlayLoops options LoopForever | False => Left <$> getError
      True <- playTrack track (Just options) | False => Left <$> getError
      -- A real application keeps these scopes around its update loop.
      delayNS 1000000000
      True <- stopTrack track 0 | False => Left <$> getError
      pure (Right ())
```

## Output to memory

`createMemoryMixer spec` returns `Mixer MemoryOutput`. It opens no device and advances only through
`generateMixer mixer buffer offset count`. `AudioSpec` accepts the eight [core
formats](audio.md#streams-and-formats), 1 through 8 channels, and a positive frame rate. The output
format remains fixed.  Device mixers cannot be passed to `generateMixer` through the typed API.

Offset and count are `Bits32` bytes. Both must align to complete output frames. The range must fit
the actual buffer capacity, and count must not exceed 2147483647. On success, SDL initializes the
whole requested range. `Right bytes` excludes appended silence, so it can be smaller than count,
including zero. The buffer can contain valid silence beyond that returned count.

Allocate the output buffer once and reuse it. Do not read or modify it during generation.  The
adapter creates no temporary native heap buffer. SDL_mixer can allocate, decode, and convert
internally. No performance or exact audible-timing measurements exist.

## Example and tests

After `make example-mixer`, run from the repository root:

```sh
LD_LIBRARY_PATH="$PWD/cbits:/usr/local/lib:${LD_LIBRARY_PATH:-}" \
  examples/build/exec/sdl3-mixer-example music-file sound-file
```

The example loops music and uses a separate sound track. Enter `p` to pause music, `r` to resume,
`m` to restart, `s` to stop, or `d` to fade it out over one second. Enter `f` to retrigger the sound
or `x` to stop it. Each command needs Enter. Enter `q`, an empty line, or end of input to exit.

`make test-mixer` runs native, Idris, and compile-time tests with dummy audio. Memory-mixer tests
inspect generated samples, loops, fades, gain, input references, and guarded output ranges.  Device
tests cover independent tracks and owned-device cleanup without audible output.  Real devices,
compressed-format quality, latency, and device changes need manual testing.  See [native testing
limits](internals.md#tests) for the installed decoder dependency's leak report.

This initial subset does not bind streaming I/O input, groups, tags, spatial effects, callbacks, or
advanced decoder configuration. It does not expose raw pointers from core I/O or playback handles.
Future input loaders must state whether they borrow, retain, or consume each source.
