module WindowFocusTests

import SDL3
import SDL3.Scoped

%default covering

focusChanges : Window -> Window -> IO (Either String ())
focusChanges first other = do
  let queryFirst = hasKeyboardFocus first
  let queryOther = hasKeyboardFocus other
  let raiseFirst = raiseWindow first
  True <- queryFirst | False => pure (Left "Dummy shown window did not have keyboard focus")
  False <- queryOther | True => pure (Left "Hidden window had keyboard focus")
  True <- raiseWindow other | False => Left <$> getError
  True <- isWindowHidden other | False => pure (Left "Raising a hidden window showed it")
  True <- showWindow other | False => Left <$> getError
  False <- queryFirst | True => pure (Left "Cached focus query retained the old focus")
  True <- queryOther | False => pure (Left "Showing the other dummy window did not transfer focus")
  -- Raising succeeds without changing focus on the dummy driver.
  True <- raiseFirst | False => Left <$> getError
  True <- raiseFirst | False => Left <$> getError
  False <- queryFirst | True => pure (Left "Dummy raising unexpectedly changed focus")
  True <- queryOther | False => pure (Left "Dummy raising removed focus from the other window")
  True <- hideWindow first | False => Left <$> getError
  True <- showWindow first | False => Left <$> getError
  True <- queryFirst | False => pure (Left "Showing the first dummy window did not restore focus")
  False <- queryOther | True => pure (Left "Cached focus query retained focus on the other window")
  pure (Right ())

retainedRenderer : Window -> Renderer -> IO (Either String ())
retainedRenderer window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    True <- raiseWindow window | False => Left <$> getError
    True <- hasKeyboardFocus window | False => pure (Left "Raising the focused dummy window removed focus")
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Raising the window changed its texture dimensions")
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())

export
windowFocusTests : IO (Either String ())
windowFocusTests = do
  copied <- withWindow "focus tests" 37 23 neutral $ \first =>
    withWindow "hidden focus tests" 16 16 (hidden <+> resizable <+> borderless) $ \other => do
      Right identifier <- getWindowID first | Left err => pure (Left err)
      Right () <- focusChanges first other | Left err => pure (Left err)
      Right () <- withRenderer first (retainedRenderer first) | Left err => pure (Left err)
      Right after <- getWindowID first | Left err => pure (Left err)
      title <- getWindowTitle first
      Right (MkSize 37 23) <- getWindowSize first | _ => pure (Left "Raising changed window dimensions")
      focused <- hasKeyboardFocus first
      unfocused <- hasKeyboardFocus other
      if after == identifier && title == "focus tests" then pure (Right (focused, unfocused))
         else pure (Left "Raising changed window identity or title")
  Right (True, False) <- pure copied | _ => pure (Left "Copied focus states changed after window cleanup")
  pure (Right ())
