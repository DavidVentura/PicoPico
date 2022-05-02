.PHONY: run

run: emulator
	./emulator examples/hello-world.lua
run-movement: emulator
	./emulator examples/movement.lua
static_game_data.h: artifacts/font.lua Makefile to_c.py examples/* stdlib/stdlib.lua
	# need to append a null byte at the end..
	python3 to_c.py stdlib/stdlib.lua artifacts/font.lua examples/* > static_game_data.h

emulator: pico_backend.c main.c engine.c parser.c sdl_backend.c Makefile static_game_data.h
	gcc main.c -g -Werror -I/home/david/git/lua/ -I/usr/include/SDL2/ -L/home/david/git/lua -llua -lm -ldl -lSDL2 -o emulator -DSDL_BACKEND
