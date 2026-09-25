module SDL3

import public SDL3.Flags
import SDL3.Raw

%default total

||| Owned window. Destroy after its renderer, before quit.
export
data Window = MkWindow AnyPtr

||| Owned renderer. Its window must remain alive.
export
data Renderer = MkRenderer AnyPtr

||| Reusable native event storage. Free exactly once.
export
data EventBuffer = MkEventBuffer AnyPtr

public export
data EventType = QuitRequested | WindowCloseRequested | KeyDown | KeyUp
               | OtherEvent Bits32

||| Copy the current thread's SDL error. Read only after a failed call.
export
getError : IO String
getError = primIO prim__getError

||| Initialize on the main thread. Video also enables events.
export
init : InitFlags -> IO Bool
init flags = (/= 0) <$> primIO (prim__init (initBits flags))

||| Destroy all owned resources before this call.
export
quit : IO ()
quit = primIO prim__quit

owned : (AnyPtr -> a) -> PrimIO AnyPtr -> IO (Either String a)
owned wrap action = do
  ptr <- primIO action
  null <- primIO (prim__isNull ptr)
  if null /= 0 then Left <$> getError else pure (Right (wrap ptr))

||| Width and height must be positive C int values. Call on the main thread.
export
createWindow : String -> Int -> Int -> WindowFlags -> IO (Either String Window)
createWindow title width height flags =
  if width <= 0 || height <= 0 || width > 2147483647 || height > 2147483647
     then pure (Left "Window dimensions must be positive 32-bit integers")
     else owned MkWindow (prim__createWindow title width height (windowBits flags))

||| Do not use the window after this call. Destroy its renderer first.
export
destroyWindow : Window -> IO ()
destroyWindow (MkWindow ptr) = primIO (prim__destroyWindow ptr)

||| Select SDL's default renderer. Call on the main thread.
export
createRenderer : Window -> IO (Either String Renderer)
createRenderer (MkWindow ptr) = owned MkRenderer (prim__createRenderer ptr)

export
destroyRenderer : Renderer -> IO ()
destroyRenderer (MkRenderer ptr) = primIO (prim__destroyRenderer ptr)

||| Rendering calls return False on failure. Call getError for details.
export
setDrawColor : Renderer -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO Bool
setDrawColor (MkRenderer ptr) r g b a =
  (/= 0) <$> primIO (prim__drawColor ptr r g b a)

export
clear : Renderer -> IO Bool
clear (MkRenderer ptr) = (/= 0) <$> primIO (prim__clear ptr)

export
present : Renderer -> IO Bool
present (MkRenderer ptr) = (/= 0) <$> primIO (prim__present ptr)

||| Coordinates convert to SDL's single-precision floats in the C adapter.
export
fillRect : Renderer -> Double -> Double -> Double -> Double -> IO Bool
fillRect (MkRenderer ptr) x y w h = (/= 0) <$> primIO (prim__fillRect ptr x y w h)

export
newEventBuffer : IO (Either String EventBuffer)
newEventBuffer = owned MkEventBuffer prim__eventNew

export
freeEventBuffer : EventBuffer -> IO ()
freeEventBuffer (MkEventBuffer ptr) = primIO (prim__eventFree ptr)

||| Poll on the main thread. Nothing means the queue is empty.
||| This initial API exposes event types, not event payloads.
export
pollEvent : EventBuffer -> IO (Maybe EventType)
pollEvent (MkEventBuffer ptr) = do
  ready <- primIO (prim__poll ptr)
  if ready == 0 then pure Nothing else do
    kind <- primIO (prim__eventKind ptr)
    event <- case kind of
      1 => pure QuitRequested
      2 => pure WindowCloseRequested
      3 => pure KeyDown
      4 => pure KeyUp
      _ => OtherEvent <$> primIO (prim__eventType ptr)
    pure (Just event)

||| Milliseconds since SDL initialization.
export
ticks : IO Bits64
ticks = primIO prim__ticks

export
delay : Bits32 -> IO ()
delay ms = primIO (prim__delay ms)
