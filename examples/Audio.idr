module Audio

import SDL3
import SDL3.Scoped

import System

%default covering

report : IO Bool -> IO ()
report action = do
  True <- action | False => getError >>= putStrLn
  pure ()

commands : PlaybackStream -> WAV -> PlaybackStream -> WAV -> IO ()
commands music musicData sound soundData = do
  command <- getLine
  case command of
    "q" => pure ()
    "" => pure () -- Also exit when input reaches EOF.
    "p" => do report (pausePlayback music); commands music musicData sound soundData
    "r" => do report (resumePlayback music); commands music musicData sound soundData
    "m" => do report (playWAV music musicData); commands music musicData sound soundData
    "s" => do report (stopPlayback music); commands music musicData sound soundData
    "f" => do report (playWAV sound soundData); commands music musicData sound soundData
    "x" => do report (stopPlayback sound); commands music musicData sound soundData
    "0" => do report (setPlaybackGain music 0.0); commands music musicData sound soundData
    "1" => do report (setPlaybackGain music 0.25); commands music musicData sound soundData
    _ => do
      putStrLn "Use p pause, r resume, m restart music, s stop music, f sound, x stop sound, 0 mute music, 1 restore volume, q quit."
      commands music musicData sound soundData

run : String -> String -> IO (Either String ())
run musicPath soundPath = withWAV musicPath $ \musicData =>
  withWAV soundPath $ \soundData =>
    withPlaybackStream (wavSpec musicData) $ \music =>
      withPlaybackStream (wavSpec soundData) $ \sound => do
        -- SDL mixes these separate logical playback devices. No Idris audio callback is installed.
        True <- setPlaybackGain music 0.25 | False => Left <$> getError
        True <- setPlaybackGain sound 0.5 | False => Left <$> getError
        True <- playWAV music musicData | False => Left <$> getError
        putStrLn "Music plays once. Use m to restart. Sound playback uses an independent stream."
        putStrLn "p pause, r resume, m restart music, s stop music, f sound, x stop sound, 0 mute music, 1 restore volume, q quit."
        commands music musicData sound soundData
        True <- stopPlayback music | False => Left <$> getError
        True <- stopPlayback sound | False => Left <$> getError
        pure (Right ())

main : IO ()
main = do
  args <- getArgs
  case args of
    [_, musicPath, soundPath] => do
      True <- init audio | False => do
        getError >>= putStrLn
        exitFailure
      result <- run musicPath soundPath
      quit
      case result of
        Right () => pure ()
        Left err => do
          putStrLn err
          exitFailure
    _ => do
      putStrLn "Usage: sdl3-audio music.wav sound.wav"
      exitFailure
