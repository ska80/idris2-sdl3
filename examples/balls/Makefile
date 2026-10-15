IPKG        := balls.ipkg
EXECUTABLE  := balls
EXTENSIONS  := ttf mixer
CLEAN_IPKGS := $(IPKG) tests/balls-test.ipkg

include ../common.mk

.PHONY: test
test: all
	$(PACK_CHEZ) build tests/balls-test.ipkg
	./tests/build/exec/balls-test
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIO_DRIVER=dummy ./build/exec/balls --smoke
