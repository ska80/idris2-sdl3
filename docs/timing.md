# Timing and display synchronization

Import `SDL3` for clocks, delays, and renderer synchronization.  Clock and delay functions can run
on any thread. Renderer synchronization requires the main thread and a live renderer. Time units do
not guarantee clock or scheduling precision.

## Clocks and delays

`ticks` returns `IO Bits64` milliseconds since SDL initialization.  `ticksNS` returns nanoseconds,
matching event timestamps. These are elapsed times, not calendar timestamps. A nanosecond is one
billionth of a second.

`performanceCounter` returns a high-resolution counter. `performanceFrequency` returns its
increments per second. Only differences between counter samples are meaningful.  Subtract before
converting to `Double`, then divide by the frequency to obtain seconds.  Do not compare counter
values directly with ticks or event timestamps.

`delay` takes `Bits32` milliseconds. `delayNS` takes `Bits64` nanoseconds.  Both wait at least the
requested interval. `delayPrecise` also takes nanoseconds and can keep the CPU active while
waiting. All delays can return late because of operating-system scheduling. Long delays on the main
thread stop event processing and drawing.

## Frame pacing

Frame pacing controls the time between rendered frames. Measure event handling and drawing, then
wait only for the unused frame budget. If work exceeds the budget, skip the delay.  Unsigned
subtraction without that condition can wrap to a very long delay:

```idris
import SDL3

finishFrame : Bits64 -> IO ()
finishFrame started = do
  ended <- ticksNS
  let elapsed = ended - started
  if elapsed < 16666667
    then delayNS (16666667 - elapsed)
    else pure ()
```

Take `started <- ticksNS` before frame work and call `finishFrame started` afterward.  This targets
roughly 60 frames per second without promising that rate.  It does not synchronize frames with the
display.

## VSync

VSync synchronizes presentation with display refreshes.  `setRenderVSync renderer mode` selects a
mode and returns `Bool`.  Supported values depend on the driver:

- `VSyncDisabled`: Disable synchronization, the default for new renderers.
- `VSyncInterval n`: Present every `n` refreshes, from 1 through 2147483647.
- `VSyncAdaptive`: Allow late frames without waiting for the next refresh.

Adaptive mode can show parts of different frames during one refresh.  Use `VSyncDisabled`, not
`VSyncInterval 0`. The binding rejects zero and oversized intervals before changing the
renderer. Read `getError` immediately after a failed setting.

`getRenderVSync` returns `Either String VSyncMode` for the configured mode.  The state belongs to
the renderer, not a texture target. Large intervals can make `present` wait a long time. Include
that time in frame measurements before adding a delay.

## Examples and tests

[Hello](../examples/Hello.idr) and [Locking](../examples/Locking.idr) use timer-based pacing.  `make
test` covers clock units, progress, interval bounds, queries, and supported or rejected modes.  It
does not measure timing accuracy, physical synchronization, or visible frame tearing.  Those require
measurements on the target system.
