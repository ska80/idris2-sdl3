# SDL header references

Unmodified copies of the installed header directories under `/usr/local/include`, captured on
2026-10-15.  Reference only. Builds still use installed headers and libraries through pkg-config.

| Directory | Header / pkg-config version | pkg-config package | Upstream |
| --- | --- | --- | --- |
| [SDL3](SDL3) | 3.4.16 | `sdl3` | [SDL](https://github.com/libsdl-org/SDL) |
| [SDL3_image](SDL3_image) | 3.4.6 | `sdl3-image` | [SDL_image](https://github.com/libsdl-org/SDL_image) |
| [SDL3_mixer](SDL3_mixer) | 3.2.4 | `sdl3-mixer` | [SDL_mixer](https://github.com/libsdl-org/SDL_mixer) |
| [SDL3_ttf](SDL3_ttf) | 3.2.2 | `sdl3-ttf` | [SDL_ttf](https://github.com/libsdl-org/SDL_ttf) |

- Versions match the `*_MAJOR_VERSION`, `*_MINOR_VERSION`, and `*_MICRO_VERSION` macros and
  installed pkg-config metadata.
- SDL revision: `SDL-3.4.16-HEAD-HASH-NOTFOUND`. The installation does not identify its source
  commit.
- These copies include headers for unbound APIs. They do not define binding coverage or [minimum
  supported versions](../docs/build.md#requirements).
- Preserve upstream contents, formatting, and license notices. Some headers contain third-party
  notices.

## Integrity and updates

[SHA256SUMS](SHA256SUMS) records a SHA-256 checksum for each header to detect byte changes.  From
the repository root:

```sh
(cd vendor && sha256sum -c SHA256SUMS)
```

1. Replace complete header directories from the installed SDK. Do not merge copies that leave
   removed headers behind.
2. Match header versions against `pkg-config --modversion sdl3 sdl3-image sdl3-mixer sdl3-ttf`.
3. Update the table, capture date, and revision above. Regenerate checksums from the repository
   root:

```sh
(cd vendor && find SDL3 SDL3_image SDL3_mixer SDL3_ttf -type f -name '*.h' -print0 |
  LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS)
```

Run the [build and test checks](../docs/build.md#targets-and-tests) after updating the bindings.
