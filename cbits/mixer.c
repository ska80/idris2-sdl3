#include "mixer.h"
#include <float.h>

_Static_assert(sizeof(int) == sizeof(Sint32), "Mixer requires 32-bit C int");
_Static_assert(MIX_DURATION_UNKNOWN == -1 && MIX_DURATION_INFINITE == -2, "Mixer duration codes changed");

int idris_mix_init(void) { return MIX_Init(); }
MIX_Mixer* idris_mix_create_device(void) {
    return MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, NULL);
}
MIX_Mixer* idris_mix_create_memory(Uint32 format, Sint32 channels, Sint32 frequency) {
    if (channels < 1 || channels > 8 || frequency <= 0) {
        SDL_SetError("Mixer output requires 1 to 8 channels and a positive sample rate");
        return NULL;
    }
    SDL_AudioSpec spec = {(SDL_AudioFormat)format, channels, frequency};
    return MIX_CreateMixer(&spec);
}
MIX_Audio* idris_mix_load_audio(MIX_Mixer* mixer, const char* path, int predecode) {
    return MIX_LoadAudio(mixer, path, predecode != 0);
}
int idris_mix_set_audio(MIX_Track* track, MIX_Audio* audio) { return MIX_SetTrackAudio(track, audio); }
int idris_mix_clear_audio(MIX_Track* track) { return MIX_SetTrackAudio(track, NULL); }
int idris_mix_play(MIX_Track* track, Uint32 options) { return MIX_PlayTrack(track, options); }
int idris_mix_stop(MIX_Track* track, Uint64 frames) {
    if (frames > SDL_MAX_SINT64) return SDL_SetError("Mixer fade frames exceed signed 64-bit range");
    return MIX_StopTrack(track, (Sint64)frames);
}
int idris_mix_pause(MIX_Track* track) { return MIX_PauseTrack(track); }
int idris_mix_resume(MIX_Track* track) { return MIX_ResumeTrack(track); }
int idris_mix_playing(MIX_Track* track) { return MIX_TrackPlaying(track); }
int idris_mix_paused(MIX_Track* track) { return MIX_TrackPaused(track); }
static int valid_gain(double gain) {
    if (!(gain >= 0.0 && gain <= FLT_MAX)) return SDL_SetError("Mixer gain must be finite, nonnegative, and fit a float");
    return 1;
}
int idris_mix_set_gain(MIX_Mixer* mixer, double gain) {
    return valid_gain(gain) && MIX_SetMixerGain(mixer, (float)gain);
}
double idris_mix_get_gain(MIX_Mixer* mixer) { return MIX_GetMixerGain(mixer); }
int idris_mix_set_track_gain(MIX_Track* track, double gain) {
    return valid_gain(gain) && MIX_SetTrackGain(track, (float)gain);
}
double idris_mix_get_track_gain(MIX_Track* track) { return MIX_GetTrackGain(track); }
int idris_mix_options_loops(Uint32 options, Sint64 loops) {
    if (loops < -1 || loops > SDL_MAX_SINT32) return SDL_SetError("Mixer loop count must be -1 or fit a nonnegative C int");
    return SDL_SetNumberProperty(options, MIX_PROP_PLAY_LOOPS_NUMBER, loops);
}
int idris_mix_options_frames(Uint32 options, Sint32 field, Uint64 frames) {
    if (frames > SDL_MAX_SINT64) return SDL_SetError("Mixer play frames exceed signed 64-bit range");
    const char* name;
    switch (field) {
    case 0: name = MIX_PROP_PLAY_START_FRAME_NUMBER; break;
    case 1: name = MIX_PROP_PLAY_LOOP_START_FRAME_NUMBER; break;
    case 2: name = MIX_PROP_PLAY_FADE_IN_FRAMES_NUMBER; break;
    default: return SDL_SetError("Unknown mixer play option");
    }
    return SDL_SetNumberProperty(options, name, (Sint64)frames);
}
int idris_mix_seek(MIX_Track* track, Uint64 frames) {
    if (frames > SDL_MAX_SINT64) return SDL_SetError("Mixer seek frames exceed signed 64-bit range");
    return MIX_SetTrackPlaybackPosition(track, (Sint64)frames);
}
Sint32 idris_mix_generate(MIX_Mixer* mixer, void* data, Uint64 capacity, Uint32 offset, Uint32 count) {
    SDL_AudioSpec spec;
    if (!MIX_GetMixerFormat(mixer, &spec)) return -1;
    const int frame_bytes = SDL_AUDIO_FRAMESIZE(spec);
    if (frame_bytes <= 0 || !data || count > SDL_MAX_SINT32 ||
        (Uint64)offset + count > capacity || (Uint64)offset + count > SIZE_MAX ||
        offset % (Uint32)frame_bytes || count % (Uint32)frame_bytes) {
        SDL_SetError("Mixer output range must fit the buffer and contain aligned whole frames");
        return -1;
    }
    return MIX_Generate(mixer, (Uint8*)data + offset, (int)count);
}
