||| Share the core audio-format conversion without re-exporting it to applications.
module SDL3.Internal.Audio

%default total

public export
interface NativeAudioFormat (0 format : Type) where
  audioFormatCode : format -> Bits32
