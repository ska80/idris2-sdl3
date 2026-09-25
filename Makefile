PACK ?= pack
CG   ?= chez
ROOT := $(CURDIR)

export LD_LIBRARY_PATH := $(ROOT)/cbits:/usr/local/lib:$(LD_LIBRARY_PATH)

ifeq ($(CG),refc)
export LIBRARY_PATH := $(ROOT)/cbits:/usr/local/lib:$(LIBRARY_PATH)
export CPATH := $(ROOT)/cbits:/usr/local/include:$(CPATH)
export IDRIS2_LDLIBS := $(IDRIS2_LDLIBS) -lidris2_sdl3 -lSDL3
endif


.PHONY: all example run run-c
all:
	$(PACK) --no-prompt --cg=$(CG) build sdl3.ipkg

example: all
	$(PACK) --no-prompt --cg=$(CG) build examples/hello.ipkg

run: example
	$(PACK) --no-prompt --cg=$(CG) run examples/hello.ipkg

run-c:
	$(MAKE) run CG=refc


.PHONY: test
test: export LD_LIBRARY_PATH := $(ROOT)/test/build:$(LD_LIBRARY_PATH)
ifeq ($(CG),refc)
test: export LIBRARY_PATH := $(ROOT)/test/build:$(LIBRARY_PATH)
test: export CPATH := $(ROOT)/test:$(CPATH)
test: export IDRIS2_LDLIBS := $(IDRIS2_LDLIBS) -lidris2_sdl3_test
endif
test: all
	$(MAKE) -C test native
	$(RM) -f test/build/exec/sdl3-test
	SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software $(PACK) \
		--no-prompt --cg=$(CG) run test/test.ipkg


.PHONY: clean
clean:
	$(PACK) clean examples/hello.ipkg
	$(PACK) clean test/test.ipkg
	$(PACK) clean sdl3.ipkg
	$(MAKE) -C cbits clean
	$(MAKE) -C test clean
