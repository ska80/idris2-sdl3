#pragma once

#include <SDL3_mixer/SDL_mixer.h>

#define IDRIS_MIXER __attribute__((visibility("default")))

IDRIS_MIXER int        idris_mix_init(void);
IDRIS_MIXER MIX_Mixer* idris_mix_create_device(void);
IDRIS_MIXER MIX_Mixer* idris_mix_create_memory(Uint32 format, Sint32 channels, Sint32 frequency);
IDRIS_MIXER MIX_Audio* idris_mix_load_audio(MIX_Mixer* mixer, const char* path, int predecode);
IDRIS_MIXER int        idris_mix_set_audio(MIX_Track* track, MIX_Audio* audio);
IDRIS_MIXER int        idris_mix_clear_audio(MIX_Track* track);
IDRIS_MIXER int        idris_mix_play(MIX_Track* track, Uint32 options);
IDRIS_MIXER int        idris_mix_stop(MIX_Track* track, Uint64 frames);
IDRIS_MIXER int        idris_mix_pause(MIX_Track* track);
IDRIS_MIXER int        idris_mix_resume(MIX_Track* track);
IDRIS_MIXER int        idris_mix_playing(MIX_Track* track);
IDRIS_MIXER int        idris_mix_paused(MIX_Track* track);
IDRIS_MIXER int        idris_mix_set_gain(MIX_Mixer* mixer, double gain);
IDRIS_MIXER double     idris_mix_get_gain(MIX_Mixer* mixer);
IDRIS_MIXER int        idris_mix_set_track_gain(MIX_Track* track, double gain);
IDRIS_MIXER double     idris_mix_get_track_gain(MIX_Track* track);
IDRIS_MIXER int        idris_mix_options_loops(Uint32 options, Sint64 loops);
IDRIS_MIXER int        idris_mix_options_frames(Uint32 options, Sint32 field, Uint64 frames);
IDRIS_MIXER int        idris_mix_seek(MIX_Track* track, Uint64 frames);
IDRIS_MIXER Sint32     idris_mix_generate(MIX_Mixer* mixer, void* data, Uint64 capacity, Uint32 offset, Uint32 count);
