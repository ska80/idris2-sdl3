module Assets

import SDL3
import SDL3.Scoped
import SDL3.Mixer
import SDL3.Mixer.Scoped

%default covering

circlePixels : LockedRGBA -> Int32 -> Nat -> IO Bool
circlePixels view index Z = pure True
circlePixels view index (S n) = do
  let x = index `mod` 96
  let y = index `div` 96
  let dx : Double = cast x + 0.5 - 48
  let dy : Double = cast y + 0.5 - 48
  let distance = sqrt (dx * dx + dy * dy)
  let alpha : Bits8 = cast (255 * max 0 (min 1 (48 - distance)))
  let shade : Bits8 = cast (180 + 75 * sqrt (max 0 (1 - distance * distance / 2304)))
  True <- setLockedPixelRGBA view x y shade shade shade alpha | False => pure False
  circlePixels view (index + 1) n

export
withBallTexture : Renderer -> (Texture StreamingAccess -> IO (Either String a)) -> IO (Either String a)
withBallTexture renderer action = withStreamingTexture renderer 96 96 $ \texture => do
  True <- setTextureBlendMode texture AlphaBlend | False => Left <$> getError
  True <- setTextureScaleMode texture LinearScale | False => Left <$> getError
  Right () <- withTextureLockBuffer (\storage =>
    withTextureLockRGBA storage texture Nothing $ \view => do
      -- Initialize all pixels first, even if a later pixel write fails.
      True <- fillLockedRGBA view 255 255 255 0 | False => Left <$> getError
      True <- circlePixels view 0 (96 * 96) | False => Left <$> getError
      pure (Right ())) | Left err => pure (Left err)
  -- All balls share this initialized texture. No more locks or uploads are needed.
  action texture

withTracks : Nat -> Mixer DeviceOutput -> (List Track -> IO (Either String a)) -> IO (Either String a)
withTracks Z mixer action = action []
withTracks (S n) mixer action = withTrack mixer $ \track =>
  withTracks n mixer $ \rest => action (track :: rest)

assign : Audio -> Double -> List Track -> IO (Either String ())
assign asset gain [] = pure (Right ())
assign asset gain (track :: rest) = do
  True <- setTrackAudio track (Just asset) | False => Left <$> getError
  True <- setTrackGain track gain | False => Left <$> getError
  assign asset gain rest

export
withSounds : (List Track -> IO (Either String a)) -> IO (Either String a)
withSounds action = withMixerLibrary $ withMixer $ \mixer =>
  withTrack mixer $ \music => withTracks 16 mixer $ \effects => do
    Right () <- withAudio mixer "assets/music.ogg" Predecode (\asset => assign asset 0.18 [music])
      | Left err => pure (Left err)
    Right () <- withAudio mixer "assets/sound.wav" Predecode (\asset => assign asset 0.08 effects)
      | Left err => pure (Left err)
    -- Tracks retain the shared inputs after the caller releases both assets.
    Right () <- withPlayOptions (\options => do
      True <- setPlayLoops options LoopForever | False => Left <$> getError
      Right fade <- trackMSToFrames music 800 | Left err => pure (Left err)
      True <- setPlayFadeInFrames options fade | False => Left <$> getError
      True <- playTrack music (Just options) | False => Left <$> getError
      pure (Right ())) | Left err => pure (Left err)
    -- Track scopes stop playback before the mixer closes its device.
    action effects

-- Rotate through fixed voices. When all are busy, restart the oldest voice.
export
playBounces : List Track -> List Track -> Nat -> IO (Either String (List Track))
playBounces all remaining Z = pure (Right remaining)
playBounces [] _ (S n) = pure (Left "The bounce sound pool is empty")
playBounces all@(_ :: _) [] count = playBounces all all count
playBounces all (track :: rest) (S n) = do
  True <- playTrack track Nothing | False => Left <$> getError
  playBounces all rest n
