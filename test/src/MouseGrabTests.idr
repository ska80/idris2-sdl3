module MouseGrabTests

import SDL3
import SDL3.Scoped

%default covering

roundTrips : Window -> IO (Either String ())
roundTrips window = do
  let query = getWindowMouseGrab window
  let grab = setWindowMouseGrab window True
  let release = setWindowMouseGrab window False
  False <- query | True => pure (Left "Initial mouse grab was enabled")
  True <- grab | False => Left <$> getError
  True <- query | False => pure (Left "Mouse grab was not reported")
  True <- grab | False => Left <$> getError
  True <- query | False => pure (Left "Repeated mouse grab changed state")
  True <- release | False => Left <$> getError
  False <- query | True => pure (Left "Mouse grab release was not reported")
  True <- release | False => Left <$> getError
  True <- grab | False => Left <$> getError
  True <- query | False => pure (Left "Cached mouse grab request did not run again")
  True <- release | False => Left <$> getError
  False <- query | True => pure (Left "Cached release request did not run again")
  pure (Right ())

focusTransfer : Window -> Window -> IO (Either String Bool)
focusTransfer first other = do
  True <- setWindowMouseGrab first True | False => Left <$> getError
  True <- setWindowMouseGrab other True | False => Left <$> getError
  False <- getWindowMouseGrab other | True => pure (Left "Hidden window reported an active mouse grab")
  True <- isWindowHidden other | False => pure (Left "Mouse grab request showed a hidden window")
  True <- showWindow other | False => Left <$> getError
  True <- getWindowMouseGrab other | False => pure (Left "Showing the dummy window did not activate its mouse grab")
  False <- getWindowMouseGrab first | True => pure (Left "Window without focus retained an active mouse grab")
  saved <- getWindowMouseGrab other
  True <- setWindowMouseGrab other False | False => Left <$> getError
  True <- setWindowMouseGrab first False | False => Left <$> getError
  False <- getWindowMouseGrab other | True => pure (Left "Focused window did not release mouse grab")
  pure (Right saved)

retainedTarget : Window -> Renderer -> IO (Either String ())
retainedTarget window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    Right () <- roundTrips window | Left err => pure (Left err)
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Mouse grab changed target dimensions")
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())

export
mouseGrabTests : IO (Either String ())
mouseGrabTests = do
  copied <- withWindow "mouse grab" 37 23 neutral $ \window =>
    withWindow "pending grab" 16 16 (hidden <+> resizable <+> borderless) $ \other => do
      Right identifier <- getWindowID window | Left err => pure (Left err)
      Right () <- roundTrips window | Left err => pure (Left err)
      Right () <- withRenderer window (retainedTarget window) | Left err => pure (Left err)
      Right saved <- focusTransfer window other | Left err => pure (Left err)
      Right after <- getWindowID window | Left err => pure (Left err)
      title <- getWindowTitle window
      Right (MkSize 37 23) <- getWindowSize window | _ => pure (Left "Mouse grab changed window dimensions")
      if after == identifier && title == "mouse grab" then pure (Right saved)
         else pure (Left "Mouse grab changed window identity or title")
  Right True <- pure copied | _ => pure (Left "Copied mouse grab state changed after cleanup")
  pure (Right ())
