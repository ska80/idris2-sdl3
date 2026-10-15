PACK   ?= pack
CG     ?= chez
CC     ?= cc
MKDIR  ?= mkdir
CFLAGS ?= -O2

ROOT := $(abspath ../..)

PACK_CHEZ = $(PACK) --no-prompt --cg=chez

IPKG       := $(EXTENSION)-test.ipkg
EXECUTABLE := $(EXTENSION)-test

# Library dependencies still share the repository's pack build directories.
.NOTPARALLEL:

ifneq ($(CG),chez)
$(error Only the Chez backend is supported)
endif

SDL_PACKAGES := $(if $(filter-out clean,$(or $(MAKECMDGOALS),all)),sdl3 sdl3-$(EXTENSION))

include ../../cbits/runtime.mk

# Keep native output outside pack's replaceable build/ directory.
NATIVE_BUILD := native-build
FIXTURE_LIBRARY := libidris2_sdl3_$(EXTENSION)_test.so
FIXTURE_SOURCES ?= fixtures.c
FIXTURE_HEADERS ?= fixtures.h
FIXTURE_PACKAGE ?= sdl3
ADAPTER := ../../cbits/$(EXTENSION)

export LD_LIBRARY_PATH := $(CURDIR)/$(NATIVE_BUILD):$(LD_LIBRARY_PATH)
TEST_ENV = SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIO_DRIVER=dummy

.PHONY: all libraries native run clean
all: libraries $(NATIVE_BUILD)/native $(NATIVE_BUILD)/$(FIXTURE_LIBRARY)
	$(PACK_CHEZ) build $(IPKG)

libraries:
	$(MAKE) -C "$(ROOT)" PACK="$(PACK)" CG="$(CG)" $(EXTENSION)

native: $(NATIVE_BUILD)/native $(NATIVE_BUILD)/$(FIXTURE_LIBRARY)
	$(TEST_ENV) ./$(NATIVE_BUILD)/native

run: all native
	$(TEST_ENV) ./build/exec/$(EXECUTABLE)

$(NATIVE_BUILD):
	$(MKDIR) -p $@

$(NATIVE_BUILD)/native: native.c $(FIXTURE_SOURCES) $(FIXTURE_HEADERS) $(ADAPTER).c $(ADAPTER).h ../../cbits/core.h ../../cbits/internal.h | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../../cbits -I.. \
		$(shell $(PKG_CONFIG) --cflags sdl3-$(EXTENSION)) native.c $(FIXTURE_SOURCES) $(ADAPTER).c \
		-o $@ $(shell $(PKG_CONFIG) --libs sdl3-$(EXTENSION))

$(NATIVE_BUILD)/$(FIXTURE_LIBRARY): $(FIXTURE_SOURCES) $(FIXTURE_HEADERS) | $(NATIVE_BUILD)
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC -shared \
		$(shell $(PKG_CONFIG) --cflags $(FIXTURE_PACKAGE)) $(FIXTURE_SOURCES) -o $@ \
		$(shell $(PKG_CONFIG) --libs $(FIXTURE_PACKAGE))

clean:
	$(PACK) --no-prompt clean $(IPKG)
	$(RM) -r $(NATIVE_BUILD)
