||| Shared ordinary-return cleanup. Not an application API or an exception handler.
module SDL3.Internal.Resource

import SDL3.Raw

%default total

-- Copy the error before any cleanup call can replace it.
sdlFailure : IO (Either String a)
sdlFailure = Left <$> primIO prim__getError

finish : IO Bool -> Either String a -> IO (Either String a)
finish cleanup result = do
  succeeded <- cleanup
  case result of
    Left err => pure (Left err)
    Right value => if succeeded then pure (Right value) else sdlFailure

export
withResource : IO (Either String resource) -> (resource -> IO ()) ->
               (resource -> IO (Either String a)) -> IO (Either String a)
withResource acquire release action = do
  Right resource <- acquire | Left err => pure (Left err)
  result <- action resource
  release resource
  pure result

export
withCheckedResource : IO (Either String resource) -> (resource -> IO Bool) ->
                      (resource -> IO (Either String a)) -> IO (Either String a)
withCheckedResource acquire release action = do
  Right resource <- acquire | Left err => pure (Left err)
  result <- action resource
  finish (release resource) result

export
withLibrary : IO Bool -> IO () -> IO (Either String a) -> IO (Either String a)
withLibrary start stop action = withResource acquire (\_ => stop) (\_ => action)
  where
    acquire : IO (Either String ())
    acquire = do
      True <- start | False => sdlFailure
      pure (Right ())

||| Attempt restoration even when setting fails. Setting/action errors take precedence.
export
withRestored : IO Bool -> IO Bool -> IO (Either String a) -> IO (Either String a)
withRestored {a} set restore action = do
  changed <- set
  result <- the (IO (Either String a)) (if changed then action else sdlFailure)
  finish restore result

export
withState : IO (Either String state) -> (state -> IO Bool) -> state -> IO (Either String a) -> IO (Either String a)
withState query set temporary action = do
  Right previous <- query | Left err => pure (Left err)
  withRestored (set temporary) (set previous) action
