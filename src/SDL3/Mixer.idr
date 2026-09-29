||| SDL3_mixer assets and tracks. Requires successful initMixer before creating resources.
module SDL3.Mixer

import SDL3
import SDL3.Raw
import SDL3.Mixer.Raw
import Data.Buffer
import System.FFI

%default total

public export
data MixerOutput = DeviceOutput | MemoryOutput

||| Owns its tracks and, for DeviceOutput, a logical audio device.
||| Destroy tracks first. Do not use any child after mixer destruction.
export
data Mixer : MixerOutput -> Type where
  MkMixer : AnyPtr -> Mixer output

||| Owned reference to an audio asset. Tracks retain their own references after assignment.
export
data Audio = MkAudio AnyPtr

||| Owned track tied to its creating mixer. No callbacks into Idris are installed.
export
data Track = MkTrack AnyPtr

||| Reusable playback properties. Allocate and configure outside the frame loop.
export
data PlayOptions = MkPlayOptions Bits32

public export
data DecodeMode = DecodeOnPlayback | Predecode

||| Repeat n means n additional plays. Repeat 0 and PlayOnce have the same effect.
public export
data LoopCount = PlayOnce | Repeat Bits32 | LoopForever

public export
data AudioDuration = KnownFrames Bits64 | UnknownDuration | InfiniteDuration

||| Not thread-safe. Pair each successful call with quitMixer after resource cleanup.
export
initMixer : IO Bool
initMixer = (/= 0) <$> primIO prim__initMixer

||| Final quit destroys remaining mixer objects. Never use or destroy those handles afterward.
||| Serialize initialization and shutdown. Release mixer resources before SDL3.quit.
export
quitMixer : IO ()
quitMixer = primIO prim__quitMixer

ownedMixerObject : (AnyPtr -> a) -> PrimIO AnyPtr -> IO (Either String a)
ownedMixerObject wrap action = do
  ptr <- primIO action
  0 <- primIO (prim__isNull ptr) | _ => Left <$> getError
  pure (Right (wrap ptr))

||| Main thread. Opens default playback and initializes SDL audio internally.
export
createMixer : IO (Either String (Mixer DeviceOutput))
createMixer = ownedMixerObject MkMixer prim__createMixerDevice

mixerFormatCode : AudioFormat -> Bits32
mixerFormatCode AudioU8 = 0x0008
mixerFormatCode AudioS8 = 0x8008
mixerFormatCode AudioS16LE = 0x8010
mixerFormatCode AudioS16BE = 0x9010
mixerFormatCode AudioS32LE = 0x8020
mixerFormatCode AudioS32BE = 0x9020
mixerFormatCode AudioF32LE = 0x8120
mixerFormatCode AudioF32BE = 0x9120

||| No device or background rendering. generateMixer advances this mixer explicitly.
export
createMemoryMixer : AudioSpec -> IO (Either String (Mixer MemoryOutput))
createMemoryMixer (MkAudioSpec format channels frequency) =
  ownedMixerObject MkMixer (prim__createMemoryMixer (mixerFormatCode format) channels frequency)

||| Also destroys remaining tracks. Device mixers must be destroyed on the main thread.
export
destroyMixer : Mixer output -> IO ()
destroyMixer (MkMixer ptr) = primIO (prim__destroyMixer ptr)

||| Loads the whole file into memory. DecodeOnPlayback stores encoded data, not a live file stream.
||| Audio assets can be shared across mixers. UTF-8 paths end at an embedded NUL.
export
loadAudio : Mixer output -> String -> DecodeMode -> IO (Either String Audio)
loadAudio (MkMixer ptr) path mode = ownedMixerObject MkAudio $
  prim__loadAudio ptr path (case mode of Predecode => 1; DecodeOnPlayback => 0)

||| Releases this reference, not references retained by tracks. Do not use the handle afterward.
export
destroyAudio : Audio -> IO ()
destroyAudio (MkAudio ptr) = primIO (prim__destroyAudio ptr)

||| Duration in the asset's sample frames. Some formats cannot report an exact length.
export
getAudioDuration : Audio -> IO AudioDuration
getAudioDuration (MkAudio ptr) = do
  value <- primIO (prim__audioDuration ptr)
  pure $ if value == -2 then InfiniteDuration
    else if value < 0 then UnknownDuration else KnownFrames (cast value)

export
createTrack : Mixer output -> IO (Either String Track)
createTrack (MkMixer ptr) = ownedMixerObject MkTrack (prim__createTrack ptr)

||| Stops immediately and releases track input. Must run before destroying its mixer.
export
destroyTrack : Track -> IO ()
destroyTrack (MkTrack ptr) = primIO (prim__destroyTrack ptr)

||| Retains an internal asset reference. Nothing removes input without destroying the caller's asset.
||| Assignment alone does not start playback. Restart explicitly after replacing input.
export
setTrackAudio : Track -> Maybe Audio -> IO Bool
setTrackAudio (MkTrack track) Nothing = (/= 0) <$> primIO (prim__clearTrackAudio track)
setTrackAudio (MkTrack track) (Just (MkAudio source)) = (/= 0) <$> primIO (prim__setTrackAudio track source)

export
newPlayOptions : IO (Either String PlayOptions)
newPlayOptions = do
  identifier <- primIO prim__newPlayOptions
  if identifier == 0 then Left <$> getError else pure (Right (MkPlayOptions identifier))

export
freePlayOptions : PlayOptions -> IO ()
freePlayOptions (MkPlayOptions identifier) = primIO (prim__freePlayOptions identifier)

