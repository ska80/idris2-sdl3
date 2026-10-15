module SDL3.Mixer.Raw

import Data.Buffer

import System.FFI

%default total

%foreign "C:idris_mix_init, libidris2_sdl3_mixer, mixer.h"
export
prim__initMixer : PrimIO Int

%foreign "C:MIX_Quit, libSDL3_mixer"
export
prim__quitMixer : PrimIO ()

%foreign "C:idris_mix_create_device, libidris2_sdl3_mixer, mixer.h"
export
prim__createMixerDevice : PrimIO AnyPtr

%foreign "C:idris_mix_create_memory, libidris2_sdl3_mixer, mixer.h"
export
prim__createMemoryMixer : Bits32 -> Int32 -> Int32 -> PrimIO AnyPtr

%foreign "C:MIX_DestroyMixer, libSDL3_mixer"
export
prim__destroyMixer : AnyPtr -> PrimIO ()

%foreign "C:idris_mix_load_audio, libidris2_sdl3_mixer, mixer.h"
export
prim__loadAudio : AnyPtr -> String -> Int -> PrimIO AnyPtr

%foreign "C:MIX_DestroyAudio, libSDL3_mixer"
export
prim__destroyAudio : AnyPtr -> PrimIO ()

%foreign "C:MIX_GetAudioDuration, libSDL3_mixer"
export
prim__audioDuration : AnyPtr -> PrimIO Int64

%foreign "C:MIX_CreateTrack, libSDL3_mixer"
export
prim__createTrack : AnyPtr -> PrimIO AnyPtr

%foreign "C:MIX_DestroyTrack, libSDL3_mixer"
export
prim__destroyTrack : AnyPtr -> PrimIO ()

%foreign "C:idris_mix_set_audio, libidris2_sdl3_mixer, mixer.h"
export
prim__setTrackAudio : AnyPtr -> AnyPtr -> PrimIO Int

%foreign "C:idris_mix_clear_audio, libidris2_sdl3_mixer, mixer.h"
export
prim__clearTrackAudio : AnyPtr -> PrimIO Int

%foreign "C:idris_mix_play, libidris2_sdl3_mixer, mixer.h"
export
prim__playTrack : AnyPtr -> Bits32 -> PrimIO Int

%foreign "C:idris_mix_stop, libidris2_sdl3_mixer, mixer.h"
export
prim__stopTrack : AnyPtr -> Bits64 -> PrimIO Int

%foreign "C:idris_mix_pause, libidris2_sdl3_mixer, mixer.h"
export
prim__pauseTrack : AnyPtr -> PrimIO Int

%foreign "C:idris_mix_resume, libidris2_sdl3_mixer, mixer.h"
export
prim__resumeTrack : AnyPtr -> PrimIO Int

%foreign "C:idris_mix_playing, libidris2_sdl3_mixer, mixer.h"
export
prim__trackPlaying : AnyPtr -> PrimIO Int

%foreign "C:idris_mix_paused, libidris2_sdl3_mixer, mixer.h"
export
prim__trackPaused : AnyPtr -> PrimIO Int

%foreign "C:idris_mix_set_gain, libidris2_sdl3_mixer, mixer.h"
export
prim__setMixerGain : AnyPtr -> Double -> PrimIO Int

%foreign "C:idris_mix_get_gain, libidris2_sdl3_mixer, mixer.h"
export
prim__getMixerGain : AnyPtr -> PrimIO Double

%foreign "C:idris_mix_set_track_gain, libidris2_sdl3_mixer, mixer.h"
export
prim__setTrackGain : AnyPtr -> Double -> PrimIO Int

%foreign "C:idris_mix_get_track_gain, libidris2_sdl3_mixer, mixer.h"
export
prim__getTrackGain : AnyPtr -> PrimIO Double

%foreign "C:SDL_CreateProperties, libSDL3"
export
prim__newPlayOptions : PrimIO Bits32

%foreign "C:SDL_DestroyProperties, libSDL3"
export
prim__freePlayOptions : Bits32 -> PrimIO ()

%foreign "C:idris_mix_options_loops, libidris2_sdl3_mixer, mixer.h"
export
prim__playLoops : Bits32 -> Int64 -> PrimIO Int

%foreign "C:idris_mix_options_frames, libidris2_sdl3_mixer, mixer.h"
export
prim__playFrames : Bits32 -> Int32 -> Bits64 -> PrimIO Int

%foreign "C:idris_mix_seek, libidris2_sdl3_mixer, mixer.h"
export
prim__seekTrack : AnyPtr -> Bits64 -> PrimIO Int

%foreign "C:MIX_GetTrackPlaybackPosition, libSDL3_mixer"
export
prim__trackPosition : AnyPtr -> PrimIO Int64

%foreign "C:MIX_TrackMSToFrames, libSDL3_mixer"
export
prim__trackMSToFrames : AnyPtr -> Int64 -> PrimIO Int64

%foreign "C:idris_mix_generate, libidris2_sdl3_mixer, mixer.h"
export
prim__generate : AnyPtr -> Buffer -> Bits64 -> Bits32 -> Bits32 -> PrimIO Int32

%foreign "C:MIX_GetNumAudioDecoders, libSDL3_mixer"
export
prim__decoderCount : PrimIO Int32

%foreign "C:MIX_GetAudioDecoder, libSDL3_mixer"
export
prim__decoderName : Int32 -> PrimIO String
