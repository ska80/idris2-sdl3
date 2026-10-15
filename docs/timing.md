# Timing and display synchronization

Clock/delay calls: any thread. Renderer calls: main thread. Units do not guarantee timing precision.

## Clocks and delays

| API | Type / unit | Contract |
| --- | --- | --- |
| `ticks` | `IO Bits64`, milliseconds | Elapsed since SDL initialization, not calendar time |
| `ticksNS` | `IO Bits64`, nanoseconds | Same units/origin as event timestamps |
| `performanceCounter` | `IO Bits64`, counter units | Only differences are meaningful |
| `performanceFrequency` | `IO Bits64`, units/second | Subtract counters before converting to `Double`, then divide by this frequency |
| `delay` | `Bits32` milliseconds | Wait at least the requested interval |
| `delayNS` | `Bits64` nanoseconds | Wait at least the requested interval |
| `delayPrecise` | `Bits64` nanoseconds | Can keep the CPU active while waiting |

- Do not compare performance counters directly with ticks/event timestamps.
- Scheduling can make delays return late. Main-thread delays block event handling and drawing.
- Before subtracting an elapsed time from an unsigned frame budget, test that elapsed time is
  smaller.

## VSync

VSync synchronizes presentation with display refreshes.  `setRenderVSync renderer mode` requests a
mode. `getRenderVSync` returns `Either String VSyncMode`.

| Mode | Meaning |
| --- | --- |
| `VSyncDisabled` | Default for new renderers |
| `VSyncInterval n` | Every `n` refreshes (1..2147483647) |
| `VSyncAdaptive` | Late frames need not wait for the next refresh. Tearing remains possible |

- Zero/oversized intervals fail before changing state. Use `VSyncDisabled`, not interval zero.
- Support depends on the driver. A reported mode does not prove physical synchronization.
- State belongs to the renderer, not a texture target. Include time spent in `present` when
  measuring a full frame.

Examples: [Basic](../examples/basic/Main.idr) waits for events instead of redrawing unchanged
content. [Media](../examples/media/Main.idr) uses timed event waits for its once-per-second text
update. [Locking](../examples/locking/Main.idr) requests VSync and uses timer pacing if the request
fails. Its animation follows elapsed time, not the number of presented frames.

Measurements: [batch CPU timing](geometry.md#cpu-timing-example). Build/run:
[examples](build.md#examples).
