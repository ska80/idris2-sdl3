module FlashTests

import SDL3
import SDL3.Scoped

%default covering

rejected : List (IO Bool) -> IO (Either String ())
rejected [] = pure (Right ())
rejected (request :: rest) = do
  False <- request | True => pure (Left "Dummy driver unexpectedly accepted a flash request")
  err <- getError
  if err == "" then pure (Left "Rejected flash request did not report an SDL error")
     else rejected rest

requests : Window -> IO (Either String ())
requests window = do
  let brief = flashWindow window FlashBriefly
  let focused = flashWindow window FlashUntilFocused
  let cancel = flashWindow window CancelFlash
  rejected [brief, cancel, focused, cancel, brief, focused, cancel]

retainedTarget : Window -> Renderer -> IO (Either String ())
retainedTarget window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    Right () <- requests window | Left err => pure (Left err)
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Flash requests changed target dimensions")
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())

export
flashTests : IO (Either String ())
flashTests = withWindow "flash tests" 37 23 neutral $ \window =>
  withWindow "hidden flash tests" 16 16 (hidden <+> alwaysOnTop) $ \other => do
    Right identifier <- getWindowID window | Left err => pure (Left err)
    True <- hasKeyboardFocus window | False => pure (Left "Dummy shown window did not start with focus")
    Right () <- requests window | Left err => pure (Left err)
    Right () <- requests other | Left err => pure (Left err)
    True <- hasKeyboardFocus window | False => pure (Left "Rejected flash requests removed focus")
    False <- hasKeyboardFocus other | True => pure (Left "Rejected flash requests gave a hidden window focus")
    True <- isWindowHidden other | False => pure (Left "Rejected flash requests showed a hidden window")
    True <- isWindowAlwaysOnTop other | False => pure (Left "Rejected flash requests changed the stacking flag")
    Right () <- withRenderer window (retainedTarget window) | Left err => pure (Left err)
    Right after <- getWindowID window | Left err => pure (Left err)
    title <- getWindowTitle window
    Right (MkSize 37 23) <- getWindowSize window | _ => pure (Left "Flash requests changed window dimensions")
    if after == identifier && title == "flash tests" then pure (Right ())
       else pure (Left "Flash requests changed window identity or title")
