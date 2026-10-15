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

commands : Track -> Track -> PlayOptions -> IO ()
commands music sound options = do
  command <- getLine
  case command of
    "q" => pure ()
    "" => pure ()
    "p" => do report (pauseTrack music); commands music sound options
    "r" => do report (resumeTrack music); commands music sound options
    "m" => do report (playTrack music (Just options)); commands music sound options
    "s" => do report (stopTrack music 0); commands music sound options
    "d" => do fadeOut music; commands music sound options
    "f" => do report (playTrack sound Nothing); commands music sound options
    "x" => do report (stopTrack sound 0); commands music sound options
    _ => do
      putStrLn "p pause, r resume, m restart music, s stop music, d fade out, f sound, x stop sound, q quit."
      commands music sound options

run : String -> String -> IO (Either String ())
run musicPath soundPath = withMixerLibrary $ withMixer $ \mixer =>
  withAudio mixer musicPath DecodeOnPlayback $ \musicAudio =>
    withAudio mixer soundPath Predecode $ \soundAudio =>
      withTrack mixer $ \music => withTrack mixer $ \sound => withPlayOptions $ \options => do
        True <- setTrackAudio music (Just musicAudio) | False => Left <$> getError
        True <- setTrackAudio sound (Just soundAudio) | False => Left <$> getError
        True <- setTrackGain music 0.25 | False => Left <$> getError
        True <- setTrackGain sound 0.5 | False => Left <$> getError
        True <- setPlayLoops options LoopForever | False => Left <$> getError
        Right fadeFrames <- trackMSToFrames music 500 | Left err => pure (Left err)
        True <- setPlayFadeInFrames options fadeFrames | False => Left <$> getError
        True <- playTrack music (Just options) | False => Left <$> getError
        putStrLn "Music loops. Sound uses a separate reusable track. Each command needs Enter."
        putStrLn "p pause, r resume, m restart music, s stop music, d fade out, f sound, x stop sound, q quit."
        commands music sound options
        True <- stopTrack music 0 | False => Left <$> getError
        True <- stopTrack sound 0 | False => Left <$> getError
        pure (Right ())

main : IO ()
main = do
  [_, musicPath, soundPath] <- getArgs | _ => do
    putStrLn "Usage: mixer-example music-file sound-file"
    exitFailure
  result <- run musicPath soundPath
  SDL3.quit
  case result of
    Right () => pure ()
    Left err => do
      putStrLn err
      exitFailure
