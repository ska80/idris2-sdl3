# Resource contract

Applies to core and all extensions. Typed APIs use opaque handles. Raw/internal APIs bypass these
guarantees.

## Initialization and errors

- Initialize SDL on the main thread: `init (video <+> audio <+> gamepad)`. Select only needed
  flags. `neutral` selects none.
- Call `quit` last, after resource cleanup, including after failed initialization.
- Creation/query `Left err`: copied error. Control `False`: read `getError` immediately on the same
  thread, before cleanup.
- Boolean state queries report state, not success. Another SDL call can replace the current error.
- Strings and paths use UTF-8 C strings. Embedded NUL ends the value.
- SDL `float` values widen to `Double` without gaining precision. Drawing values narrow back to
  floats.

## Manual ownership

| Resource | Release | Required order or special rule |
| --- | --- | --- |
| `Window` | `destroyWindow` | After its renderers |
| `Renderer` | `destroyRenderer` | After its textures and text engines |
| `Texture access` | `destroyTexture` | After unlocking and switching away from it as a render target |
| `Surface` | `destroySurface` | A texture copied from it can outlive it |
| `PlaybackStream` | `destroyPlaybackStream` | Also closes its owned logical audio device |
| `WAV` | `freeWAV` | Queued copies survive cleanup |
| `Gamepad` | `closeGamepad` | Once per successful open, including after removal |
| `Cursor` | `destroyCursor` | Select another cursor first |
| `IOStream` | `closeIO` | Invalid even if close fails. Never retry close |
| Reusable buffer/snapshot | Matching `free...` | No users or borrowed views after release |
| Image result | Core surface/texture release | Same core handle types |
| TTF text/font/engine | Matching `destroy...` / `closeFont` | [TTF resource order](ttf.md#resources) |
| Mixer track/asset/options/output | Matching `destroy...` / `freePlayOptions` | [Mixer reference ownership](mixer.md#ownership-and-threads) |

- Release each owned reference exactly once. Copying a handle does not acquire another reference.
- Types do not prevent stale access, duplicate cleanup, thread mistakes, or renderer/mixer identity
  errors.
- Copied strings, events, IDs, sizes, and query records survive source cleanup. They are snapshots,
  not live state or ownership.

## Scoped resources

A scope acquires a resource, calls an action, then releases the resource.

- Import the corresponding `.Scoped` module. Resource helpers follow the `with...` naming
  convention.
- Failed acquisition skips the action and cleanup.
- Ordinary `Right` and `Left` returns both trigger cleanup. Exceptions, process exit, and
  nonreturning actions do not guarantee cleanup.
- Do not release supplied handles yourself or retain handles/actions that use them beyond the scope.
- Nest dependent resources inside their owners. Allocate reusable buffers around the loop, not
  within each frame/event.
- Callback errors precede cleanup errors. After a successful callback, failed close/unlock returns
  its cleanup error.

`withTargetTexture` owns a texture without selecting it. Nest `withRenderTarget` inside it.
`withSystemCursor` owns a cursor without selecting it or restoring the previous selection.

## Temporary state

- `withRenderTarget` is in `SDL3`. Other state helpers are in `SDL3.Scoped`.
- State scopes borrow live resources and restore only their named state. Nested scopes save their
  own entry state.
- Failed query: skip the action. Failed setting: skip the action but still attempt restoration.
- Setting/action errors precede restoration errors. If only restoration fails, return its error.
- `Left` does not guarantee restoration. The ordinary-return limit above applies to restoration too.
- Keep the same target selected throughout viewport, clip, and scale scopes. Restore target changes
  in an inner scope.
- `withTextureLockRGBA` submits writes on unlock, including after `Left`. It does not restore pixels
  or undo writes.

## Threads and unsafe access

- Main thread: initialization, windows, rendering, events, keyboard/mouse queries, cursors,
  clipboard, and this TTF subset.
- Timing calls: any thread. Other thread rules: [audio](audio.md), [gamepads](gamepads.md),
  [I/O](io.md), [Image](image.md), [Mixer](mixer.md).
- Serialize access to shared resources and their cleanup. Never mutate or free native storage during
  a call that uses it.
- `SDL3.Raw` and extension `.Raw` modules require callers to enforce pointer validity, bounds,
  alignment, and lifetime.
- `SDL3.Internal.*` modules are implementation details, not application APIs. `Internal.Handles`
  permits pointer access and handle forging.
