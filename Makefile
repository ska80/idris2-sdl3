PACK ?= pack
CG   ?= chez
ROOT := $(CURDIR)

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
test: export LD_LIBRARY_PATH := $(ROOT)/test/build:$(LD_LIBRARY_PATH)
test: all
	$(MAKE) -C test native
	$(RM) test/build/exec/sdl3-test
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIO_DRIVER=dummy \
		$(PACK) --no-prompt --cg=chez run test/test.ipkg


.PHONY: mixer test-mixer example-mixer
mixer: all
	$(PACK) --no-prompt --cg=chez build sdl3-mixer.ipkg

test-mixer: export LD_LIBRARY_PATH := $(ROOT)/test/build:$(LD_LIBRARY_PATH)
test-mixer: mixer
	$(MAKE) -C test mixer-native
	$(RM) test/build/exec/sdl3-mixer-test
	SDL_AUDIO_DRIVER=dummy $(PACK) --no-prompt --cg=chez run test/mixer.ipkg

example-mixer: mixer
	$(PACK) --no-prompt --cg=chez build examples/mixer.ipkg

.PHONY: clean
clean:
	$(PACK) clean examples/hello.ipkg
	$(PACK) clean examples/locking.ipkg
	$(PACK) clean examples/audio.ipkg
	$(PACK) clean test/test.ipkg
	$(PACK) clean sdl3.ipkg
	$(PACK) clean examples/mixer.ipkg
	$(PACK) clean test/mixer.ipkg
	$(PACK) clean sdl3-mixer.ipkg
	$(MAKE) -C cbits clean
	$(MAKE) -C test clean
