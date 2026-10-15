PACK ?= pack
CG ?= chez
ARGS ?=

ROOT := $(abspath ../..)
PACK_CHEZ = $(PACK) --no-prompt --cg=chez

# Dependency packages still share build directories in the repository root.
.NOTPARALLEL:

ifneq ($(CG),chez)
$(error Only the Chez backend is supported)
endif

export LD_LIBRARY_PATH := $(ROOT)/cbits:/usr/local/lib:$(LD_LIBRARY_PATH)

.PHONY: all run clean
all:
	$(MAKE) -C "$(ROOT)" PACK="$(PACK)" CG="$(CG)" core $(EXTENSIONS)
	$(PACK_CHEZ) build $(IPKG)

run: all
	./build/exec/$(EXECUTABLE) $(ARGS)

clean:
	$(PACK) --no-prompt clean $(IPKG)
