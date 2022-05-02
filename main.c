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

int _lua_print(lua_State* L) {
    size_t textLen = 0;
    const char* text = luaL_checklstring(L, 1, &textLen);
    const int x = luaL_checkinteger(L, 2);
    const int y = luaL_checkinteger(L, 3);
    const int paletteIdx = luaL_checkinteger(L, 4);

    for (int i = 0; i<textLen; i++) {
	render(&fontsheet, text[i], x + i * 4, y, paletteIdx);
    }
    // FIXME: this only works for ascii
    return 0;
}

int _lua_pal(lua_State* L) {
    int origIdx = luaL_checkinteger(L, 1);
    int newIdx = luaL_checkinteger(L, 2);
    const uint8_t* origColor = palette[origIdx];
    const uint8_t* newColor = original_palette[newIdx];

    memcpy(*(palette + origIdx), newColor, 3*sizeof(uint8_t));
    return 0;
}

int _lua_cls(lua_State* L) {
    uint8_t palIdx = luaL_optinteger(L, 1, 0);
    uint8_t* color = palette[palIdx];
    gfx_cls(color);
    return 0;
}

int _lua_sspr(lua_State* L) {
    // TODO: optional w/h/flip_x/flip_y
    // sspr( sx, sy, sw, sh, dx, dy, [dw,] [dh,] [flip_x,] [flip_y] )
    int sx = luaL_optinteger(L, 1, 0);
    int sy = luaL_checkinteger(L, 2);
    int sw = luaL_checkinteger(L, 3);
    int sh = luaL_checkinteger(L, 4);
    int dx = luaL_checkinteger(L, 5);
    int dy = luaL_checkinteger(L, 6);
    int dw = luaL_optinteger(L, 7, sw);
    int dh = luaL_optinteger(L, 8, sh);
    render_stretched(&spritesheet, sx, sy, sw, sh, dx, dy, dw, dh);
    return 0; // 1 = success
}

int _lua_spr(lua_State* L) {
    // TODO: optional w/h/flip_x/flip_y
    int n = luaL_checkinteger(L, 1);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    render(&spritesheet, n, x, y, -1);
    return 0; // 1 = success
}

int _lua_line(lua_State* L) {
    //TODO: handle all cases https://pico-8.fandom.com/wiki/Line
    uint8_t x0 = luaL_optinteger(L, 1, drawstate.line_x);
    uint8_t y0 = luaL_optinteger(L, 2, drawstate.line_y);
    uint8_t x1 = luaL_optinteger(L, 3, 0);
    uint8_t y1 = luaL_optinteger(L, 4, 0);
    int col = luaL_optinteger(L, 5, -1);
    uint8_t* newColor = NULL;
    if (col != -1) {
	    // FIXME ??
	    newColor = palette[col];
    }

    drawstate.line_x = x1;
    drawstate.line_y = y1;
    gfx_line(x0, y0, x1, y1, newColor);
    return 0;
}

int _lua_rect(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint8_t w = luaL_checkinteger(L, 3);
    uint8_t h = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);
    uint8_t* newColor = NULL;
    if (col != -1) {
	    newColor = palette[col];
    }

    gfx_rect(x, y, w-x+1, h-y+1, newColor);
    return 0;
}

int _lua_rectfill(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint8_t w = luaL_checkinteger(L, 3);
    uint8_t h = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);
    uint8_t* newColor = NULL;
    if (col != -1) {
	    newColor = palette[col];
    }

    gfx_rectfill(x, y, w, h, newColor);
    return 0;
}

int _lua_circfill(lua_State* L) {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_checkinteger(L, 3);
    int col = luaL_optinteger(L, 4, -1);

    uint8_t* newColor = NULL;
    if ( col != -1 ) {
	newColor = palette[col];
    } else {
        // newColor = RED;
    }

    // gfx_circlefill(x, y, r, newColor);
    return 0;
}

int _lua_map(lua_State* L) {
    int mapX = luaL_checkinteger(L, 1);
    int mapY = luaL_checkinteger(L, 2);
    int screenX = luaL_checkinteger(L, 3);
    int screenY = luaL_checkinteger(L, 4);
    int cellW = luaL_checkinteger(L, 5);
    int cellH = luaL_checkinteger(L, 6);
    int layerFlags = luaL_optinteger(L, 7, 0xF);

    gfx_map(mapX, mapY, screenX, screenY, cellW, cellH, layerFlags);
    //printf("mx %d, my: %d, sx %d, sy: %d, cw: %d, ch: %d, fl %d\n", mapX, mapY, screenX, screenY, cellW, cellH, layerFlags);
    return 0;
}

