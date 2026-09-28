# Windows and display sizing

Import `SDL3` and initialize `video`. Import `SDL3.Scoped` for `withWindow` and `withRenderer`. Use
all window functions on the main thread with a live window.  Window-system support and policy
determine which requests take effect.

## Creating a window

`createWindow title width height flags` returns an owned `Window` in `Either`.  Use positive
dimensions in window coordinates. Combine `WindowFlags` with `<+>`.  Available flags include
`resizable`, `hidden`, `borderless`, `fullscreen`, `alwaysOnTop`, and `highPixelDensity`. Use
`neutral` for no flags.

`getWindowID window` returns an identifier for matching events to that window.  The identifier is
not an owned handle. Events can describe windows that you already closed, so match them against the
live windows in your application.

`getWindowTitle` returns a copied string. `setWindowTitle window title` replaces the title, and
empty text clears it. Titles are UTF-8 C strings, so embedded NUL characters end the text. An empty
title is valid, not an error marker.

## Sizes and display scale

`getWindowSize window` returns `Either String (Size WindowUnits)`.  `getWindowSizeInPixels window`
returns `Either String (Size PixelUnits)`.  Both copy signed 32-bit width and height fields. The
sizes can differ on high-density displays. Defer size-dependent drawing when either dimension is
non-positive.

Window sizes do not depend on the selected render target or drawing scale.  The result survives
window destruction but does not track later resizing.  The unit type distinguishes pixels from
window coordinates, not one window from another.

`getWindowPixelDensity` returns the ratio of backing pixels to window coordinates.  For example, a
1920 by 1080 window with a 3840 by 2160 pixel buffer has density 2.0.  `getWindowDisplayScale`
describes the expected content size in pixels and includes the display's content scale. Both return
`IO (Either String Double)`, but the values are not interchangeable.

Query scale again after display-scale notifications or monitor moves.  Do not apply scaling twice if
logical presentation already handles your layout.  Mouse events still use window coordinates. See
[coordinate conversion](rendering.md#coordinate-conversion).

## Resizing and fullscreen

`setWindowSize window (MkSize width height)` requests positive `Size WindowUnits` dimensions. It
does not take pixel dimensions. SDL ignores size requests for fullscreen or maximized windows. A
successful request can be delayed, adjusted, or denied.  Query the resulting dimensions or handle
resize events before reallocating resources.

`syncWindow window` waits for pending window-state changes. It can block or fail on timeout. It does
not wait for GPU work or guarantee the requested size.  Use it when you need to wait before
querying, not on every frame:

```idris
import SDL3

resizeAndRead : Window -> Size WindowUnits -> IO (Either String (Size WindowUnits))
resizeAndRead window dimensions = do
  True <- setWindowSize window dimensions | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  getWindowSize window
```

`setWindowFullscreen window enabled` requests fullscreen or windowed mode.  SDL uses borderless
desktop fullscreen unless external code selects an exclusive display mode.  `isWindowFullscreen`
reports SDL's current flag. It does not distinguish fullscreen modes or prove visibility. Query size
and scale separately after a transition.

## Visibility, focus, and state

`showWindow` and `hideWindow` change visibility without destroying rendering resources.
`isWindowHidden` reports SDL's hidden flag. A window that is not hidden can still be minimized or
covered. Creating with `hidden` lets you prepare resources before showing it.

`raiseWindow` requests a one-time raise and keyboard focus. Use `showWindow` separately for a hidden
window. `hasKeyboardFocus` reports SDL's current keyboard-focus flag.  Successful raising does not
guarantee focus or placement above other windows.

`minimizeWindow`, `maximizeWindow`, and `restoreWindow` request window-state changes.  Maximization
requires a resizable window and differs from fullscreen.  Minimize and restore requests have no
direct effect in fullscreen, but can affect later windowed state. `isWindowMinimized` and
`isWindowMaximized` report current SDL flags.

State-query booleans describe state, not success. Process events normally to keep SDL's reported
state current. A successful control request does not prove that the window system applied it. After
a control returns `False`, read `getError` immediately.

## Style and attention controls

`setWindowBordered` and `setWindowResizable` take boolean requests.  Their queries are
`isWindowBordered` and `isWindowResizable`.  These styles cannot change in fullscreen. Disabling
user resizing does not prevent programmatic `setWindowSize` requests.

`setWindowAlwaysOnTop window enabled` requests persistent placement above other windows.
`isWindowAlwaysOnTop` reports SDL's flag, not guaranteed desktop placement.  The creation flag is
`alwaysOnTop`. This differs from the one-time `raiseWindow` request.

`flashWindow window operation` requests attention through `FlashBriefly`, `FlashUntilFocused`, or
`CancelFlash`. The window system determines its appearance and duration. It does not raise the
window or wait for completion.  Unsupported backends can reject every operation, including
cancellation.

`setWindowOpacity window value` controls whole-window transparency.  Zero is transparent and one is
opaque. Values outside that range are clamped, including infinities. NaN, meaning "not a number", is
rejected. This is separate from texture alpha.  `getWindowOpacity` returns `Either String Double`
and can report 1.0 even when the setter is unsupported.

Mouse confinement uses `setWindowMouseGrab` and `getWindowMouseGrab`.  See [mouse
grab](input.md#mouse-grab) for release and focus rules.  Opacity, visibility, focus, and mouse
confinement are separate controls.

## Events, ownership, and threading

Window notifications cover close requests, movement, sizes, scale, focus, visibility, minimization,
maximization, restoration, exposure, and fullscreen transitions.  [Input and
events](input.md#window-notifications) describes their payloads.  Notifications describe past
changes, not guaranteed current state or a fixed event order.

Destroy textures before their renderer, then destroy the window.  `withWindow` and `withRenderer`
perform cleanup after ordinary callback returns.  Do not retain their handles or destroy them inside
the callback.  See [resource ownership](resources.md) for scope limits and initialization cleanup.

## Example and tests

Run `make run-hello` from the repository root for a resizable window with texture drawing and mouse
input. Close the window, press Escape, or click the blue rectangle to exit.  The example converts
clicks to drawing coordinates after resizing.

`make test` uses SDL's dummy video driver. Tests cover queries, copied values, controls, event
decoding, and rendering-resource reuse. Real window-manager behavior, display scaling, focus policy,
and physical cursor confinement need manual testing. The dummy driver rejects some requests and
accepts others without changing state.
