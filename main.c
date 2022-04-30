#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdbool.h>
#include <stdio.h>
#include "static_game_data.h"
#include "engine.c"
#ifdef SDL_BACKEND
#include "sdl_backend.c"
#else
#include "pico_backend.c"
#endif
Cart* c;

int _lua_print() {
    size_t textLen = 0;
    const char* text = luaL_checklstring(L, 1, &textLen);
    const int x = luaL_checkinteger(L, 2);
    const int y = luaL_checkinteger(L, 3);
    const int paletteIdx = luaL_checkinteger(L, 4);

    for (int i = 0; i<textLen; i++) {
	render(&fontsheet, text[i], x + i * 4, y, paletteIdx);
    }
    // render(font, letter_idx, x + letter_count, y);
}

int _lua_pal() {
    int origIdx = luaL_checkinteger(L, 1);
    int newIdx = luaL_checkinteger(L, 2);
    const uint8_t* origColor = palette[origIdx];
    const uint8_t* newColor = original_palette[newIdx];

    memcpy(*(palette + origIdx), newColor, 3*sizeof(uint8_t));
    return 1;
}

int _lua_cls() {
    gfx_cls();
    return 1;
}

int _lua_spr() {
    // TODO: optional w/h/flip_x/flip_y
    int n = luaL_checkinteger(L, 1);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    render(&spritesheet, n, x, y, -1);
    return 1; // 1 = success
}

int _lua_rectfill() {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint8_t w = luaL_checkinteger(L, 3);
    uint8_t h = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);
    uint8_t* newColor = NULL;
    if (col != -1) {
	    *newColor = col;
    }

    gfx_rectfill(x, y, w, h, newColor);
    return 1;
}

int _lua_circfill() {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_checkinteger(L, 3);
    int col = luaL_optinteger(L, 4, -1);

    uint8_t* newColor = NULL;
    if ( col != -1 ) {
	newColor = palette[col];
    }

    gfx_circle(x, y, r, newColor);
    return 1;
}

void registerLuaFunctions() {
    lua_pushcfunction(L, _lua_spr);
    lua_setglobal(L, "spr");
    lua_pushcfunction(L, _lua_cls);
    lua_setglobal(L, "cls");
    lua_pushcfunction(L, _lua_pal);
    lua_setglobal(L, "pal");
    lua_pushcfunction(L, _lua_print);
    lua_setglobal(L, "print");
    lua_pushcfunction(L, _lua_rectfill);
    lua_setglobal(L, "rectfill");
    lua_pushcfunction(L, _lua_circfill);
    lua_setglobal(L, "circfill");
    lua_pushcfunction(L, _lua_btn);
    lua_setglobal(L, "btn");
}

int main( int argc, char* args[] )
{
    if (argc == 1) {
	printf("Usage: %s <file.lua>\n", args[0]);
	return 1;
    }
    if( !init_video() )
    {
	printf( "Failed to initialize video!\n" );
	return 1;
    }

    L = init_lua(examples_hello_world_lua);
    if ( L == NULL ) {
	printf( "Failed to initialize LUA!\n" );
	return 1;
    }
    registerLuaFunctions();

    memset(&fontsheet.sprite_data, 0xFF, 128*120);
    c = cartParser(artifacts_untitled_p8);

    // FIXME: broken on pico
    //fontParser(artifacts_font_lua);
    LCD_Clear(GREEN);

    bool quit = false;
    bool call_update = _lua_fn_exists("_update");
    bool call_draw = _lua_fn_exists("_draw");

    // hexDump(NULL, spritesheet.sprite_data, 128*16, 128);
    quit = false;
    uint64_t frame_start_time;
    uint64_t frame_end_time;
    while (!quit) {
	frame_start_time = now();
	quit = handle_input();
	put_pixel(0, 0, (uint8_t[]){255, 255, 255});
	put_pixel(16, 16, (uint8_t[]){255, 0, 0});
	put_pixel(32, 32, (uint8_t[]){0, 255, 0});
	put_pixel(48, 48, (uint8_t[]){0, 0, 255});
	put_pixel(64, 64, (uint8_t[]){255, 255, 255});
	if (call_update) _to_lua_call("_update");
	if (call_draw) _to_lua_call("_draw");
	gfx_flip();
	frame_end_time = now();
	delay(33 - (frame_end_time - frame_start_time));
    }
    LCD_Clear(RED);

    lua_close(L);
    video_close();
}