int _lua_camera(lua_State* L) {
    int x = luaL_optinteger(L, 1, 0xFFFF);
    int y = luaL_optinteger(L, 2, 0xFFFF);

    if (x != 0xFFFF)
	    drawstate.camera_x = x;

    if (y != 0xFFFF)
	    drawstate.camera_y = y;
    return 0;
}
int _lua_btnp(lua_State* L) {
	// FIXME this is just _btn
    int idx = luaL_checkinteger(L, 1);
    // printf("Button state for %d is %d\n", idx, buttons[idx]);
    lua_pushboolean(L, buttons[idx]);
    return 1;
}
int _lua_btn(lua_State* L) {
    int idx = luaL_checkinteger(L, 1);
    lua_pushboolean(L, buttons[idx]);
    return 1;
}
int _lua_rnd(lua_State* L) {
    if(lua_istable(L, 1)) {
	    printf("rnd for table not implemented\n");
	    return 1;
    }
    int limit = luaL_optinteger(L, 1, 1);
    float x = (float)rand()/(float)(RAND_MAX/limit);
    lua_pushnumber(L, x);
    return 1;
}
int _lua_pget(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint16_t p = get_pixel(x, y);
    lua_pushinteger(L, p);
    return 1;
}

int _lua_flr(lua_State* L) {
    float val = luaL_checknumber(L, 1);
    lua_pushinteger(L, (uint16_t)val);
    return 1;
}

int _lua_time(lua_State* L) {
    float delta = ((float)(now() - bootup_time))/1000;
    lua_pushnumber(L, delta);
    return 1;
}

int _lua_abs(lua_State* L) {
    float val = luaL_checknumber(L, 1);
    lua_pushinteger(L, abs(val));
    return 1;
}

int _lua_printh(lua_State* L) {
    const char* val = luaL_checkstring(L, 1);
    printf("> %s\n", val);
    return 0;
}

int _lua_sfx(lua_State* L) {
	// TODO: implement
    return 0;
}

void registerLuaFunctions() {
    lua_pushcfunction(L, _lua_spr);
    lua_setglobal(L, "spr");
    lua_pushcfunction(L, _lua_sspr);
    lua_setglobal(L, "sspr");
    lua_pushcfunction(L, _lua_cls);
    lua_setglobal(L, "cls");
    lua_pushcfunction(L, _lua_pal);
    lua_setglobal(L, "pal");
    lua_pushcfunction(L, _lua_print);
    lua_setglobal(L, "print");
    lua_pushcfunction(L, _lua_rectfill);
    lua_setglobal(L, "rectfill");
    lua_pushcfunction(L, _lua_rect);
    lua_setglobal(L, "rect");
    lua_pushcfunction(L, _lua_line);
    lua_setglobal(L, "line");
    lua_pushcfunction(L, _lua_circfill);
    lua_setglobal(L, "circfill");
    lua_pushcfunction(L, _lua_btn);
    lua_setglobal(L, "btn");
    lua_pushcfunction(L, _lua_btnp);
    lua_setglobal(L, "btnp");
    lua_pushcfunction(L, _lua_map);
    lua_setglobal(L, "map");
    lua_pushcfunction(L, _lua_rnd);
    lua_setglobal(L, "rnd");
    lua_pushcfunction(L, _lua_flr);
    lua_setglobal(L, "flr");
    lua_pushcfunction(L, _lua_pget);
    lua_setglobal(L, "pget");
    lua_pushcfunction(L, _lua_time);
    lua_setglobal(L, "time");
    lua_pushcfunction(L, _lua_abs);
    lua_setglobal(L, "abs");
    lua_pushcfunction(L, _lua_sfx);
    lua_setglobal(L, "sfx");
    lua_pushcfunction(L, _lua_printh);
    lua_setglobal(L, "printh");
}

int main( int argc, char* args[] )
{
    if( !init_video() )
    {
	printf( "Failed to initialize video!\n" );
	return 1;
    }

    engine_init();
    // cartParser(examples_map_p8);
    cartParser(examples_hello_world_lua);
    // cartParser(examples_tennis_p8);
    // cartParser(examples_dice_p8);
    fontParser(artifacts_font_lua);

    L = init_lua(cart.code);
    if ( L == NULL ) {
	printf( "Failed to initialize LUA!\n" );
	return 1;
    }
    gfx_cls(P_BLUE);
    gfx_flip();
    registerLuaFunctions();
    gfx_cls(P_RED);
    gfx_flip();

    bool quit = false;
    bool call_update = _lua_fn_exists("_update");
    bool call_draw = _lua_fn_exists("_draw");

    quit = false;
    uint64_t frame_start_time;
    uint64_t frame_end_time;
    const uint8_t target_fps = 60;
    const uint8_t ms_delay = 1000 / target_fps;
    bootup_time = now();

    if (_lua_fn_exists("_init")) _to_lua_call("_init");
    while (!quit) {
	frame_start_time = now();
	gfx_flip();
	quit = handle_input();
	if (call_update) _to_lua_call("_update");
	if (call_draw) _to_lua_call("_draw");
	frame_end_time = now();
	int delta = ms_delay - (frame_end_time - frame_start_time);
	if(delta > 0) delay(delta);
	 printf("This frame took: %d (del is %d, ms_del is %d)\n", ms_delay - delta, delta, ms_delay);
    }

    lua_close(L);
    video_close();
}
