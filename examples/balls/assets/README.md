# Ball example assets

| File | Source and license |
| --- | --- |
| `Lato-Regular.ttf` | Unmodified host copy of `/usr/share/fonts/truetype/lato/Lato-Regular.ttf`, version 2.015. Copyright © 2011–2015 tyPoland Lukasz Dziedzic. SIL Open Font License 1.1 |
| [Lato-LICENSE.txt](Lato-LICENSE.txt) | Copyright notice from the font metadata. Font license text from `/usr/share/doc/fonts-lato/copyright` |
| `sound.wav` | Original synthesized bounce sound. Mono, 44100 Hz, signed 16-bit PCM, 0.16 seconds. [MIT](../../../LICENSE) |
| `music.ogg` | Original synthesized cosmic ambient loop, “Orbital drift.” Stereo, 44100 Hz, Vorbis, 32 seconds. [MIT](../../../LICENSE) |
| `generate.py` | Audio generator. [MIT](../../../LICENSE) |

Font project: <https://www.latofonts.com/>. The font remains under its original license, not MIT.
No third-party recordings or samples were used for the audio.

The music combines slowly changing sine-wave pads, detuned harmonics, stereo motion, and bell tones.
Its frequencies and envelopes repeat over 32 seconds to avoid a gap between loops.
The bounce uses a descending tone with a short transient. Mixer gains keep both assets quiet.

To regenerate both audio files, install Python 3 and FFmpeg with the `libvorbis` encoder, then run:

```sh
python3 examples/balls/assets/generate.py
```

The script overwrites `sound.wav` and `music.ogg` beside itself. It does not change the font.
The PCM synthesis is deterministic. Encoder versions and Ogg stream serial numbers can change
encoded bytes. The checked-in files are ready to use without these generation tools.

Font SHA-256: `6f6940be0835c3ddec9199e5fc42be4cbc61ebcfd58c623fdf719366253f1780`.
