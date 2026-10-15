#include "mixer.h"
#include "audio_fixtures.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static void generate(MIX_Mixer* mixer, float* output, Uint32 count) {
    assert(idris_mix_generate(mixer, output, 32 * sizeof(float), 0, count * sizeof(float)) >= 0);
}

static void memory_tests(const char* path) {
    MIX_Mixer* mixer = idris_mix_create_memory(SDL_AUDIO_F32, 1, 8000);
    assert(mixer);
    MIX_Audio* audio = idris_mix_load_audio(mixer, path, 1);
    assert(audio && MIX_GetAudioDuration(audio) == 4);
    MIX_Track* music = MIX_CreateTrack(mixer);
    MIX_Track* sound = MIX_CreateTrack(mixer);
    assert(music && sound);
    assert(!idris_mix_play(music, 0));
    assert(idris_mix_set_audio(music, audio) && idris_mix_set_audio(sound, audio));
    assert(MIX_TrackMSToFrames(music, 1000) == 8000);
    MIX_DestroyAudio(audio); /* Assigned tracks retain it. */
    float output[32];
    assert(idris_mix_play(music, 0));
    generate(mixer, output, 8);
    assert(fabsf(output[1] - 0.125f) < 0.00001f && fabsf(output[2] + 0.125f) < 0.00001f);
    assert(output[4] == 0 && output[7] == 0);
    assert(!idris_mix_playing(music));

    SDL_PropertiesID options = SDL_CreateProperties();
    assert(options && idris_mix_options_loops(options, -1));
    assert(!idris_mix_options_loops(options, -2));
    assert(!idris_mix_options_loops(options, 0x80000000ll));
    assert(!idris_mix_options_frames(options, 0, SDL_MAX_UINT64));
    assert(!idris_mix_options_frames(options, 9, 0));
    assert(idris_mix_play(music, options));
    assert(idris_mix_play(sound, options));
    SDL_DestroyProperties(options); /* Playback does not retain properties. */
    assert(idris_mix_set_track_gain(music, 0.25) && idris_mix_set_track_gain(sound, 0.25));
    assert(idris_mix_set_gain(mixer, 0.5));
    generate(mixer, output, 8);
    assert(fabsf(output[1] - 0.03125f) < 0.00001f);
    assert(idris_mix_playing(music) && idris_mix_playing(sound));
    assert(idris_mix_pause(music));
    assert(!idris_mix_playing(music) && idris_mix_paused(music));
    assert(idris_mix_playing(sound));
    const Sint64 paused_position = MIX_GetTrackPlaybackPosition(music);
    assert(idris_mix_stop(music, 4));
    generate(mixer, output, 8);
    assert(idris_mix_paused(music));
    assert(MIX_GetTrackPlaybackPosition(music) == paused_position);
    assert(idris_mix_resume(music));
    assert(!idris_mix_paused(music));
    assert(idris_mix_stop(sound, 0));
    assert(idris_mix_playing(music) && !idris_mix_playing(sound));
    assert(!idris_mix_set_track_gain(music, -1));
    assert(!idris_mix_set_track_gain(music, NAN));
    assert(!idris_mix_set_gain(mixer, INFINITY));
    assert(!idris_mix_set_gain(mixer, 1.0e300));
    assert(idris_mix_get_track_gain(music) == 0.25 && idris_mix_get_gain(mixer) == 0.5);
    assert(!idris_mix_stop(music, SDL_MAX_UINT64));
    assert(!idris_mix_seek(music, SDL_MAX_UINT64));
    assert(idris_mix_stop(music, 4));
    generate(mixer, output, 16);
    assert(!idris_mix_playing(music));
    assert(output[1] > 0 && output[1] < 0.015625f && output[4] == 0);

    options = SDL_CreateProperties();
    assert(idris_mix_options_frames(options, 0, 1));
    assert(idris_mix_options_frames(options, 1, 1));
    assert(idris_mix_options_frames(options, 2, 4));
    assert(idris_mix_play(music, options));
    assert(MIX_GetTrackPlaybackPosition(music) == 1);
    generate(mixer, output, 8);
    assert(fabsf(output[0]) < 0.00001f);
    assert(!idris_mix_playing(music));
    SDL_DestroyProperties(options);

    memset(output, 0x5a, sizeof(output));
    float original[32];
    memcpy(original, output, sizeof(output));
    assert(idris_mix_generate(mixer, output, sizeof(output), 1, 4) == -1);
    assert(idris_mix_generate(mixer, output, sizeof(output), 0, 3) == -1);
    assert(idris_mix_generate(mixer, output, sizeof(output), 124, 8) == -1);
    assert(idris_mix_generate(mixer, output, sizeof(output), 0, 0x80000000u) == -1);
    assert(memcmp(original, output, sizeof(output)) == 0);
    assert(idris_mix_generate(mixer, output, sizeof(output), 4, 4) == 0);
    assert(output[1] == 0 && memcmp(original, output, 4) == 0 && memcmp(original + 2, output + 2, 4) == 0);
    assert(idris_mix_clear_audio(music));
    assert(!idris_mix_play(music, 0));
    MIX_DestroyTrack(sound);
    MIX_DestroyTrack(music);
    MIX_DestroyMixer(mixer);
}

static void device_tests(const char* path) {
    MIX_Mixer* mixer = idris_mix_create_device();
    assert(mixer);
    SDL_AudioDeviceID device = (SDL_AudioDeviceID)SDL_GetNumberProperty(MIX_GetMixerProperties(mixer), MIX_PROP_MIXER_DEVICE_NUMBER, 0);
    assert(device);
    MIX_Audio* audio = idris_mix_load_audio(mixer, path, 0);
    MIX_Track* track = MIX_CreateTrack(mixer);
    assert(audio && track && idris_mix_set_audio(track, audio));
    SDL_PropertiesID options = SDL_CreateProperties();
    assert(idris_mix_options_loops(options, -1));
    assert(idris_mix_play(track, options));
    assert(idris_mix_pause(track) && idris_mix_paused(track));
    assert(idris_mix_resume(track));
    assert(idris_mix_stop(track, 0));
    float output[32];
    assert(idris_mix_generate(mixer, output, sizeof(output), 0, sizeof(output)) == -1);
    SDL_DestroyProperties(options);
    MIX_DestroyTrack(track);
    MIX_DestroyAudio(audio);
    MIX_DestroyMixer(mixer);
    SDL_AudioSpec spec;
    assert(!SDL_GetAudioDeviceFormat(device, &spec, NULL));
}

int main(void) {
    assert(idris_mix_init());
    assert(idris_mix_init()); /* Reference-counted initialization. */
    MIX_Quit();
    assert(MIX_GetNumAudioDecoders() > 0);
    assert(!idris_mix_create_memory(SDL_AUDIO_F32, 0, 8000));
    assert(!idris_mix_create_memory(SDL_AUDIO_F32, 1, 0));
    assert(!idris_mix_load_audio(NULL, "/nonexistent/idris-mixer-test", 1));
    assert(!idris_mix_pause(NULL) && !idris_mix_resume(NULL) && !idris_mix_stop(NULL, 0));
    const char* path = idris_test_make_wav();
    assert(path[0]);
    memory_tests(path);
    device_tests(path);
    assert(unlink(path) == 0);
    MIX_Quit();
    SDL_Quit();
    puts("Mixer native tests passed");
    return 0;
}
