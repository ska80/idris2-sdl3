PACK ?= pack
CG   ?= chez
ROOT := $(CURDIR)

# NOTE: The Idris packages share build directories. Keep pack invocations serial.
.NOTPARALLEL:

ifneq ($(CG),chez)
$(error Only the Chez backend is supported)
endif

export LD_LIBRARY_PATH := $(ROOT)/cbits:/usr/local/lib:$(LD_LIBRARY_PATH)

.PHONY: all
all:
	$(PACK) --no-prompt --cg=chez build sdl3.ipkg


.PHONY: example
example: all
	$(PACK) --no-prompt --cg=chez build examples/hello.ipkg
	$(PACK) --no-prompt --cg=chez build examples/locking.ipkg
	$(PACK) --no-prompt --cg=chez build examples/audio.ipkg

.PHONY: run-hello run-locking run-audio
run-hello: example
	$(PACK) --no-prompt --cg=chez run examples/hello.ipkg

run-locking: example
	$(PACK) --no-prompt --cg=chez run examples/locking.ipkg

run-audio: example
	$(PACK) --no-prompt --cg=chez run examples/audio.ipkg


.PHONY: test
test: export LD_LIBRARY_PATH := $(ROOT)/test/native-build:$(LD_LIBRARY_PATH)
test: all
	$(MAKE) -C test native
	$(RM) test/build/exec/sdl3-test
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIO_DRIVER=dummy \
		$(PACK) --no-prompt --cg=chez run test/test.ipkg


.PHONY: mixer test-mixer example-mixer
mixer: all
	$(PACK) --no-prompt --cg=chez build sdl3-mixer.ipkg

test-mixer: export LD_LIBRARY_PATH := $(ROOT)/test/native-build:$(LD_LIBRARY_PATH)
test-mixer: mixer
	$(MAKE) -C test mixer-native
	$(RM) test/build/exec/sdl3-mixer-test
	SDL_AUDIO_DRIVER=dummy $(PACK) --no-prompt --cg=chez run test/mixer.ipkg

example-mixer: mixer
	$(PACK) --no-prompt --cg=chez build examples/mixer.ipkg

.PHONY: image test-image
image: all
	$(PACK) --no-prompt --cg=chez build sdl3-image.ipkg

test-image: export LD_LIBRARY_PATH := $(ROOT)/test/native-build:$(LD_LIBRARY_PATH)
test-image: image
	$(MAKE) -C test image-native
	$(RM) test/build/exec/sdl3-image-test
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software $(PACK) --no-prompt --cg=chez run test/image.ipkg

.PHONY: ttf test-ttf
ttf: all
	$(PACK) --no-prompt --cg=chez build sdl3-ttf.ipkg

test-ttf: export LD_LIBRARY_PATH := $(ROOT)/test/native-build:$(LD_LIBRARY_PATH)
test-ttf: ttf
	$(MAKE) -C test ttf-native
	$(RM) test/build/exec/sdl3-ttf-test
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software $(PACK) --no-prompt --cg=chez run test/ttf.ipkg

.PHONY: example-media example-batches
example-media: image ttf
	$(PACK) --no-prompt --cg=chez build examples/media.ipkg

example-batches: all
	$(PACK) --no-prompt --cg=chez build examples/batches.ipkg

.PHONY: clean
clean:
	$(PACK) --no-prompt clean examples/hello.ipkg
	$(PACK) --no-prompt clean examples/locking.ipkg
	$(PACK) --no-prompt clean examples/audio.ipkg
	$(PACK) --no-prompt clean examples/media.ipkg
	$(PACK) --no-prompt clean examples/batches.ipkg
	$(PACK) --no-prompt clean test/test.ipkg
	$(PACK) --no-prompt clean sdl3.ipkg
	$(PACK) --no-prompt clean examples/mixer.ipkg
	$(PACK) --no-prompt clean test/mixer.ipkg
	$(PACK) --no-prompt clean sdl3-mixer.ipkg
	$(PACK) --no-prompt clean test/image.ipkg
	$(PACK) --no-prompt clean sdl3-image.ipkg
	$(PACK) --no-prompt clean test/ttf.ipkg
	$(PACK) --no-prompt clean sdl3-ttf.ipkg
	$(MAKE) -C cbits clean
	$(MAKE) -C test clean
