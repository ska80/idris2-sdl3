module VSyncTests

import SDL3

%default covering

rejectedInterval : Renderer -> Bits32 -> IO (Either String ())
rejectedInterval renderer interval = do
  Right before <- getRenderVSync renderer | Left err => pure (Left err)
  False <- setRenderVSync renderer (VSyncInterval interval)
    | True => pure (Left "Invalid VSync interval was accepted")
  err <- getError
  Right after <- getRenderVSync renderer | Left message => pure (Left message)
  if err /= "" && before == after then pure (Right ())
     else pure (Left "Rejected VSync interval lost its error or changed renderer state")

optionalMode : Renderer -> VSyncMode -> IO (Either String ())
optionalMode renderer requested = do
  supported <- setRenderVSync renderer requested
  case supported of
    True => do
      Right actual <- getRenderVSync renderer | Left err => pure (Left err)
      if actual == requested then pure (Right ()) else pure (Left "VSync query did not match the selected mode")
    False => do
      -- Drivers need not support adaptive synchronization or every interval.
      err <- getError
      if err /= "" then pure (Right ()) else pure (Left "Unsupported VSync mode produced no error")

export
vsyncTests : Renderer -> IO (Either String ())
vsyncTests renderer = do
  True <- setRenderVSync renderer VSyncDisabled | False => Left <$> getError
  result <- do
    Right actual <- getRenderVSync renderer | Left err => pure (Left err)
    if actual /= VSyncDisabled then pure (Left "Cannot disable VSync") else do
      Right () <- rejectedInterval renderer 0 | Left err => pure (Left err)
      Right () <- rejectedInterval renderer 2147483648 | Left err => pure (Left err)
      Right () <- rejectedInterval renderer 4294967295 | Left err => pure (Left err)
      Right () <- optionalMode renderer (VSyncInterval 1) | Left err => pure (Left err)
      Right () <- optionalMode renderer (VSyncInterval 2) | Left err => pure (Left err)
      -- Query the largest interval without presenting a frame at that interval.
      Right () <- optionalMode renderer (VSyncInterval 2147483647) | Left err => pure (Left err)
      optionalMode renderer VSyncAdaptive
  restored <- setRenderVSync renderer VSyncDisabled
  Right () <- pure result | Left err => pure (Left err)
  if restored then pure (Right ()) else Left <$> getError
