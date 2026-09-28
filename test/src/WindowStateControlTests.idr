module WindowStateControlTests

import SDL3
import SDL3.Scoped

%default covering

rejected : List (IO Bool) -> IO (Either String ())
rejected [] = pure (Right ())
rejected (request :: rest) = do
  False <- request | True => pure (Left "Dummy driver unexpectedly accepted a window state request")
  err <- getError
  if err == "" then pure (Left "Rejected window state request did not report an SDL error")
     else rejected rest

normal : Window -> IO (Either String ())
normal window = do
  False <- isWindowMinimized window | True => pure (Left "Dummy window was reported as minimized")
  False <- isWindowMaximized window | True => pure (Left "Dummy window was reported as maximized")
  pure (Right ())

requests : Window -> Window -> IO (Either String (Bool, Bool))
requests window other = do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  title <- getWindowTitle window
  let minimize = minimizeWindow window
  let maximize = maximizeWindow window
  let restore = restoreWindow window
  let minimized = isWindowMinimized window
  let maximized = isWindowMaximized window
  False <- minimized | True => pure (Left "Initial minimized flag was set")
  False <- maximized | True => pure (Left "Initial maximized flag was set")
  Right () <- rejected [minimize, maximize, restore, minimize, maximize, restore] | Left err => pure (Left err)
  Right () <- normal other | Left err => pure (Left err)
  True <- isWindowHidden other | False => pure (Left "Requests on another window changed hidden state")
  Right after <- getWindowID window | Left err => pure (Left err)
  afterTitle <- getWindowTitle window
  Right (MkSize 37 23) <- getWindowSize window | _ => pure (Left "Rejected requests changed window dimensions")
  if after /= identifier || afterTitle /= title then pure (Left "Rejected requests changed window identity or title") else do
    small <- minimized
    large <- maximized
    pure (Right (small, large))

retainedTarget : Window -> Renderer -> IO (Either String ())
retainedTarget window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    Right () <- rejected [minimizeWindow window, maximizeWindow window, restoreWindow window] | Left err => pure (Left err)
    Right () <- normal window | Left err => pure (Left err)
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Rejected requests changed target dimensions")
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())

export
windowStateControlTests : IO (Either String ())
windowStateControlTests = do
  copied <- withWindow "state controls" 37 23 resizable $ \window =>
    withWindow "other state controls" 16 16 (hidden <+> resizable <+> borderless) $ \other => do
      Right states <- requests window other | Left err => pure (Left err)
      Right () <- withRenderer window (retainedTarget window) | Left err => pure (Left err)
      pure (Right states)
  Right (False, False) <- pure copied | _ => pure (Left "Copied state flags changed after cleanup")
  Right () <- withWindow "fixed size" 37 23 hidden (\window =>
    rejected [maximizeWindow window, minimizeWindow window, restoreWindow window]) | Left err => pure (Left err)
  withWindow "fullscreen state flags" 16 16 (hidden <+> fullscreen) $ \window => do
    True <- isWindowFullscreen window | False => pure (Left "Fullscreen creation flag was missing")
    normal window
