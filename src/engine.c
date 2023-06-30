#ifndef ENGINE
#define ENGINE
#include "data.h"
#include "engine.h"
#include "parser.c"
//#include "synth.c"
#include "hud.c"
#include "sfx.c"
#include "pico8api.c"
//#include "lua/lauxlib.h"
//#include "lua/lualib.h"
#include <string.h>
#include <stdbool.h>

#include <dlfcn.h> // dlopen, dlsym
static bool     wants_to_quit = false;
static uint8_t  fps = 30;
static uint8_t  ms_delay = 33;
static uint32_t frame_start_time;
static uint32_t frame_end_time;

//static lua_State *L = NULL;
//void registerLuaFunctions();

/*
static int p_init_lua(lua_State* _L) {
    luaL_checkversion(_L);
    lua_gc(_L, LUA_GCSTOP, 0);  / * stop collector during initialization * /
    luaL_openlibs(_L);  / * open libraries * /
    lua_gc(_L, LUA_GCRESTART, 0);
    return 1;
}

bool init_lua(const uint8_t* bytecode, uint16_t code_len) {
    L = luaL_newstate();
    if (L == NULL) {
        printf("cannot create LUA state: not enough memory\n");
        return false;
    }
    lua_setpico8memory(L, ram);
    lua_pushcfunction(L, &p_init_lua);

    int status = lua_pcall(L, 0, 1, 0);
    if (status != LUA_OK) {
        int result = lua_toboolean(L, -1);
        printf("Error loading lua VM: %s\n", lua_tostring(L, lua_gettop(L)));
        return false;
    }

    registerLuaFunctions();
    uint32_t start_time = now();
    uint32_t end_time;
    int error = luaL_loadbuffer(L, (const char*)stdlib_stdlib_lua, stdlib_stdlib_lua_len, "stdlib") || lua_pcall(L, 0, 0, 0);
    if (error) {
        goto handle_error;
    }

    end_time = now();
    printf("stdlib loaded, took %dms\n", end_time-start_time);
    start_time = now();

    error = luaL_loadbuffer(L, (const char*)bytecode, code_len, "cart") || lua_pcall(L, 0, 0, 0);
    if (error) {
        goto handle_error;
    }
    end_time = now();
    printf("cart loaded, took %dms\n", end_time-start_time);
    return true;

handle_error:
    printf("Fail: %s\n", lua_tostring(L, lua_gettop(L)));
    lua_close(L);
    return false;
}
*/

void reset_transparency() {
    memset(drawstate.transparent, 0, sizeof(drawstate.transparent));
    drawstate.transparent[0] = 1;
}

void load_game_code(GameCart* cart) {
	cart->_preinit_fn = NULL;
	cart->_init_fn = NULL;
	cart->_update_fn = NULL;
	cart->_draw_fn = NULL;

	char data[100] = {0};
	sprintf(data, "/home/david/git/lua-but-worse/%s", cart->name);
	void *libhandle = dlopen(data, RTLD_NOW);
	printf("%s\n", data);
	if(libhandle == NULL) {
		printf("No libhandle %s\n", dlerror());
		fflush(stdout);
		exit(1);
		return;
	}

	printf("err %s\n", dlerror());
	//dlerror(); // clear existing errors
	typedef void(*fn_t)();

	cart->_preinit_fn = dlsym(libhandle, "__preinit");
	printf("err %s\n", dlerror());
	cart->_init_fn = dlsym(libhandle, "__init");
	printf("err %s\n", dlerror());
	cart->_update_fn = dlsym(libhandle, "_update");
	printf("err %s\n", dlerror());
	cart->_draw_fn = dlsym(libhandle, "_draw");
	printf("err %s\n", dlerror());
}
void engine_init() {
    reset_transparency();

    memset(&fontsheet.sprite_data, 0xFF, sizeof(fontsheet.sprite_data));
    memset(map_data, 0, sizeof(map_data));

    memset(cartdata, 0, sizeof(cartdata));

    memset(audiobuf, 0, sizeof(audiobuf));

    channels[0].id = 0;
    channels[1].id = 1;
    channels[2].id = 2;
    channels[3].id = 3;

    channels[0].sfx = NULL;
    channels[1].sfx = NULL;
    channels[2].sfx = NULL;
    channels[3].sfx = NULL;

    printf("Parsing font \n");
    assert(artifacts_font_lua_len <= sizeof(fontsheet.sprite_data));
    memcpy(fontsheet.sprite_data, artifacts_font_lua, artifacts_font_lua_len);

    printf("Parsing HUD \n");
    assert(artifacts_hud_p8_len <= sizeof(hud_sprites.sprite_data));
    memcpy(hud_sprites.sprite_data, artifacts_hud_p8, artifacts_hud_p8_len);
//    init_pink_noise_gen(&osc);
}

