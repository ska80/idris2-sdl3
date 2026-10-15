PACK ?= pack
CG   ?= chez

ROOT := $(CURDIR)

PACK_CHEZ = $(PACK) --no-prompt --cg=chez

EXTENSIONS   := mixer image ttf
TEST_TARGETS := test $(addprefix test-,$(EXTENSIONS))
PACKAGES     := sdl3.ipkg $(addprefix sdl3-,$(addsuffix .ipkg,$(EXTENSIONS))) \
                test/test.ipkg $(addprefix test/,$(addsuffix .ipkg,$(EXTENSIONS)))

# Package builds share directories. Separate pack invocations must remain serial.
.NOTPARALLEL:

ifneq ($(CG),chez)
$(error Only the Chez backend is supported)
endif

# Discover only the SDL packages needed by the requested targets.
BUILD_GOALS := $(filter-out clean,$(or $(MAKECMDGOALS),all))
RUNTIME_EXTENSIONS := $(if $(filter all,$(BUILD_GOALS)),$(EXTENSIONS),\
                          $(filter $(EXTENSIONS),$(patsubst test-%,%,$(BUILD_GOALS))))
SDL_PACKAGES := $(if $(BUILD_GOALS),sdl3 $(addprefix sdl3-,$(RUNTIME_EXTENSIONS)))

include cbits/runtime.mk

TEST_ENV = SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIO_DRIVER=dummy

.PHONY: all core clean $(EXTENSIONS) $(TEST_TARGETS)
all: core $(EXTENSIONS)

core:
	$(PACK_CHEZ) build sdl3.ipkg

$(EXTENSIONS): core
	$(PACK_CHEZ) build sdl3-$@.ipkg

$(TEST_TARGETS): export LD_LIBRARY_PATH := $(ROOT)/test/native-build:$(LD_LIBRARY_PATH)
test: core
	$(MAKE) -C test native
	$(RM) test/build/exec/sdl3-test
	$(TEST_ENV) $(PACK_CHEZ) run test/test.ipkg

$(addprefix test-,$(EXTENSIONS)): test-%: %
	$(MAKE) -C test $*-native
	$(RM) test/build/exec/sdl3-$*-test
	$(TEST_ENV) $(PACK_CHEZ) run test/$*.ipkg

clean:
	@set -e; for package in $(PACKAGES); do $(PACK) --no-prompt clean $$package; done
	$(MAKE) -C cbits clean
	$(MAKE) -C test clean
