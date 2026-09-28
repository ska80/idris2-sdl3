#include "audio_fixtures.h"
#include "core.h"

#include <assert.h>
#include <float.h>
#include <math.h>
#include <stdio.h>

static void queue_tests(void) {
    SDL_AudioSpec    spec   = {SDL_AUDIO_S16LE, 2, 8000};
    SDL_AudioStream* stream = SDL_CreateAudioStream(&spec, &spec);

    assert(stream);

    Uint8 input[16] = {0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0};
    Uint8 saved[16], output[16];
    SDL_memcpy(saved, input, sizeof(input));

    assert(idris_sdl_audio_put(stream, input, 16, 1, 4) == 0);
    assert(idris_sdl_audio_put(stream, input, 16, 0, 3) == 0);
    assert(idris_sdl_audio_put(stream, input, 16, 12, 8) == 0);
    assert(idris_sdl_audio_put(stream, input, 16, SDL_MAX_UINT32, 8) == 0);
    assert(idris_sdl_audio_put(stream, input, SDL_MAX_UINT64, 0, 0x80000000u) == 0);
    assert(idris_sdl_audio_put(stream, NULL, 16, 0, 4) == 0);
    assert(SDL_GetAudioStreamQueued(stream) == 0);
    assert(idris_sdl_audio_put(stream, NULL, 0, 0, 0) == 1);
    assert(idris_sdl_audio_put(stream, input, 16, 4, 8) == 1);
    assert(SDL_GetAudioStreamQueued(stream) == 8);

    SDL_memset(input, 255, sizeof(input));

    assert(idris_sdl_audio_flush(stream) == 1);
    assert(SDL_GetAudioStreamData(stream, output, sizeof(output)) == 8);
    assert(SDL_memcmp(output, saved + 4, 8) == 0);
    assert(idris_sdl_audio_clear(stream) == 1);
    assert(SDL_GetAudioStreamQueued(stream) == 0);
    assert(idris_sdl_audio_get_gain(stream) == 1.0);
    assert(idris_sdl_audio_set_gain(stream, 0.25) == 1);
    assert(idris_sdl_audio_get_gain(stream) == 0.25);

    const double bad[] = {-1, NAN, INFINITY, -INFINITY, DBL_MAX};

    for (unsigned i = 0; i < sizeof(bad) / sizeof(bad[0]); ++i) {
        assert(idris_sdl_audio_set_gain(stream, bad[i]) == 0);
        assert(idris_sdl_audio_get_gain(stream) == 0.25);
    }

    SDL_DestroyAudioStream(stream);
}

static void device_tests(void) {
    SDL_AudioStream* music = idris_sdl_audio_open(SDL_AUDIO_S16LE, 1, 8000);
    SDL_AudioStream* sound = idris_sdl_audio_open(SDL_AUDIO_F32LE, 2, 48000);

    assert(music && sound);

    SDL_AudioDeviceID music_id = SDL_GetAudioStreamDevice(music);
    SDL_AudioDeviceID sound_id = SDL_GetAudioStreamDevice(sound);

    assert(music_id && sound_id && music_id != sound_id);
    assert(idris_sdl_audio_paused(music) == 1 && idris_sdl_audio_paused(sound) == 1);

    Uint8 silence[64] = {0};

    assert(idris_sdl_audio_put(music, silence, sizeof(silence), 0, sizeof(silence)) == 1);
    assert(idris_sdl_audio_put(sound, silence, sizeof(silence), 0, sizeof(silence)) == 1);
    assert(SDL_GetAudioStreamQueued(music) == 64 && SDL_GetAudioStreamQueued(sound) == 64);
    assert(idris_sdl_audio_resume(music) == 1);
    assert(idris_sdl_audio_paused(music) == 0 && idris_sdl_audio_paused(sound) == 1);
    assert(SDL_GetAudioStreamQueued(sound) == 64);
    assert(idris_sdl_audio_resume(sound) == 1);
    assert(idris_sdl_audio_pause(music) == 1);
    assert(idris_sdl_audio_paused(music) == 1 && idris_sdl_audio_paused(sound) == 0);

    SDL_DestroyAudioStream(music);

    SDL_AudioSpec spec;

    assert(!SDL_GetAudioDeviceFormat(music_id, &spec, NULL));
    assert(SDL_GetAudioDeviceFormat(sound_id, &spec, NULL));
    assert(idris_sdl_audio_pause(sound) == 1);

    SDL_DestroyAudioStream(sound);

    assert(!SDL_GetAudioDeviceFormat(sound_id, &spec, NULL));
}

