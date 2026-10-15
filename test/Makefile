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

$(addprefix $(NATIVE_BUILD)/,native audio-native subset-native extended-native mixer-native ttf-native): ../cbits/internal.h

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

.PHONY: mixer-native
mixer-native: $(NATIVE_BUILD)/mixer-native $(NATIVE_BUILD)/libidris2_sdl3_test.so
	SDL_AUDIO_DRIVER=dummy ./$(NATIVE_BUILD)/mixer-native

$(NATIVE_BUILD)/mixer-native: mixer_native.c audio_fixtures.c audio_fixtures.h ../cbits/mixer.c ../cbits/mixer.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3-mixer) mixer_native.c audio_fixtures.c \
		../cbits/mixer.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3-mixer)

.PHONY: image-native
image-native: $(NATIVE_BUILD)/image-native $(NATIVE_BUILD)/libidris2_sdl3_image_test.so
	SDL_VIDEODRIVER=dummy ./$(NATIVE_BUILD)/image-native

$(NATIVE_BUILD)/image-native: image_native.c image_fixtures.c image_fixtures.h ../cbits/image.c ../cbits/image.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3-image) image_native.c image_fixtures.c ../cbits/image.c \
		-o $@ $(shell $(PKG_CONFIG) --libs sdl3-image)

$(NATIVE_BUILD)/libidris2_sdl3_image_test.so: image_fixtures.c image_fixtures.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC -shared \
		$(shell $(PKG_CONFIG) --cflags sdl3-image) image_fixtures.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3-image)

.PHONY: ttf-native
ttf-native: $(NATIVE_BUILD)/ttf-native $(NATIVE_BUILD)/libidris2_sdl3_ttf_test.so
	SDL_VIDEODRIVER=dummy ./$(NATIVE_BUILD)/ttf-native

$(NATIVE_BUILD)/ttf-native: ttf_native.c ttf_fixtures.c ttf_fixtures.h ../cbits/ttf.c ../cbits/ttf.h ../cbits/core.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3-ttf) ttf_native.c ttf_fixtures.c ../cbits/ttf.c \
		-o $@ $(shell $(PKG_CONFIG) --libs sdl3-ttf)

$(NATIVE_BUILD)/libidris2_sdl3_ttf_test.so: ttf_fixtures.c ttf_fixtures.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC -shared \
		$(shell $(PKG_CONFIG) --cflags sdl3) ttf_fixtures.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)

.PHONY: clean
clean:
	$(RM) -r $(NATIVE_BUILD)
