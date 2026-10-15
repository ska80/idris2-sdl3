module Main

import TypeSafety

import SDL3
import SDL3.Mixer
import SDL3.Mixer.Scoped

import Data.Buffer
import Data.IORef

import System
import System.File

%default covering

%foreign "C:idris_test_make_wav, libidris2_sdl3_mixer_test, audio_fixtures.h"
prim__makeWAV : PrimIO String

require : IO Bool -> IO (Either String ())
require action = do
  True <- action | False => Left <$> getError
  pure (Right ())

loadAssigned : Mixer output -> String -> Track -> IO (Either String AudioDuration)
loadAssigned mixer path track = withAudio mixer path Predecode $ \asset => do
  Right () <- require (setTrackAudio track (Just asset)) | Left err => pure (Left err)
  Right <$> getAudioDuration asset

oneShot : Mixer MemoryOutput -> Track -> Buffer -> IO (Either String ())
oneShot mixer track buffer = do
  Right () <- require (playTrack track Nothing) | Left err => pure (Left err)
  Right 8 <- generateMixer mixer buffer 2 16 | _ => pure (Left "Incorrect one-shot output count")
  77 <- getBits8 buffer 0 | _ => pure (Left "Generation changed prefix guard")
  88 <- getBits8 buffer 18 | _ => pure (Left "Generation changed suffix guard")
  4096 <- getBits16 buffer 4 | _ => pure (Left "Mixed positive sample was incorrect")
  61440 <- getBits16 buffer 6 | _ => pure (Left "Mixed negative sample was incorrect")
  0 <- getBits16 buffer 16 | _ => pure (Left "Trailing output was not silent")
  False <- trackPlaying track | True => pure (Left "One-shot track did not finish")
  pure (Right ())

looping : Mixer MemoryOutput -> Track -> Buffer -> IO (Either String ())
looping mixer track buffer = do
  Right () <- withPlayOptions (\options => do
    Right () <- require (setPlayLoops options LoopForever) | Left err => pure (Left err)
    False <- setPlayLoops options (Repeat 0x80000000) | True => pure (Left "Oversized loop count accepted")
    False <- setPlayStartFrames options 0xffffffffffffffff | True => pure (Left "Oversized start accepted")
    require (playTrack track (Just options))) | Left err => pure (Left err)
  -- Options and caller audio references are gone; playback retains its own state and input.
  Right 32 <- generateMixer mixer buffer 0 32 | _ => pure (Left "Looped output count was incorrect")
  True <- trackPlaying track | False => pure (Left "Infinite loop stopped")
  Right () <- require (pauseTrack track) | Left err => pure (Left err)
  True <- trackPaused track | False => pure (Left "Track did not pause")
  False <- trackPlaying track | True => pure (Left "Paused track reported playing")
  Right position <- getTrackPlaybackPosition track | Left err => pure (Left err)
  Right 0 <- generateMixer mixer buffer 0 32 | _ => pure (Left "Paused track generated input")
  Right unchanged <- getTrackPlaybackPosition track | Left err => pure (Left err)
  True <- pure (position == unchanged) | False => pure (Left "Pause advanced track position")
  Right () <- require (resumeTrack track) | Left err => pure (Left err)
  Right 8000 <- trackMSToFrames track 1000 | _ => pure (Left "Milliseconds conversion was incorrect")
  Right () <- require (setTrackPlaybackPosition track 1) | Left err => pure (Left err)
  Right 1 <- getTrackPlaybackPosition track | _ => pure (Left "Track seek was incorrect")
  False <- stopTrack track 0xffffffffffffffff | True => pure (Left "Oversized fade accepted")
  Right () <- require (stopTrack track 4) | Left err => pure (Left err)
  Right _ <- generateMixer mixer buffer 0 32 | Left err => pure (Left err)
  False <- trackPlaying track | True => pure (Left "Fade-out did not finish")
  pure (Right ())

finiteLoop : Mixer MemoryOutput -> Track -> Buffer -> IO (Either String ())
finiteLoop mixer track buffer = withPlayOptions $ \options => do
  Right () <- require (setPlayLoops options (Repeat 1)) | Left err => pure (Left err)
  Right () <- require (setPlayLoopStartFrames options 1) | Left err => pure (Left err)
  Right () <- require (setPlayFadeInFrames options 2) | Left err => pure (Left err)
  Right () <- require (playTrack track (Just options)) | Left err => pure (Left err)
  Right 14 <- generateMixer mixer buffer 0 32 | _ => pure (Left "Finite loop point produced wrong frame count")
  False <- trackPlaying track | True => pure (Left "Finite loop did not stop")
  require (setPlayLoops options PlayOnce)

