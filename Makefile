PACK ?= pack
CG   ?= chez

ROOT := $(CURDIR)

PACK_CHEZ = $(PACK) --no-prompt --cg=chez

EXTENSIONS := mixer image ttf
CORE_EXAMPLES := hello locking audio
OPTIONAL_EXAMPLES := mixer media batches
TEST_TARGETS := test $(addprefix test-,$(EXTENSIONS))
PACKAGES := sdl3.ipkg $(addprefix sdl3-,$(addsuffix .ipkg,$(EXTENSIONS))) \
            test/test.ipkg $(addprefix test/,$(addsuffix .ipkg,$(EXTENSIONS))) \
            $(addprefix examples/,$(addsuffix .ipkg,$(CORE_EXAMPLES) $(OPTIONAL_EXAMPLES)))

# Package builds share directories. Separate pack invocations must remain serial.
.NOTPARALLEL:

ifneq ($(CG),chez)
$(error Only the Chez backend is supported)
endif

export LD_LIBRARY_PATH := $(ROOT)/cbits:/usr/local/lib:$(LD_LIBRARY_PATH)
TEST_ENV = SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIO_DRIVER=dummy

.PHONY: all clean example $(EXTENSIONS) $(TEST_TARGETS) \
        $(addprefix run-,$(CORE_EXAMPLES)) $(addprefix example-,$(OPTIONAL_EXAMPLES))
all:
	$(PACK_CHEZ) build sdl3.ipkg

$(EXTENSIONS): all
	$(PACK_CHEZ) build sdl3-$@.ipkg

$(TEST_TARGETS): export LD_LIBRARY_PATH := $(ROOT)/test/native-build:$(LD_LIBRARY_PATH)
test: all
	$(MAKE) -C test native
	$(RM) test/build/exec/sdl3-test
	$(TEST_ENV) $(PACK_CHEZ) run test/test.ipkg

$(addprefix test-,$(EXTENSIONS)): test-%: %
	$(MAKE) -C test $*-native
	$(RM) test/build/exec/sdl3-$*-test
	$(TEST_ENV) $(PACK_CHEZ) run test/$*.ipkg

example: all
	@set -e; for name in $(CORE_EXAMPLES); do $(PACK_CHEZ) build examples/$$name.ipkg; done

$(addprefix run-,$(CORE_EXAMPLES)): run-%: example
	$(PACK_CHEZ) run examples/$*.ipkg

example-mixer: mixer
example-media: image ttf
example-batches: all
$(addprefix example-,$(OPTIONAL_EXAMPLES)): example-%:
	$(PACK_CHEZ) build examples/$*.ipkg

clean:
	@set -e; for package in $(PACKAGES); do $(PACK) --no-prompt clean $$package; done
	$(MAKE) -C cbits clean
	$(MAKE) -C test clean
