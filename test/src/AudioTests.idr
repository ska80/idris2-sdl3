module AudioTests

import SDL3
import SDL3.Raw
import SDL3.Scoped
import Data.Buffer
import Data.IORef
import System.File

%default covering

%foreign "C:idris_test_make_wav, libidris2_sdl3_test, audio_fixtures.h"
prim__makeWAV : PrimIO String

expectQueued : PlaybackStream -> Bits32 -> IO (Either String ())
expectQueued stream expected = do
  Right count <- getPlaybackQueued stream | Left err => pure (Left err)
  if count == expected then pure (Right ()) else pure (Left "Audio queue byte count was incorrect")

zeroBytes : Buffer -> Int -> Nat -> IO ()
zeroBytes buffer offset Z = pure ()
zeroBytes buffer offset (S remaining) = do
  setBits8 buffer offset 0
  zeroBytes buffer (offset + 1) remaining

invalidRanges : PlaybackStream -> Buffer -> List (Bits32, Bits32) -> IO (Either String ())
invalidRanges stream buffer [] = expectQueued stream 0
invalidRanges stream buffer ((offset, count) :: rest) = do
  False <- queueAudio stream buffer offset count | True => pure (Left "Invalid audio range was accepted")
  err <- getError
  if err == "" then pure (Left "Invalid audio range lost its error") else invalidRanges stream buffer rest

queueTests : PlaybackStream -> IO (Either String ())
queueTests stream = do
  True <- isPlaybackPaused stream | False => pure (Left "Playback did not start paused")
  Just buffer <- newBuffer 16 | Nothing => pure (Left "Cannot allocate audio test buffer")
  zeroBytes buffer 0 16
  Right () <- invalidRanges stream buffer [(1, 4), (0, 3), (12, 8), (0xffffffff, 4), (0, 0x80000000)]
    | Left err => pure (Left err)
  True <- queueAudio stream buffer 0 0 | False => Left <$> getError
  True <- queueAudio stream buffer 4 8 | False => Left <$> getError
  Right () <- expectQueued stream 8 | Left err => pure (Left err)
  True <- queueAudio stream buffer 0 4 | False => Left <$> getError
  Right () <- expectQueued stream 12 | Left err => pure (Left err)
  True <- clearPlayback stream | False => Left <$> getError
  Right () <- expectQueued stream 0 | Left err => pure (Left err)
  True <- queueAudio stream buffer 0 16 | False => Left <$> getError
  True <- flushPlayback stream | False => Left <$> getError
  -- Flush must not discard pending input.
  Right () <- expectQueued stream 16 | Left err => pure (Left err)
  True <- stopPlayback stream | False => Left <$> getError
  expectQueued stream 0

gainTests : PlaybackStream -> List Double -> IO (Either String ())
gainTests stream [] = pure (Right ())
gainTests stream (gain :: rest) = do
  True <- setPlaybackGain stream gain | False => Left <$> getError
  Right actual <- getPlaybackGain stream | Left err => pure (Left err)
  if actual /= gain then pure (Left "Audio gain did not round-trip") else do
    False <- setPlaybackGain stream (-1.0) | True => pure (Left "Negative gain was accepted")
    False <- setPlaybackGain stream 1.0e300 | True => pure (Left "Gain beyond float range was accepted")
    Right unchanged <- getPlaybackGain stream | Left err => pure (Left err)
    if unchanged /= gain then pure (Left "Invalid gain request changed volume") else gainTests stream rest

independentStreams : PlaybackStream -> PlaybackStream -> IO (Either String ())
independentStreams music sound = do
  True <- setPlaybackGain music 0.25 | False => Left <$> getError
  True <- setPlaybackGain sound 0.5 | False => Left <$> getError
  True <- resumePlayback music | False => Left <$> getError
  False <- isPlaybackPaused music | True => pure (Left "Music did not resume")
  True <- isPlaybackPaused sound | False => pure (Left "Resuming music also resumed sound")
  True <- resumePlayback sound | False => Left <$> getError
  True <- stopPlayback music | False => Left <$> getError
  True <- isPlaybackPaused music | False => pure (Left "Stop did not pause music")
  False <- isPlaybackPaused sound | True => pure (Left "Stopping music also stopped sound")
  Right 0.25 <- getPlaybackGain music | _ => pure (Left "Stop changed music gain")
  Right 0.5 <- getPlaybackGain sound | _ => pure (Left "Music controls changed sound gain")
  True <- pausePlayback sound | False => Left <$> getError
  True <- pausePlayback sound | False => Left <$> getError
  pure (Right ())

formats : List (AudioFormat, Bits32) -> IO (Either String ())
formats [] = pure (Right ())
formats ((format, bytes) :: rest) = do
  Right () <- withPlaybackStream (MkAudioSpec format 1 8000) (\stream => do
    Just buffer <- newBuffer 4 | Nothing => pure (Left "Cannot allocate format test buffer")
    zeroBytes buffer 0 4
    True <- queueAudio stream buffer 0 bytes | False => Left <$> getError
    Right () <- expectQueued stream bytes | Left err => pure (Left err)
    if bytes == 1 then pure (Right ()) else do
      False <- queueAudio stream buffer 0 (bytes - 1) | True => pure (Left "Partial sample was accepted")
      pure (Right ())) | Left err => pure (Left err)
  formats rest

