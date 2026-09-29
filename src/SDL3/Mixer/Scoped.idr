module SDL3.Mixer.Scoped

import SDL3
import SDL3.Mixer

%default total

withOwned : IO (Either String resource) -> (resource -> IO ()) ->
            (resource -> IO (Either String a)) -> IO (Either String a)
withOwned acquire release action = do
  Right resource <- acquire | Left err => pure (Left err)
  result <- action resource
  release resource
  pure result

||| Balance one successful initMixer with quitMixer on ordinary return. Not thread-safe.
||| All child scopes must finish first. Exceptions and nonreturning actions do not guarantee cleanup.
export
withMixerLibrary : IO (Either String a) -> IO (Either String a)
withMixerLibrary action = do
  True <- initMixer | False => Left <$> getError
  result <- action
  quitMixer
  pure result

||| Main-thread device ownership. Destroy all track scopes before returning.
||| Do not destroy or retain the supplied mixer. Ordinary returns only guarantee cleanup.
export
withMixer : (Mixer DeviceOutput -> IO (Either String a)) -> IO (Either String a)
withMixer = withOwned createMixer destroyMixer

export
withMemoryMixer : AudioSpec -> (Mixer MemoryOutput -> IO (Either String a)) -> IO (Either String a)
withMemoryMixer spec = withOwned (createMemoryMixer spec) destroyMixer

||| Own the caller's asset reference. Assigned tracks keep their internal references.
||| Do not destroy or retain the supplied Audio after return. Ordinary-return cleanup only.
export
withAudio : Mixer output -> String -> DecodeMode -> (Audio -> IO (Either String a)) -> IO (Either String a)
withAudio mixer path mode = withOwned (loadAudio mixer path mode) destroyAudio

||| Keep the mixer alive until this callback returns and the track is destroyed.
||| Do not destroy or retain the supplied track. Ordinary-return cleanup only.
export
withTrack : Mixer output -> (Track -> IO (Either String a)) -> IO (Either String a)
withTrack mixer = withOwned (createTrack mixer) destroyTrack

||| Allocate once around the playback loop. Options are not retained by playTrack.
||| Do not free or retain the supplied options. Ordinary-return cleanup only.
export
withPlayOptions : (PlayOptions -> IO (Either String a)) -> IO (Either String a)
withPlayOptions = withOwned newPlayOptions freePlayOptions
