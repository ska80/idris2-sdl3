CC         ?= cc
PKG_CONFIG ?= pkg-config
MKDIR      ?= mkdir
CFLAGS     ?= -O2


.PHONY: native
native: build/native build/audio-native build/subset-native build/libidris2_sdl3_test.so
	SDL_VIDEODRIVER=dummy ./build/native
	SDL_AUDIO_DRIVER=dummy ./build/audio-native
	SDL_VIDEODRIVER=dummy ./build/subset-native

build/native: native.c ../cbits/core.c ../cbits/core.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) native.c \
		../cbits/core.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

build/audio-native: audio_native.c audio_fixtures.c audio_fixtures.h ../cbits/core.c ../cbits/core.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) audio_native.c audio_fixtures.c \
		../cbits/core.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

build/subset-native: subset_native.c subset_fixtures.c subset_fixtures.h ../cbits/core.c ../cbits/core.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) subset_native.c subset_fixtures.c \
		../cbits/core.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

build/libidris2_sdl3_test.so: fixtures.c fixtures.h audio_fixtures.c audio_fixtures.h subset_fixtures.c subset_fixtures.h ../cbits/core.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC -shared \
		$(shell $(PKG_CONFIG) --cflags sdl3) fixtures.c audio_fixtures.c subset_fixtures.c -o $@ \
		$(shell $(PKG_CONFIG) --libs sdl3)


.PHONY: mixer-native
mixer-native: build/mixer-native build/libidris2_sdl3_test.so
	SDL_AUDIO_DRIVER=dummy ./build/mixer-native

build/mixer-native: mixer_native.c audio_fixtures.c audio_fixtures.h ../cbits/mixer.c ../cbits/mixer.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3-mixer) mixer_native.c audio_fixtures.c \
		../cbits/mixer.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3-mixer)

.PHONY: clean
clean:
	$(RM) build/native build/audio-native build/subset-native build/mixer-native build/libidris2_sdl3_test.so
