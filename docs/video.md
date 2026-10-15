# Windows and display sizes

Initialize `video`. Main thread only. [Shared resource/error rules](resources.md).

## Window operations

| API | Result or constraint |
| --- | --- |
| `createWindow title width height flags` | Owned `Window`. Positive C-int dimensions in window coordinates |
| `getWindowID` | Copied ID for matching events, not ownership |
| `getWindowTitle`, `setWindowTitle` | Copied title / replacement. Empty title is valid |
| `setWindowSize window (MkSize w h)` | Positive `Size WindowUnits`. Ignored in fullscreen/maximized state |
| `syncWindow` | Wait for pending window-state requests. Can block or time out. Not GPU synchronization |
| `setWindowFullscreen`, `isWindowFullscreen` | Desktop fullscreen unless external code selects an exclusive mode |
| `showWindow`, `hideWindow`, `isWindowHidden` | Visibility only. Not-hidden does not imply visible or unobscured |
| `raiseWindow`, `hasKeyboardFocus` | One-time raise/focus request / current focus flag |
| `minimizeWindow`, `maximizeWindow`, `restoreWindow` | Maximize requires resizing enabled. Minimize/restore have no direct fullscreen effect |
| `isWindowMinimized`, `isWindowMaximized` | Current SDL flags |
| `setWindowBordered`, `isWindowBordered` | Cannot change style in fullscreen |
| `setWindowResizable`, `isWindowResizable` | Disabling user resizing does not prevent programmatic resizing |
| `setWindowAlwaysOnTop`, `isWindowAlwaysOnTop` | Persistent placement request, unlike one-time raising |
| `flashWindow` | `FlashBriefly`, `FlashUntilFocused`, `CancelFlash`. No raise or completion wait |
| `setWindowOpacity`, `getWindowOpacity` | Whole-window alpha, separate from texture alpha |

- Combine window flags with `<+>`: `resizable`, `hidden`, `borderless`, `fullscreen`, `alwaysOnTop`,
  `highPixelDensity`. `neutral` for none.
- Successful requests can be delayed, adjusted, or denied by the window system. Process events and
  query resulting state.
- Show a hidden window separately before raising it. Success does not guarantee keyboard focus.
- Opacity clamps to 0..1, including infinities, and rejects NaN. A getter can return 1.0 when
  setting is unsupported.
- Flash appearance/duration depend on the window system. Unsupported backends can reject
  cancellation too.
- Mouse confinement and release rules: [mouse grab](input.md#mouse-grab).

## Sizes and display scale

| Query | Meaning |
| --- | --- |
| `getWindowSize` | `Size WindowUnits` |
| `getWindowSizeInPixels` | `Size PixelUnits`. Independent of render targets and draw scale |
| `getWindowPixelDensity` | Backing pixels per window unit |
| `getWindowDisplayScale` | Expected content size in pixels, including display content scale |

- Size fields are signed `Int32`. Defer size-dependent drawing when either is non-positive.
- Window and pixel sizes can differ. Unit types do not identify a particular window.
- Query density/scale again after monitor moves or scale events. Density and display scale are not
  interchangeable.
- Do not apply scaling twice when logical presentation already handles it. Mouse events still use
  window coordinates.
- Notifications and their payloads: [window events](input.md#window-notifications). They describe
  past changes, without guaranteed ordering.

## Example

[Hello](../examples/Hello.idr): resizable window, logical resolution, input conversion.
[Build and run commands](build.md#examples).
