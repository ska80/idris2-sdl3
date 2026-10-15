module Main

import SDL3
import SDL3.Mixer
import SDL3.Mixer.Scoped

import System

%default covering

report : IO Bool -> IO ()
report action = do
  True <- action | False => getError >>= putStrLn
  pure ()

fadeOut : Track -> IO ()
fadeOut track = do
  Right frames <- trackMSToFrames track 1000 | Left err => putStrLn err
  report (stopTrack track frames)

controls : String
controls = "p pause, r resume, m restart music, s stop music, d fade out, f sound, x stop sound, q quit."

commands : Track -> Track -> PlayOptions -> IO ()
commands music sound options = do
  command <- getLine
  case command of
    "q" => pure ()
    "" => pure () -- Also exit when input reaches EOF.
    _ => do
      case command of
        "p" => report (pauseTrack music)
        "r" => report (resumeTrack music)
        "m" => report (playTrack music (Just options))
        "s" => report (stopTrack music 0)
        "d" => fadeOut music
        "f" => report (playTrack sound Nothing)
        "x" => report (stopTrack sound 0)
        _ => putStrLn controls
      commands music sound options

loadTrack : Mixer output -> Track -> String -> DecodeMode -> IO (Either String ())
loadTrack mixer track path mode = withAudio mixer path mode $ \asset => do
  True <- setTrackAudio track (Just asset) | False => Left <$> getError
  -- The track retains its input after the caller's asset reference is released.
  pure (Right ())

run : String -> String -> IO (Either String ())
run musicPath soundPath = withMixerLibrary $ withMixer $ \mixer =>
  withTrack mixer $ \music => withTrack mixer $ \sound => withPlayOptions $ \options => do
    Right () <- loadTrack mixer music musicPath DecodeOnPlayback | Left err => pure (Left err)
    Right () <- loadTrack mixer sound soundPath Predecode | Left err => pure (Left err)
    True <- setTrackGain music 0.25 | False => Left <$> getError
    True <- setTrackGain sound 0.5 | False => Left <$> getError
    True <- setPlayLoops options LoopForever | False => Left <$> getError
    Right fadeFrames <- trackMSToFrames music 500 | Left err => pure (Left err)
    True <- setPlayFadeInFrames options fadeFrames | False => Left <$> getError
    True <- playTrack music (Just options) | False => Left <$> getError
    putStrLn "Music loops. Sound uses a separate reusable track. Each command needs Enter."
    putStrLn controls
    commands music sound options
    -- Track scopes stop playback before the mixer and its device are destroyed.
    pure (Right ())

main : IO ()
main = do
  [_, musicPath, soundPath] <- getArgs | _ => die "Usage: mixer music-file sound-file"
  result <- run musicPath soundPath
  SDL3.quit
  either die pure result
