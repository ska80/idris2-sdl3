PACK ?= pack
CG   ?= chez
ROOT := $(CURDIR)

ifneq ($(CG),chez)
$(error Only the Chez backend is supported)
endif

export LD_LIBRARY_PATH := $(ROOT)/cbits:/usr/local/lib:$(LD_LIBRARY_PATH)

.PHONY: all example run
all:
	$(PACK) --no-prompt --cg=chez build sdl3.ipkg

example: all
	$(PACK) --no-prompt --cg=chez build examples/hello.ipkg

run: example
	$(PACK) --no-prompt --cg=chez run examples/hello.ipkg


.PHONY: test
test: export LD_LIBRARY_PATH := $(ROOT)/test/build:$(LD_LIBRARY_PATH)
test: all
	$(MAKE) -C test native
	$(RM) -f test/build/exec/sdl3-test
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software \
		$(PACK) --no-prompt --cg=chez run test/test.ipkg


.PHONY: clean
clean:
	$(PACK) clean examples/hello.ipkg
	$(PACK) clean test/test.ipkg
	$(PACK) clean sdl3.ipkg
	$(MAKE) -C cbits clean
	$(MAKE) -C test clean