wavPlayback : String -> PlaybackStream -> IO (Either String AudioSpec)
wavPlayback path stream = do
  copied <- withWAV path $ \wav => do
    let spec = wavSpec wav
    if spec /= MkAudioSpec AudioS16LE 1 8000 || wavByteLength wav /= 8 then pure (Left "WAV metadata was incorrect") else do
      True <- queueWAV stream wav | False => Left <$> getError
      True <- queueWAVRange stream wav 2 4 | False => Left <$> getError
      Right () <- expectQueued stream 12 | Left err => pure (Left err)
      False <- queueWAVRange stream wav 1 2 | True => pure (Left "Unaligned WAV range was accepted")
      False <- queueWAVRange stream wav 6 4 | True => pure (Left "Out-of-bounds WAV range was accepted")
      Right () <- withPlaybackStream (MkAudioSpec AudioU8 1 8000) (\wrong => do
        False <- queueWAV wrong wav | True => pure (Left "Mismatched WAV format was accepted")
        expectQueued wrong 0) | Left err => pure (Left err)
      pure (Right spec)
  -- The queue owns copies and remains populated after WAV cleanup.
  Right () <- expectQueued stream 12 | Left err => pure (Left err)
  True <- stopPlayback stream | False => Left <$> getError
  Right () <- withWAV path (\wav => do
    True <- playWAV stream wav | False => Left <$> getError
    False <- isPlaybackPaused stream | True => pure (Left "WAV playback did not start")
    True <- pausePlayback stream | False => Left <$> getError
    True <- playWAV stream wav | False => Left <$> getError
    True <- stopPlayback stream | False => Left <$> getError
    expectQueued stream 0) | Left err => pure (Left err)
  pure copied

invalidSpec : AudioSpec -> IO (Either String ())
invalidSpec spec = do
  called <- newIORef False
  Left err <- withPlaybackStream spec (\stream => do
    writeIORef called True
    pure (Right ())) | Right () => pure (Left "Invalid audio specification was accepted")
  False <- readIORef called | True => pure (Left "Failed audio acquisition ran its callback")
  if err /= "" then pure (Right ()) else pure (Left "Invalid audio specification lost its error")

rawFailures : IO (Either String ())
rawFailures = do
  ptr <- primIO (prim__openPlayback 0 1 8000)
  1 <- primIO (prim__isNull ptr) | _ => do
    primIO (prim__destroyPlayback ptr)
    pure (Left "Raw invalid audio format was accepted")
  count <- primIO (prim__playbackQueued ptr)
  gain <- primIO (prim__getPlaybackGain ptr)
  if count == -1 && gain == -1.0 then pure (Right ()) else pure (Left "Raw audio query lost its failure marker")

export
audioTests : IO (Either String ())
audioTests = do
  Right () <- rawFailures | Left err => pure (Left err)
  copiedResult <- withPlaybackStream (MkAudioSpec AudioU8 1 8000) $ \stream =>
    pure (Right (the Bits64 0x100000002))
  Right 0x100000002 <- pure copiedResult | _ => pure (Left "Audio scope changed the callback result")
  Right () <- invalidSpec (MkAudioSpec AudioS16LE 0 8000) | Left err => pure (Left err)
  Right () <- invalidSpec (MkAudioSpec AudioS16LE 9 8000) | Left err => pure (Left err)
  Right () <- invalidSpec (MkAudioSpec AudioS16LE 1 (-1)) | Left err => pure (Left err)
  Right () <- formats [(AudioU8, 1), (AudioS8, 1), (AudioS16LE, 2), (AudioS16BE, 2),
                       (AudioS32LE, 4), (AudioS32BE, 4), (AudioF32LE, 4), (AudioF32BE, 4)] | Left err => pure (Left err)
  Right () <- withPlaybackStream (MkAudioSpec AudioS16LE 2 8000) (\music =>
    withPlaybackStream (MkAudioSpec AudioF32LE 1 16000) $ \sound => do
      Right () <- queueTests music | Left err => pure (Left err)
      Right () <- gainTests music [0.0, 0.25, 1.0, 2.0] | Left err => pure (Left err)
      independentStreams music sound) | Left err => pure (Left err)
  failed <- withPlaybackStream (MkAudioSpec AudioS16LE 1 8000) $ \stream =>
    pure (the (Either String Bits64) (Left "audio callback result"))
  Left "audio callback result" <- pure failed | _ => pure (Left "Audio scope changed the callback error")
  path <- primIO prim__makeWAV
  if path == "" then pure (Left "Cannot create WAV fixture") else do
    result <- withPlaybackStream (MkAudioSpec AudioS16LE 1 8000) (wavPlayback path)
    _ <- removeFile path
    Left _ <- loadWAV path | Right wav => do
      freeWAV wav
      pure (Left "Missing WAV file was accepted")
    Right spec <- pure result | Left err => pure (Left err)
    if spec == MkAudioSpec AudioS16LE 1 8000 then pure (Right ()) else pure (Left "Copied WAV metadata changed after cleanup")