static void wav_tests(void) {
    const char* path = idris_test_make_wav();
    assert(path[0]);

    IdrisSDLWAV* wav = idris_sdl_wav_load(path);
    assert(wav && wav->format == SDL_AUDIO_S16LE && wav->channels == 1 && wav->frequency == 8000 && wav->length == 8);

    SDL_AudioSpec    spec   = {SDL_AUDIO_S16LE, 1, 8000};
    SDL_AudioSpec    other  = {SDL_AUDIO_S16LE, 2, 8000};
    SDL_AudioStream* stream = SDL_CreateAudioStream(&spec, &spec);
    SDL_AudioStream* wrong  = SDL_CreateAudioStream(&other, &other);

    assert(stream && wrong);
    assert(idris_sdl_audio_put_wav(wrong, wav, 0, 8) == 0);
    assert(SDL_GetAudioStreamQueued(wrong) == 0);
    assert(idris_sdl_audio_put_wav(stream, NULL, 0, 8) == 0);
    assert(idris_sdl_audio_put_wav(stream, wav, 1, 2) == 0);
    assert(idris_sdl_audio_put_wav(stream, wav, 6, 4) == 0);

    Uint8 expected[4];
    SDL_memcpy(expected, wav->data + 2, 4);

    assert(idris_sdl_audio_put_wav(stream, wav, 2, 4) == 1);

    idris_sdl_wav_free(wav);

    assert(idris_sdl_audio_flush(stream) == 1);

    Uint8 output[4];

    assert(SDL_GetAudioStreamData(stream, output, sizeof(output)) == 4);
    assert(SDL_memcmp(output, expected, 4) == 0);
    assert(SDL_SaveFile(path, "bad", 3));
    assert(idris_sdl_wav_load(path) == NULL);
    assert(remove(path) == 0);
    assert(idris_sdl_wav_load(path) == NULL);

    idris_sdl_wav_free(NULL);

    SDL_DestroyAudioStream(wrong);
    SDL_DestroyAudioStream(stream);
}

int main(void) {
    assert(SDL_Init(SDL_INIT_AUDIO));
    assert(SDL_strcmp(SDL_GetCurrentAudioDriver(), "dummy") == 0);
    assert(idris_sdl_audio_open(0, 1, 8000) == NULL);
    assert(idris_sdl_audio_open(SDL_AUDIO_S16LE, 0, 8000) == NULL);
    assert(idris_sdl_audio_open(SDL_AUDIO_S16LE, 9, 8000) == NULL);
    assert(idris_sdl_audio_open(SDL_AUDIO_S16LE, 1, 0) == NULL);
    assert(idris_sdl_audio_open(SDL_AUDIO_S16LE, 1, SDL_MIN_SINT32) == NULL);
    assert(idris_sdl_audio_put(NULL, NULL, 0, 0, 0) == 0);
    assert(idris_sdl_audio_pause(NULL) == 0);
    assert(idris_sdl_audio_resume(NULL) == 0);
    assert(idris_sdl_audio_clear(NULL) == 0);
    assert(idris_sdl_audio_flush(NULL) == 0);
    assert(idris_sdl_audio_get_gain(NULL) == -1.0);
    assert(idris_sdl_audio_set_gain(NULL, 1.0) == 0);
    assert(SDL_GetAudioStreamQueued(NULL) == -1);

    queue_tests();
    device_tests();
    wav_tests();

    SDL_Quit();

    puts("Native audio tests passed");

    return 0;
}
