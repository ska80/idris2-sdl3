# Callers set ROOT and SDL_PACKAGES. Empty SDL_PACKAGES skips discovery for clean-only runs.
export PKG_CONFIG ?= pkg-config

# Braces keep shell case patterns from closing the make function.
SDL_LIBRARY_PATH := ${shell \
	path=; \
	for package in $(SDL_PACKAGES); do \
		dir=$$($(PKG_CONFIG) --variable=libdir "$$package") || exit 1; \
		test -n "$$dir" || exit 1; \
		case ":$$path:" in *":$$dir:"*) ;; *) path="$${path:+$$path:}$$dir";; esac; \
	done; \
	printf '%s' "$$path"}

ifneq ($(strip $(SDL_PACKAGES)),)
ifeq ($(strip $(SDL_LIBRARY_PATH)),)
$(error Cannot read library directories for $(SDL_PACKAGES) with $(PKG_CONFIG))
endif
endif

# Prefer package-owned adapters over stale copies in the root cbits directory.
# Keep checkout paths with spaces intact.
EXTENSION_LIBRARY_PATH := $(shell \
	for extension in $(patsubst sdl3-%,%,$(filter sdl3-%,$(SDL_PACKAGES))); do \
		printf '%s/%s/cbits:' "$(ROOT)" "$$extension"; \
	done)

export LD_LIBRARY_PATH := $(EXTENSION_LIBRARY_PATH)$(ROOT)/cbits$(if $(SDL_LIBRARY_PATH),:$(SDL_LIBRARY_PATH))$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH))
