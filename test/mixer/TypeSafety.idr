module TypeSafety

import SDL3
import SDL3.Mixer
import SDL3.Mixer.Scoped

import Data.Buffer

import System.FFI

failing "Mismatch between"
  playbackAsMixer : PlaybackStream -> IO (Either String Track)
  playbackAsMixer stream = createTrack stream

failing "Mismatch between"
  wavAsAsset : Track -> WAV -> IO Bool
  wavAsAsset track wav = setTrackAudio track (Just wav)

failing "Mismatch between"
  textureAsTrack : Texture StaticAccess -> IO Bool
  textureAsTrack texture = pauseTrack texture

failing "Mismatch between"
  deviceGeneration : Mixer DeviceOutput -> Buffer -> IO (Either String Bits32)
  deviceGeneration mixer buffer = generateMixer mixer buffer 0 4

failing "Mismatch between"
  signedFade : Track -> Int64 -> IO Bool
  signedFade track count = stopTrack track count

failing "Name SDL3.Mixer.MkMixer is private"
  forgeMixer : AnyPtr -> Mixer MemoryOutput
  forgeMixer = MkMixer

failing "Name SDL3.Mixer.MkTrack is private"
  forgeTrack : AnyPtr -> Track
  forgeTrack = MkTrack

failing "Name SDL3.Mixer.MkAudio is private"
  forgeAudio : AnyPtr -> Audio
  forgeAudio = MkAudio

failing "Name SDL3.Mixer.MkPlayOptions is private"
  forgeOptions : Bits32 -> PlayOptions
  forgeOptions = MkPlayOptions
