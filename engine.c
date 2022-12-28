#ifndef ENGINE
#define ENGINE
#include "data.h"
#include "engine.h"
#include "parser.c"
#include "synth.c"
#include "hud.c"
#include "sfx.c"
#include "pico8api.c"
#include <cstring>


static lua_State *L = NULL;
void registerLuaFunctions();



static int p_init_lua(lua_State* L) {
    luaL_checkversion(L);
    lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
    luaL_openlibs(L);  /* open libraries */
    lua_gc(L, LUA_GCRESTART, 0);
    return 1;
}

bool init_lua(const char* script_text, uint16_t code_len) {
    L = luaL_newstate();
    if (L == NULL) {
        printf("cannot create LUA state: not enough memory\n");
        return false;
    }
    lua_setpico8memory(L, ram);
    lua_pushcfunction(L, &p_init_lua);

    int status = lua_pcall(L, 0, 1, 0);
    if (status != LUA_OK) { // err
        int result = lua_toboolean(L, -1);
        printf("Error loading lua VM: %s\n", lua_tostring(L, lua_gettop(L)));
        return false;
    }

    registerLuaFunctions();
    uint32_t start_time = now();
    if (luaL_dostring(L, (const char*)stdlib_stdlib_lua) == LUA_OK) {
        lua_pop(L, lua_gettop(L));
        uint32_t end_time = now();
        printf("stdlib loaded, took %dms\n", end_time-start_time);
        start_time = now();

        printf("Code len for lua %d\n", code_len);
        int error = luaL_loadbuffer(L, script_text, code_len, "debugname") || lua_pcall(L, 0, 0, 0);
	    if (!error) {
            end_time = now();
            printf("cart loaded, took %dms\n", end_time-start_time);
            return true;
        }
    }
    printf("Fail: %s\n", lua_tostring(L, lua_gettop(L)));
    lua_close(L);
    return false;
}

void reset_transparency() {
    memset(drawstate.transparent, 0, sizeof(drawstate.transparent));
    drawstate.transparent[0] = 1;
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
}

void rawSpriteParser(Spritesheet* sheet, const uint8_t* text) {
    int spriteCount = 0;
    uint8_t* rawbuf = (uint8_t*)malloc(129);
    // 128 bytes per line of data
    // 1 byte per line for \0

    uint16_t lineLen = 0;
    memset(rawbuf, 0, 129);
    do {
	    lineLen = readLine(&text, rawbuf);
	    gfxParser(rawbuf, spriteCount, sheet);
	    spriteCount++;
    } while (*text != 0);
    free(rawbuf);
}

void cartParser(GameCart* parsingCart) {
        // FIXME skip copy?
        printf("Code size %d\n", parsingCart->code_len);
        cart.code = (char*)malloc(parsingCart->code_len);
        memset(cart.code, 0, parsingCart->code_len);
        memcpy(cart.code, parsingCart->code, parsingCart->code_len);
        for(uint8_t i=0; i<(parsingCart->gfx_len/128); i++) {
                gfxParser(parsingCart->gfx+(i*128), i, &spritesheet);
        }
        for(uint8_t i=0; i<(parsingCart->gff_len/128); i++) {
                flagParser(parsingCart->gff+(i*128), i, &spritesheet);
        }
        for(uint8_t i=0; i<(parsingCart->map_len/256); i++) {
                mapParser(parsingCart->map+(i*256), i, map_data, true);
        }
        if (parsingCart->gfx_len > (64*128)) { // 64 half-sized lines (128bytes) == 32 256 lines
            for(uint16_t i=32; i<(parsingCart->gfx_len/256); i++) {
                mapParser(parsingCart->gfx+(i*256), i, map_data, false);
            }
        }
        for(uint8_t i=0; i<(parsingCart->sfx_len/168); i++) {
                SFXParser(parsingCart->sfx+(i*168), i, sfx);
        }
}
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
    lua_pushcfunction(L, _lua_btn);
    lua_setglobal(L, "btn");
    lua_pushcfunction(L, _lua_btnp);
    lua_setglobal(L, "btnp");
    lua_pushcfunction(L, _lua_map);
    lua_setglobal(L, "map");
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
void _to_lua_call(const char* fn) {
	lua_getglobal(L, fn);
	if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
		lua_pop(L, lua_gettop(L));
	} else {
		printf("Lua error: %s\n", lua_tostring(L, lua_gettop(L)));
		lua_pop(L, lua_gettop(L));
	}
}


#endif
