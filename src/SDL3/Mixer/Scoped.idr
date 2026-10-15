||| Mixer ownership scopes. Shared cleanup contract: docs/resources.md.
module SDL3.Mixer.Scoped

import SDL3
import SDL3.Mixer
import SDL3.Internal.Resource

%default total

||| Balance one successful initialization. Serialize initialization/shutdown; finish child scopes first.
export
withMixerLibrary : IO (Either String a) -> IO (Either String a)
withMixerLibrary = withLibrary initMixer quitMixer

||| Main-thread device ownership. Finish track scopes before returning.
export
withMixer : (Mixer DeviceOutput -> IO (Either String a)) -> IO (Either String a)
withMixer = withResource createMixer destroyMixer

||| No device or background processing. Finish track scopes before returning.
export
withMemoryMixer : AudioSpec -> (Mixer MemoryOutput -> IO (Either String a)) -> IO (Either String a)
withMemoryMixer spec = withResource (createMemoryMixer spec) destroyMixer

||| Own the caller's asset reference. Assigned tracks retain their own references.
export
withAudio : Mixer output -> String -> DecodeMode -> (Audio -> IO (Either String a)) -> IO (Either String a)
withAudio mixer path mode = withResource (loadAudio mixer path mode) destroyAudio

||| Keep the creating mixer alive through track cleanup.
export
withTrack : Mixer output -> (Track -> IO (Either String a)) -> IO (Either String a)
withTrack mixer = withResource (createTrack mixer) destroyTrack

||| Allocate around playback, not per play. playTrack does not retain options.
export
withPlayOptions : (PlayOptions -> IO (Either String a)) -> IO (Either String a)
withPlayOptions = withResource newPlayOptions freePlayOptions
