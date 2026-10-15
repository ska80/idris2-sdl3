PACK        ?= pack
CG          ?= chez
ARGS        ?=
CLEAN_IPKGS ?= $(IPKG)

ROOT := $(abspath ../..)

PACK_CHEZ = $(PACK) --no-prompt --cg=chez

# Dependency packages still share build directories in the repository root.
.NOTPARALLEL:

ifneq ($(CG),chez)
$(error Only the Chez backend is supported)
endif

SDL_PACKAGES := $(if $(filter-out clean,$(or $(MAKECMDGOALS),all)),sdl3 $(addprefix sdl3-,$(EXTENSIONS)))

include ../../cbits/runtime.mk

.PHONY: all run clean
all:
	$(MAKE) -C "$(ROOT)" PACK="$(PACK)" CG="$(CG)" core $(EXTENSIONS)
	$(PACK_CHEZ) build $(IPKG)

run: all
	./build/exec/$(EXECUTABLE) $(ARGS)

clean:
	for package in $(CLEAN_IPKGS); do \
		$(PACK) --no-prompt clean "$$package" || exit $$?; \
	done
