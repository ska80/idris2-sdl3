CC         ?= cc
PKG_CONFIG ?= pkg-config
CFLAGS     ?= -O2 -std=c2x -fvisibility=hidden -pedantic -Wall -Wextra -Werror
CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags sdl3)
LDLIBS     += $(shell $(PKG_CONFIG) --libs sdl3)

.PHONY: all clean
all: libidris2_sdl3.so

libidris2_sdl3.so: core.c core.h internal.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -shared -o $@ core.c $(LDFLAGS) $(LDLIBS)

# Remove extension adapters left by the former shared output directory too.
clean:
	$(RM) libidris2_sdl3.so libidris2_sdl3_*.so
