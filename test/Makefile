CC         ?= cc
PKG_CONFIG ?= pkg-config
CFLAGS     ?= -O2


.PHONY: native
native: build/native
	SDL_VIDEODRIVER=dummy ./build/native

build/native: native.c ../cbits/sdl3.c ../cbits/sdl3.h
	$(MKDIR) -p build
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -I../cbits \
		$(shell $(PKG_CONFIG) --cflags sdl3) native.c \
		../cbits/sdl3.c -o $@ $(shell $(PKG_CONFIG) --libs sdl3)


.PHONY: clean
clean:
	$(RM) -f build/native
