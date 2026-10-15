CC         ?= cc
PKG_CONFIG ?= pkg-config
CFLAGS     ?= -O2 -std=c2x -fvisibility=hidden -pedantic -Wall -Wextra -Werror
CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags sdl3)
LDLIBS     += $(shell $(PKG_CONFIG) --libs sdl3)

EXTENSIONS := mixer image ttf

.PHONY: all clean $(EXTENSIONS)
all: libidris2_sdl3.so

libidris2_sdl3.so: core.c core.h internal.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -shared -o $@ core.c $(LDFLAGS) $(LDLIBS)

$(EXTENSIONS): %: libidris2_sdl3_%.so

libidris2_sdl3_%.so: %.c %.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(shell $(PKG_CONFIG) --cflags sdl3-$*) -fPIC -shared -o $@ $*.c \
		$(LDFLAGS) $(shell $(PKG_CONFIG) --libs sdl3-$*)

libidris2_sdl3_mixer.so libidris2_sdl3_ttf.so: internal.h
libidris2_sdl3_ttf.so: core.h

clean:
	$(RM) libidris2_sdl3.so $(addprefix libidris2_sdl3_,$(addsuffix .so,$(EXTENSIONS)))