memoryTests : String -> Mixer MemoryOutput -> IO (Either String AudioDuration)
memoryTests path mixer = withTrack mixer $ \track => do
  False <- playTrack track Nothing | True => pure (Left "Empty track played")
  Right duration <- loadAssigned mixer path track | Left err => pure (Left err)
  Just buffer <- newBuffer 32 | Nothing => pure (Left "Cannot allocate mixer output")
  setBits8 buffer 0 77
  setBits8 buffer 18 88
  Left _ <- generateMixer mixer buffer 1 4 | Right _ => pure (Left "Unaligned output offset accepted")
  Left _ <- generateMixer mixer buffer 0 3 | Right _ => pure (Left "Partial output frame accepted")
  Left _ <- generateMixer mixer buffer 30 4 | Right _ => pure (Left "Short output buffer accepted")
  Right () <- oneShot mixer track buffer | Left err => pure (Left err)
  Right () <- looping mixer track buffer | Left err => pure (Left err)
  Right () <- finiteLoop mixer track buffer | Left err => pure (Left err)
  let readGain = getTrackGain track
  1.0 <- readGain | _ => pure (Left "Wrong initial track gain")
  Right () <- require (setTrackGain track 0.25) | Left err => pure (Left err)
  0.25 <- readGain | _ => pure (Left "Cached gain action did not read new state")
  Right () <- require (setMixerGain mixer 0.5) | Left err => pure (Left err)
  False <- setTrackGain track (-1.0) | True => pure (Left "Negative gain accepted")
  False <- setMixerGain mixer 1.0e300 | True => pure (Left "Oversized gain accepted")
  0.25 <- getTrackGain track | _ => pure (Left "Track gain changed after rejection")
  0.5 <- getMixerGain mixer | _ => pure (Left "Mixer gain changed after rejection")
  Right () <- require (setTrackAudio track Nothing) | Left err => pure (Left err)
  False <- playTrack track Nothing | True => pure (Left "Cleared track played")
  pure (Right duration)

deviceTests : String -> IO (Either String ())
deviceTests path = withMixer $ \mixer => withAudio mixer path DecodeOnPlayback $ \asset =>
  withTrack mixer $ \music => withTrack mixer $ \sound => withPlayOptions $ \options => do
    Right () <- require (setTrackAudio music (Just asset)) | Left err => pure (Left err)
    Right () <- require (setTrackAudio sound (Just asset)) | Left err => pure (Left err)
    Right () <- require (setPlayLoops options LoopForever) | Left err => pure (Left err)
    Right () <- require (playTrack music (Just options)) | Left err => pure (Left err)
    Right () <- require (playTrack sound (Just options)) | Left err => pure (Left err)
    Right () <- require (pauseTrack music) | Left err => pure (Left err)
    True <- trackPaused music | False => pure (Left "Device track did not pause")
    True <- trackPlaying sound | False => pure (Left "Pausing music also paused sound")
    Right () <- require (stopTrack music 0) | Left err => pure (Left err)
    True <- trackPlaying sound | False => pure (Left "Stopping music also stopped sound")
    require (stopTrack sound 0)

formats : List (AudioFormat, Bits32) -> IO (Either String ())
formats [] = pure (Right ())
formats ((format, frameBytes) :: rest) = do
  Right () <- withMemoryMixer (MkAudioSpec format 1 8000) (\mixer => do
    Just buffer <- newBuffer 8 | Nothing => pure (Left "Cannot allocate format test output")
    setBits8 buffer 0 17
    Right 0 <- generateMixer mixer buffer 0 frameBytes | _ => pure (Left "Empty mixer did not produce silence")
    sample <- getBits8 buffer 0
    let expected : Bits8 = case format of AudioU8 => 128; _ => 0
    if sample == expected then pure (Right ()) else pure (Left "Incorrect silence format"))
      | Left err => pure (Left err)
  formats rest

tests : IO (Either String ())
tests = do
  Right () <- formats [(AudioU8, 1), (AudioS8, 1), (AudioS16LE, 2), (AudioS16BE, 2),
                       (AudioS32LE, 4), (AudioS32BE, 4), (AudioF32LE, 4), (AudioF32BE, 4)]
    | Left err => pure (Left err)
  decoders <- getAudioDecoders
  False <- pure (null decoders) | True => pure (Left "No mixer decoders reported")
  called <- newIORef False
  Left _ <- withMemoryMixer (MkAudioSpec AudioS16LE 0 8000) (\mixer => do
    writeIORef called True
    pure (Right ())) | Right () => pure (Left "Invalid mixer format accepted")
  False <- readIORef called | True => pure (Left "Failed creation ran callback")
  Left _ <- withMemoryMixer (MkAudioSpec AudioS16LE 1 8000) (\mixer =>
    withAudio mixer "/nonexistent/idris-mixer-test" Predecode (\asset => do
      writeIORef called True
      pure (Right ()))) | Right () => pure (Left "Missing audio file loaded")
  False <- readIORef called | True => pure (Left "Failed audio load ran callback")
  failed <- withMemoryMixer (MkAudioSpec AudioS16LE 1 8000) $ \mixer =>
    withTrack mixer $ \track => pure (the (Either String Bits64) (Left "mixer callback"))
  Left "mixer callback" <- pure failed | _ => pure (Left "Mixer scope changed callback error")
  path <- primIO prim__makeWAV
  if path == "" then pure (Left "Cannot create mixer WAV fixture") else do
    result <- withMemoryMixer (MkAudioSpec AudioS16LE 1 8000) (memoryTests path)
    device <- deviceTests path
    _ <- removeFile path
    Right duration <- pure result | Left err => pure (Left err)
    KnownFrames 4 <- pure duration | _ => pure (Left "Copied audio duration was incorrect")
    pure device

main : IO ()
main = do
  result <- withMixerLibrary tests
  SDL3.quit
  case result of
    Right () => putStrLn "Mixer Idris tests passed"
    Left err => do
      putStrLn err
      exitFailure
