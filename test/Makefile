CC         ?= cc
PKG_CONFIG ?= pkg-config
MKDIR      ?= mkdir
CFLAGS     ?= -O2


.PHONY: native
native: build/native build/libidris2_sdl3_test.so
	SDL_VIDEODRIVER=dummy ./build/native

build/native: native.c ../cbits/sdl3.c ../cbits/sdl3.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) native.c \
		../cbits/sdl3.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)


build/libidris2_sdl3_test.so: fixtures.c fixtures.h ../cbits/sdl3.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC -shared \
		$(shell $(PKG_CONFIG) --cflags sdl3) fixtures.c -o $@ \
		$(shell $(PKG_CONFIG) --libs sdl3)

.PHONY: clean
clean:
	$(RM) -f build/native build/libidris2_sdl3_test.so