void cartParser(GameCart* parsingCart) {
	assert(parsingCart->gfx_len <= sizeof(spritesheet.sprite_data));
	memcpy(spritesheet.sprite_data, parsingCart->gfx, parsingCart->gfx_len);

	assert(parsingCart->gff_len <= sizeof(spritesheet.flags));
	memcpy(spritesheet.flags, parsingCart->gff, parsingCart->gff_len);

	assert(parsingCart->map_len <= sizeof(map_data));
	memcpy(map_data, parsingCart->map, parsingCart->map_len);

        if (parsingCart->gfx_len > (64*128)) { // 64 half-sized lines (128bytes) == 32 256 lines
                                               // these are LSB and have to be flipped
            for(uint16_t i=32; i<(parsingCart->gfx_len/256); i++) {
                mapParser(parsingCart->gfx+(i*256), i, map_data);
            }
        }
        for(uint8_t i=0; i<(parsingCart->sfx_len/168); i++) {
                SFXParser(parsingCart->sfx+(i*168), i, sfx);
        }
	load_game_code(parsingCart);
}
/*
void registerLuaFunctions() {
    lua_pushcfunction(L, _lua_spr);
    lua_setglobal(L, "spr");
    lua_pushcfunction(L, _lua_sspr);
    lua_setglobal(L, "sspr");
    lua_pushcfunction(L, _lua_cls);
    lua_setglobal(L, "cls");
    lua_pushcfunction(L, _lua_palt);
    lua_setglobal(L, "palt");
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
    lua_pushcfunction(L, _lua_circ);
    lua_setglobal(L, "circ");
    lua_pushcfunction(L, _lua_circfill);
    lua_setglobal(L, "circfill");
    lua_pushcfunction(L, _lua_oval);
    lua_setglobal(L, "oval");
    lua_pushcfunction(L, _lua_ovalfill);
    lua_setglobal(L, "ovalfill");
    lua_pushcfunction(L, _lua_btn);
    lua_setglobal(L, "btn");
    lua_pushcfunction(L, _lua_btnp);
    lua_setglobal(L, "btnp");
    lua_pushcfunction(L, _lua_map);
    lua_setglobal(L, "map");
    lua_pushcfunction(L, _lua_srand);
    lua_setglobal(L, "srand");
    lua_pushcfunction(L, _lua_rnd);
    lua_setglobal(L, "rnd");
    lua_pushcfunction(L, _lua_pset);
    lua_setglobal(L, "pset");
    lua_pushcfunction(L, _lua_pget);
    lua_setglobal(L, "pget");
    lua_pushcfunction(L, _lua_fget);
    lua_setglobal(L, "fget");
    lua_pushcfunction(L, _lua_mset);
    lua_setglobal(L, "mset");
    lua_pushcfunction(L, _lua_mget);
    lua_setglobal(L, "mget");
    lua_pushcfunction(L, _lua_sget);
    lua_setglobal(L, "sget");
    lua_pushcfunction(L, _lua_sset);
    lua_setglobal(L, "sset");
    lua_pushcfunction(L, _lua_time);
    lua_setglobal(L, "t");
    lua_pushcfunction(L, _lua_time);
    lua_setglobal(L, "time");
    lua_pushcfunction(L, _lua_sfx);
    lua_setglobal(L, "sfx");
    lua_pushcfunction(L, _lua_printh);
    lua_setglobal(L, "printh");
    lua_pushcfunction(L, _lua_stub);
    lua_setglobal(L, "cartdata");
    lua_pushcfunction(L, _lua_dget);
    lua_setglobal(L, "dget");
    lua_pushcfunction(L, _lua_dset);
    lua_setglobal(L, "dset");
    lua_pushcfunction(L, _lua_stub);
    lua_setglobal(L, "menuitem");
    lua_pushcfunction(L, _lua_stub);
    lua_setglobal(L, "music");
    lua_pushcfunction(L, _lua_camera);
    lua_setglobal(L, "camera");
    lua_pushcfunction(L, _lua_stat);
    lua_setglobal(L, "stat");
    lua_pushcfunction(L, _lua_clip);
    lua_setglobal(L, "clip");
    lua_pushcfunction(L, _lua_color);
    lua_setglobal(L, "color");
    lua_pushcfunction(L, _lua_poke);
    lua_setglobal(L, "poke");
    lua_pushcfunction(L, _lua_poke4);
    lua_setglobal(L, "poke4");
    lua_pushcfunction(L, _lua_flip);
    lua_setglobal(L, "flip");
    lua_pushcfunction(L, _lua_fillp);
    lua_setglobal(L, "fillp");
    lua_pushcfunction(L, _lua_reload);
    lua_setglobal(L, "reload");
    lua_pushcfunction(L, _extcmd);
    lua_setglobal(L, "extcmd");
    lua_pushcfunction(L, _lua_cursor);
    lua_setglobal(L, "cursor");
}

bool _lua_fn_exists(const char* fn) {
    lua_getglobal(L, fn);
    if (lua_isfunction(L, -1)) {
	    return true;
    } else {
	    printf("Function %s does not exist\n", fn);
	    return false;
    }
}
uint8_t _to_lua_call(const char* fn) {
	lua_getglobal(L, fn);
	if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
		lua_pop(L, lua_gettop(L));
		return 0;
	} else {
		printf("Lua error: %s\n", lua_tostring(L, lua_gettop(L)));
		lua_pop(L, lua_gettop(L));
		return 1;
	}
}
*/

void flip() {
    gfx_flip();
    wants_to_quit = handle_input();
    uint32_t n = now();

    if (n < frame_end_time) {
		//printf("delaying for %u\n", frame_end_time - n);
        delay(frame_end_time - n);
    }

    frame_start_time = now();
    frame_end_time = frame_start_time + ms_delay;
}
#endif

