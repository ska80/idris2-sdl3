#!/usr/bin/env python3
"""Generate the example's original audio. Requires Python 3 and FFmpeg/libvorbis."""

from array import array
from math import cos, exp, pi, sin
from pathlib import Path
import subprocess
import sys
import tempfile
import wave

RATE = 44100
SECONDS = 32
TAU = 2 * pi
HERE = Path(__file__).resolve().parent


def write_wave(path, samples, channels):
    peak = max(abs(x) for x in samples)
    pcm = array("h", (round(x * 0.65 * 32767 / peak) for x in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(path), "wb") as output:
        output.setnchannels(channels)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())


def bounce():
    # A soft descending chirp with a short bright transient and smooth ends.
    duration = 0.16
    samples = array("f")
    for index in range(round(RATE * duration)):
        t = index / RATE
        envelope = (1 - exp(-t * 1200)) * exp(-t * 38)
        envelope *= min(1, (duration - t) / 0.02)
        phase = TAU * (520 * t - 900 * t * t)
        samples.append(envelope * (sin(phase) + 0.15 * sin(TAU * 1400 * t) * exp(-t * 80)))
    write_wave(HERE / "sound.wav", samples, 1)


def ambient():
    # A C-minor ninth pad, slow stereo motion, detuning, and distant bell pulses.
    # All oscillators and envelopes are periodic over 32 seconds. Quantizing
    # frequencies to whole cycles preserves the waveform at the loop boundary.
    notes = (65.406, 98.0, 130.813, 155.563, 196.0, 233.082, 293.665)
    voices = [(round(hz * SECONDS) / SECONDS, index * 0.73) for index, hz in enumerate(notes)]
    bells = (523.251, 587.33, 622.254, 783.991)
    bells = [(round(hz * SECONDS) / SECONDS, index * pi / 2) for index, hz in enumerate(bells)]
    samples = array("f")
    for index in range(RATE * SECONDS):
        t = index / RATE
        orbit = TAU * t / SECONDS
        left = right = 0.0
        for voice, (hz, phase) in enumerate(voices):
            swell = 0.55 + 0.35 * sin(orbit + phase)
            pan = 0.5 + 0.3 * sin(orbit + phase * 2)
            tone = sin(TAU * hz * t + phase)
            tone += 0.24 * sin(TAU * (hz + 2 / SECONDS) * t - phase)
            tone += 0.08 * sin(TAU * 2 * hz * t + phase)
            tone *= swell / (1 + voice * 0.22)
            left += tone * (1 - pan)
            right += tone * pan
        for hz, phase in bells:
            glow = (0.5 + 0.5 * cos(orbit + phase)) ** 24
            left += 0.14 * glow * sin(TAU * hz * t + phase)
            right += 0.14 * glow * sin(TAU * hz * t + phase + 0.4)
        samples.extend((left, right))
    with tempfile.TemporaryDirectory(prefix="balls-audio-") as directory:
        source = Path(directory) / "music.wav"
        write_wave(source, samples, 2)
        subprocess.run([
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source),
            "-map_metadata", "-1", "-c:a", "libvorbis", "-q:a", "4",
            "-metadata", "title=Orbital drift", "-metadata", "artist=Idris SDL3 balls example",
            str(HERE / "music.ogg"),
        ], check=True)


if __name__ == "__main__":
    bounce()
    ambient()
    print("Generated sound.wav and music.ogg")
