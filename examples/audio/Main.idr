module Main

import SDL3
import SDL3.Scoped

import System

%default covering

report : IO Bool -> IO ()
report action = do
  True <- action | False => getError >>= putStrLn
  pure ()

controls : String
controls = "p pause, r resume, m restart music, s stop music, f sound, x stop sound, 0 mute music, 1 restore volume, q quit."

commands : PlaybackStream -> WAV -> PlaybackStream -> WAV -> IO ()
commands music musicData sound soundData = do
  command <- getLine
  case command of
    "q" => pure ()
    "" => pure () -- Also exit when input reaches EOF.
    _ => do
      case command of
        "p" => report (pausePlayback music)
        "r" => report (resumePlayback music)
        "m" => report (playWAV music musicData)
        "s" => report (stopPlayback music)
        "f" => report (playWAV sound soundData)
        "x" => report (stopPlayback sound)
        "0" => report (setPlaybackGain music 0.0)
        "1" => report (setPlaybackGain music 0.25)
        _ => putStrLn controls
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
        putStrLn controls
        commands music musicData sound soundData
        -- Stream scopes discard queued audio and close both logical devices.
        pure (Right ())

main : IO ()
main = do
  [_, musicPath, soundPath] <- getArgs | _ => die "Usage: audio music.wav sound.wav"
  ok <- init audio
  result <- if ok then run musicPath soundPath else Left <$> getError
  quit
  either die pure result
