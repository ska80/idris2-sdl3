CC         ?= cc
PKG_CONFIG ?= pkg-config
CFLAGS     ?= -O2 -std=c2x -fvisibility=hidden -pedantic -Wall -Wextra -Werror
CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags sdl3)
LDLIBS     += $(shell $(PKG_CONFIG) --libs sdl3)


.PHONY: all
all: libidris2_sdl3.so

libidris2_sdl3.so: core.c core.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -shared -o $@ core.c $(LDFLAGS) $(LDLIBS)


.PHONY: mixer
mixer: libidris2_sdl3_mixer.so

libidris2_sdl3_mixer.so: mixer.c mixer.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(shell $(PKG_CONFIG) --cflags sdl3-mixer) -fPIC -shared -o $@ mixer.c \
		$(LDFLAGS) $(shell $(PKG_CONFIG) --libs sdl3-mixer)

.PHONY: image
image: libidris2_sdl3_image.so

libidris2_sdl3_image.so: image.c image.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(shell $(PKG_CONFIG) --cflags sdl3-image) -fPIC -shared -o $@ image.c \
		$(LDFLAGS) $(shell $(PKG_CONFIG) --libs sdl3-image)

.PHONY: ttf
ttf: libidris2_sdl3_ttf.so

libidris2_sdl3_ttf.so: ttf.c ttf.h core.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(shell $(PKG_CONFIG) --cflags sdl3-ttf) -fPIC -shared -o $@ ttf.c \
		$(LDFLAGS) $(shell $(PKG_CONFIG) --libs sdl3-ttf)

.PHONY: clean
clean:
	$(RM) libidris2_sdl3.so libidris2_sdl3_mixer.so libidris2_sdl3_image.so libidris2_sdl3_ttf.so