loopCount : LoopCount -> Int64
loopCount PlayOnce = 0
loopCount (Repeat n) = cast n
loopCount LoopForever = -1

||| Counts above 2147483647 are rejected. Options affect later play calls, not active playback.
export
setPlayLoops : PlayOptions -> LoopCount -> IO Bool
setPlayLoops (MkPlayOptions options) count = (/= 0) <$> primIO (prim__playLoops options (loopCount count))

||| Track-input sample frames, not output frames or milliseconds. Zero starts at the beginning.
export
setPlayStartFrames : PlayOptions -> Bits64 -> IO Bool
setPlayStartFrames (MkPlayOptions options) frames = (/= 0) <$> primIO (prim__playFrames options 0 frames)

export
setPlayLoopStartFrames : PlayOptions -> Bits64 -> IO Bool
setPlayLoopStartFrames (MkPlayOptions options) frames = (/= 0) <$> primIO (prim__playFrames options 1 frames)

||| Track-input sample frames. Zero disables fade-in. Values must fit signed 64-bit range.
export
setPlayFadeInFrames : PlayOptions -> Bits64 -> IO Bool
setPlayFadeInFrames (MkPlayOptions options) frames = (/= 0) <$> primIO (prim__playFrames options 2 frames)

||| Starts or restarts assigned input. Nothing uses SDL_mixer defaults (one play, no fade).
||| Options are consumed during this call and can then be reused or freed.
export
playTrack : Track -> Maybe PlayOptions -> IO Bool
playTrack (MkTrack track) options = (/= 0) <$> primIO (prim__playTrack track (case options of
  Nothing => 0
  Just (MkPlayOptions value) => value))

||| Fade over input sample frames, or stop immediately with zero. Does not wait for the fade.
export
stopTrack : Track -> Bits64 -> IO Bool
stopTrack (MkTrack track) frames = (/= 0) <$> primIO (prim__stopTrack track frames)

export
pauseTrack : Track -> IO Bool
pauseTrack (MkTrack track) = (/= 0) <$> primIO (prim__pauseTrack track)

export
resumeTrack : Track -> IO Bool
resumeTrack (MkTrack track) = (/= 0) <$> primIO (prim__resumeTrack track)

||| State, not success or audible completion. Paused tracks are not playing.
export
trackPlaying : Track -> IO Bool
trackPlaying (MkTrack track) = (/= 0) <$> primIO (prim__trackPlaying track)

export
trackPaused : Track -> IO Bool
trackPaused (MkTrack track) = (/= 0) <$> primIO (prim__trackPaused track)

||| Finite nonnegative amplitude multiplier. One is unchanged; above one can distort output.
export
setMixerGain : Mixer output -> Double -> IO Bool
setMixerGain (MkMixer ptr) gain = (/= 0) <$> primIO (prim__setMixerGain ptr gain)

||| Requires a live mixer. SDL float precision widened to Double.
export
getMixerGain : Mixer output -> IO Double
getMixerGain (MkMixer ptr) = primIO (prim__getMixerGain ptr)

export
setTrackGain : Track -> Double -> IO Bool
setTrackGain (MkTrack ptr) gain = (/= 0) <$> primIO (prim__setTrackGain ptr gain)

||| Requires a live track. Does not include the master gain or current fade envelope.
export
getTrackGain : Track -> IO Double
getTrackGain (MkTrack ptr) = primIO (prim__getTrackGain ptr)

||| Input frames. Some decoders cannot seek exactly. Later playTrack calls reset the start position.
export
setTrackPlaybackPosition : Track -> Bits64 -> IO Bool
setTrackPlaybackPosition (MkTrack ptr) frames = (/= 0) <$> primIO (prim__seekTrack ptr frames)

mixerFrames : PrimIO Int64 -> IO (Either String Bits64)
mixerFrames action = do
  value <- primIO action
  if value < 0 then Left <$> getError else pure (Right (cast value))

export
getTrackPlaybackPosition : Track -> IO (Either String Bits64)
getTrackPlaybackPosition (MkTrack ptr) = mixerFrames (prim__trackPosition ptr)

||| Convert milliseconds using assigned input, not the mixer output rate.
export
trackMSToFrames : Track -> Bits32 -> IO (Either String Bits64)
trackMSToFrames (MkTrack ptr) ms = mixerFrames (prim__trackMSToFrames ptr (cast ms))

||| Checked byte range in a reusable buffer. Only memory mixers support explicit generation.
||| On success all requested bytes are initialized, including silence. The count excludes trailing silence.
||| Read only after this call returns. The buffer is not retained. SDL can allocate internally.
export
generateMixer : Mixer MemoryOutput -> Buffer -> Bits32 -> Bits32 -> IO (Either String Bits32)
generateMixer (MkMixer ptr) buffer offset count = do
  capacity <- rawSize buffer
  generated <- primIO (prim__generate ptr buffer (cast capacity) offset count)
  if generated < 0 then Left <$> getError else pure (Right (cast generated))

decoderNames : Int32 -> Nat -> IO (List String)
decoderNames index Z = pure []
decoderNames index (S remaining) = do
  name <- primIO (prim__decoderName index)
  rest <- decoderNames (index + 1) remaining
  pure (name :: rest)

||| Copied decoder names, not a guaranteed list of file extensions. Requires initialized SDL_mixer.
export
getAudioDecoders : IO (List String)
getAudioDecoders = do
  count <- primIO prim__decoderCount
  decoderNames 0 (cast count)
