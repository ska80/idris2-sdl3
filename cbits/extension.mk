# Included from each extension's cbits/Makefile.
CC         ?= cc
PKG_CONFIG ?= pkg-config
CFLAGS     ?= -O2 -std=c2x -fvisibility=hidden -pedantic -Wall -Wextra -Werror
CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags sdl3-$(EXTENSION))
LDLIBS     += $(shell $(PKG_CONFIG) --libs sdl3-$(EXTENSION))

LIBRARY := libidris2_sdl3_$(EXTENSION).so

.PHONY: all clean
all: $(LIBRARY)

$(LIBRARY): $(EXTENSION).c $(EXTENSION).h ../../cbits/core.h ../../cbits/internal.h
	$(CC) -I../../cbits $(CPPFLAGS) $(CFLAGS) -fPIC -shared -o $@ $(EXTENSION).c $(LDFLAGS) $(LDLIBS)

clean:
	$(RM) $(LIBRARY)
