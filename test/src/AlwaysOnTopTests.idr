module AlwaysOnTopTests

import SDL3
import SDL3.Scoped

%default covering

expect : IO Bool -> Bool -> IO (Either String ())
expect query expected = do
  actual <- query
  if actual == expected then pure (Right ()) else pure (Left "Always-on-top query did not match the dummy driver's flag")

requests : Window -> Bool -> Window -> Bool -> IO (Either String ())
requests window initial other otherInitial = do
  let query = isWindowAlwaysOnTop window
  let enable = setWindowAlwaysOnTop window True
  let disable = setWindowAlwaysOnTop window False
  Right () <- expect query initial | Left err => pure (Left err)
  True <- enable | False => Left <$> getError
  True <- enable | False => Left <$> getError
  Right () <- expect query initial | Left err => pure (Left err)
  True <- disable | False => Left <$> getError
  True <- disable | False => Left <$> getError
  -- The dummy driver keeps the creation-time flag despite accepting requests.
  Right () <- expect query initial | Left err => pure (Left err)
  True <- enable | False => Left <$> getError
  Right () <- expect query initial | Left err => pure (Left err)
  Right () <- expect (isWindowAlwaysOnTop other) otherInitial | Left err => pure (Left err)
  True <- isWindowHidden window | False => pure (Left "Always-on-top requests showed a hidden window")
  pure (Right ())

retainedTarget : Window -> Renderer -> IO (Either String ())
retainedTarget window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    True <- setWindowAlwaysOnTop window True | False => Left <$> getError
    True <- setWindowAlwaysOnTop window False | False => Left <$> getError
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Always-on-top requests changed target dimensions")
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())

export
alwaysOnTopTests : IO (Either String ())
alwaysOnTopTests = do
  copied <- withWindow "always on top" 37 23 (hidden <+> resizable <+> borderless <+> alwaysOnTop) $ \top =>
    withWindow "ordinary stacking" 16 16 (hidden <+> resizable <+> borderless) $ \other => do
      Right identifier <- getWindowID top | Left err => pure (Left err)
      Right () <- requests top True other False | Left err => pure (Left err)
      Right () <- requests other False top True | Left err => pure (Left err)
      Right () <- withRenderer top (retainedTarget top) | Left err => pure (Left err)
      Right after <- getWindowID top | Left err => pure (Left err)
      title <- getWindowTitle top
      Right (MkSize 37 23) <- getWindowSize top | _ => pure (Left "Always-on-top requests changed window dimensions")
      onTop <- isWindowAlwaysOnTop top
      ordinary <- isWindowAlwaysOnTop other
      if after == identifier && title == "always on top" then pure (Right (onTop, ordinary))
         else pure (Left "Always-on-top requests changed window identity or title")
  Right (True, False) <- pure copied | _ => pure (Left "Copied always-on-top flags changed after cleanup")
  pure (Right ())
