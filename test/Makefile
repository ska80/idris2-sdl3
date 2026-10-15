CC         ?= cc
PKG_CONFIG ?= pkg-config
MKDIR      ?= mkdir
CFLAGS     ?= -O2

# pack owns build/ and can remove it when the Idris compiler changes.
NATIVE_BUILD := native-build

.PHONY: native
native: $(NATIVE_BUILD)/native $(NATIVE_BUILD)/audio-native $(NATIVE_BUILD)/subset-native $(NATIVE_BUILD)/extended-native $(NATIVE_BUILD)/libidris2_sdl3_test.so
	SDL_VIDEODRIVER=dummy ./$(NATIVE_BUILD)/native
	SDL_AUDIO_DRIVER=dummy ./$(NATIVE_BUILD)/audio-native
	SDL_VIDEODRIVER=dummy ./$(NATIVE_BUILD)/subset-native
	SDL_VIDEODRIVER=dummy ./$(NATIVE_BUILD)/extended-native

$(NATIVE_BUILD):
	$(MKDIR) -p $@

$(addprefix $(NATIVE_BUILD)/,native audio-native subset-native extended-native): ../cbits/internal.h

$(NATIVE_BUILD)/native: native.c ../cbits/core.c ../cbits/core.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) native.c \
		../cbits/core.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

$(NATIVE_BUILD)/audio-native: audio_native.c audio_fixtures.c audio_fixtures.h ../cbits/core.c ../cbits/core.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) audio_native.c audio_fixtures.c \
		../cbits/core.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

$(NATIVE_BUILD)/subset-native: subset_native.c subset_fixtures.c subset_fixtures.h ../cbits/core.c ../cbits/core.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) subset_native.c subset_fixtures.c \
		../cbits/core.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

$(NATIVE_BUILD)/extended-native: extended_native.c ../cbits/core.c ../cbits/core.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) extended_native.c ../cbits/core.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

$(NATIVE_BUILD)/libidris2_sdl3_test.so: fixtures.c fixtures.h audio_fixtures.c audio_fixtures.h subset_fixtures.c subset_fixtures.h extended_fixtures.c extended_fixtures.h ../cbits/core.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC -shared \
		$(shell $(PKG_CONFIG) --cflags sdl3) fixtures.c audio_fixtures.c subset_fixtures.c extended_fixtures.c -o $@ \
		$(shell $(PKG_CONFIG) --libs sdl3)

.PHONY: clean
clean:
	$(RM) -r $(NATIVE_BUILD)
