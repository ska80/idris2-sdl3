# Bouncing balls

Run from the repository root:

```sh
make -C examples/balls run
```

The example needs core SDL3, SDL3_ttf, and SDL3_mixer with a Vorbis decoder.  [Build
requirements](../../docs/build.md#requirements). The font and audio files are included.  Direct
executable runs need the example directory as their working directory.

| Key | Action |
| --- | --- |
| `n` | Add ten balls with random sizes, colors, directions, speeds, and opacity |
| `c` | Remove all balls |
| `q`, Escape, window close | Quit |

Key repeat is ignored. The scene starts empty. Balls bounce off the four scene edges, not each
other. Resize the window to scale the 800×600 scene. Letterboxing preserves its proportions.  The
top labels show measured FPS and ball count. The bottom label shows the controls.

## Rendering and timing

All balls share one shaded circle texture, initialized through a scoped RGBA lock. Each draw changes
its color, alpha, and destination size. Translucent balls blend in list order. The two text panels
share a reusable rectangle buffer. Three TTF text objects stay alive throughout the loop.  The FPS
string updates at most twice per second. The count string and its right-aligned position update only
when the count changes.

A nanosecond timer caps the loop at 60 FPS, including input, audio commands, drawing, and
presentation.  VSync is disabled when supported. Scheduler delays and slow rendering can lower the
frame rate.  Motion follows elapsed time, capped at 100 ms per update after stalls. Missed time is
discarded rather than replayed. The example does not impose a ball-count limit. More balls require
more CPU, rendering work, and Idris memory.

## Audio and ownership

The music loops on its own Mixer track. Sixteen reusable tracks share the predecoded bounce sound.
Each wall hit starts the next track. If all tracks are busy, the next hit restarts the oldest voice.
A corner hit triggers two sounds. Clearing balls does not stop the music or already submitted
sounds.  Both audio files are loaded and decoded once. No track or texture is created per ball or
wall hit.  SDL and Idris can still allocate internally.

All application work runs on the main thread. Resource scopes release text before its font and
engine, textures before the renderer, and tracks before the mixer. SDL quits last. Renderer resets
stop the example with a restart message. See the shared [resource
contract](../../docs/resources.md).

## Assets and tests

[Asset sources, licenses, and regeneration](assets/README.md).

```sh
make -C examples/balls test
```

The tests cover random bounds, add/clear commands, four-wall and corner reflection, elapsed-time
motion, frame budgets, key repeat, window routing, and reset handling. A two-second dummy-driver
smoke run adds twenty balls, plays wall sounds, resizes twice, and clears the scene. Its seed is
fixed.  Run that script on a real display with `make -C examples/balls run ARGS="--smoke"`.

Dummy-driver tests do not establish physical sound quality, display timing, or accelerated reset
recovery. Audio generation needs Python 3 and FFmpeg with `libvorbis`. Normal builds do not need
them.
