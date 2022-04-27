.PHONY: run

run: emulator
	./emulator hello-world.lua
emulator: main.c Makefile
	gcc  main.c -g -Werror -I/usr/include/lua5.2 -I/usr/include/SDL2/ -llua5.2 -lSDL2 -lSDL2_image -o emulator
