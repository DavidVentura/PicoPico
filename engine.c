#ifndef ENGINE
#define ENGINE
#include "data.h"
#include "parser.c"
#include <cstring>

static lua_State *L = NULL;

// The memory used by Lua is entirely separate from the PICO-8 memory and is limited to 2 MiB. 
// RIP
static uint8_t ram[0x5DFF - 0x4300]; // 7KB
// this does not include the "General use / extended map" 32KB chunk
static uint32_t cartdata[64];
static Spritesheet spritesheet;
static Spritesheet fontsheet;
static uint8_t map_data[32 * 128];
static uint32_t bootup_time;
static uint16_t frontbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

#define SECT_LUA   1
#define SECT_GFX   2
#define SECT_GFF   3
#define SECT_LABEL 4
#define SECT_MAP   5
#define SECT_SFX   6
#define SECT_MUSIC 7

static uint8_t original_palette[][3] = {
    {0, 0, 0}, //	black
    {29, 43, 83}, //	dark-blue
    {126, 37, 83}, //	dark-purple
    {0, 135, 81}, //	dark-green
    {171, 82, 54}, //	brown
    {95, 87, 79}, //	dark-grey
    {194, 195, 199}, //	light-grey
    {255, 241, 232}, //	white
    {255, 0, 77}, //	red
    {255, 163, 0}, //	orange
    {255, 236, 39}, //	yellow
    {0, 228, 54}, //	green
    {41, 173, 255}, //	blue
    {131, 118, 156}, //	lavender
    {255, 119, 168}, //	pink
    {255, 204, 170}, //	light-peach 
};
static uint8_t palette[][3] = {
    {0, 0, 0}, //	black
    {29, 43, 83}, //	dark-blue
    {126, 37, 83}, //	dark-purple
    {0, 135, 81}, //	dark-green
    {171, 82, 54}, //	brown
    {95, 87, 79}, //	dark-grey
    {194, 195, 199}, //	light-grey
    {255, 241, 232}, //	white
    {255, 0, 77}, //	red
    {255, 163, 0}, //	orange
    {255, 236, 39}, //	yellow
    {0, 228, 54}, //	green
    {41, 173, 255}, //	blue
    {131, 118, 156}, //	lavender
    {255, 119, 168}, //	pink
    {255, 204, 170}, //	light-peach 
};

static uint8_t* P_BLUE = palette[1];
static uint8_t* P_RED = palette[8];
static uint8_t* P_YELLOW = palette[10];

void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y);
void render_stretched(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t sw, uint16_t sh, uint16_t dx, uint16_t dy, uint16_t dw, uint16_t dh);
static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p);
uint16_t get_pixel(uint8_t x, uint8_t y);
static void gfx_map(uint8_t mapX, uint8_t mapY,
		    int16_t screenX, int16_t screenY,
		    uint8_t cellW, uint8_t cellH, uint8_t layerFlags);
void gfx_cls(uint8_t*);
void gfx_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint8_t* color);
void gfx_rectfill(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint8_t* color);
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color);
void gfx_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, const uint8_t* color);
void gfx_circlefill(uint16_t x, uint16_t y, uint16_t radius, uint8_t* color);
bool init_video();
bool handle_input();
void delay(uint16_t ms);
void gfx_flip();
void video_close();
uint32_t now();
void reset_transparency();

static void gfx_map(uint8_t mapX, uint8_t mapY,
		    int16_t screenX, int16_t screenY,
            uint8_t cellW, uint8_t cellH, uint8_t layerFlags) {

    for(uint8_t y = mapY; y < mapY+cellH; y++) {
        for(uint8_t x = mapX; x < mapX+cellW; x++) {
            int16_t tx = screenX+(x-mapX)*8;
            int16_t ty = screenY+(y-mapY)*8;
            uint8_t sprite = map_data[x+y*128];
            uint8_t flags = spritesheet.flags[sprite];
            if ((flags & layerFlags) == layerFlags) {
                render(&spritesheet, sprite, tx, ty, -1, false, false);
            }
        }
    }
}

int _lua_print(lua_State* L) {
    size_t textLen = 0;
    const char* text = luaL_checklstring(L, 1, &textLen);
    const int x = luaL_checkinteger(L, 2);
    const int y = luaL_checkinteger(L, 3);
    const int paletteIdx = luaL_checkinteger(L, 4);

    // printf("Requested to print [%d] '%s' at x: %d, y %d\n", textLen, text, x, y);
    for (int i = 0; i<textLen; i++) {
        uint8_t c = text[i];
        if (c == 0xe2) { // ❎ = 0xe2 0x9d 0x8e
            c = 151; // X in font
            render(&fontsheet, c, x + i * 4 + 2, y, paletteIdx, false, false);
            i += 2;
        }
        else if (c == 0xf0) { // 🅾  = 0xf0 0x9f 0x85 0xbe
            c = 142; // "circle" in font (square)
            render(&fontsheet, c, x + i * 4 + 2, y, paletteIdx, false, false);
            i += 3;
        } else {
            render(&fontsheet, c, x + i * 4, y, paletteIdx, false, false);
        }
    }
    // FIXME: this only works for ascii
    return 0;
}

int _lua_palt(lua_State* L) {
    uint8_t argcount = lua_gettop(L);
    if (argcount == 0) {
        // reset for all colors
        reset_transparency();
        return 0;
    }
    if (argcount == 1) {
        // TODO: should this use fix32?? not sure if rotr is what i want
        uint16_t bitfield = luaL_checkinteger(L, 1);
        for(uint8_t idx = 0; idx < 16; idx++) {
            drawstate.transparent[idx] = (bitfield & 1);
            bitfield >>= 1;
        }
        return 0;
    }
    uint8_t idx = luaL_checkinteger(L, 1);
    bool transparent = lua_toboolean(L, 2);
    drawstate.transparent[idx] = transparent;

    return 0;
}

int _lua_pal(lua_State* L) {
    // TODO: significant functionality missing
    // https://pico-8.fandom.com/wiki/Pal
    uint8_t argcount = lua_gettop(L);
    if (argcount == 0) {
        memcpy(palette, original_palette, sizeof(original_palette));
        reset_transparency();
        return 0;
    }
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
    return 0;
}

int _lua_spr(lua_State* L) {
    // TODO: optional w/h
    uint8_t argcount = lua_gettop(L);
    if (argcount < 3)
        return 0;

    int n = luaL_optinteger(L, 1, -1);
    if (n==-1)
        return 0;
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    z8::fix32 w = luaL_optinteger(L, 4, 1.0);
    z8::fix32 h = luaL_optinteger(L, 5, 1.0);

    bool flip_x = false;
    bool flip_y = false;

    if (argcount >= 6)
        flip_x = lua_toboolean(L, 6);
    if (argcount >= 7)
        flip_y = lua_toboolean(L, 7);

    render(&spritesheet, n, x, y, -1, flip_x==1, flip_y==1);
    return 0;
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
    uint8_t x2 = luaL_checkinteger(L, 3);
    uint8_t y2 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);
    uint8_t* newColor = NULL;
    if (col != -1) {
	    newColor = palette[col];
    }

    gfx_rect(x, y, x2, y2, newColor);
    return 0;
}

int _lua_rectfill(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint8_t x2 = luaL_checkinteger(L, 3);
    uint8_t y2 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);
    uint8_t* newColor = NULL;
    if (col != -1) {
	    newColor = palette[col];
    }

    gfx_rectfill(x, y, x2, y2, newColor);
    return 0;
}

int _lua_circfill(lua_State* L) {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_optinteger(L, 3, 4);
    int col = luaL_optinteger(L, 4, -1);

    uint8_t* newColor = NULL;
    if ( col != -1 ) {
	newColor = palette[col];
    } else {
        // newColor = RED;
    }

    gfx_circlefill(x-drawstate.camera_x, y-drawstate.camera_y, r, newColor);
    return 0;
}

int _lua_map(lua_State* L) {
    int mapX = luaL_checkinteger(L, 1);
    int mapY = luaL_checkinteger(L, 2);
    int screenX = luaL_checkinteger(L, 3);
    int screenY = luaL_checkinteger(L, 4);
    int cellW = luaL_checkinteger(L, 5);
    int cellH = luaL_checkinteger(L, 6);
    uint32_t layerFlags = luaL_optinteger(L, 7, 0x0);

    gfx_map(mapX, mapY, screenX, screenY, cellW, cellH, layerFlags);
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
    // printf("Button state for %d is %d\n", idx, buttons[idx]);
    return 1;
}
int _lua_rnd(lua_State* L) {
    if(lua_istable(L, 1)) {
        lua_len(L, 1);  // table len in top of stack
        uint32_t len = luaL_checkinteger(L, 2);
        uint32_t choice = (rand() % len) + 1;
        lua_pushinteger(L, choice);
        lua_gettable(L, 1);
	    return 1;
    }
    float limit = luaL_optnumber(L, 1, 1.0f);
    float x = (float)rand()/(float)(RAND_MAX/limit);
    lua_pushnumber(L, x);
    return 1;
}
int _lua_sget(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);

    if (x < 0 || x > 127 || y < 0 || y > 127) {
        lua_pushinteger(L, 0);
    } else {
        lua_pushinteger(L, spritesheet.sprite_data[y*128+x]);
    }
    return 1;
}

int _lua_fget(lua_State* L) {
    uint8_t n = luaL_checkinteger(L, 1);
    uint8_t bitfield = luaL_optinteger(L, 2, 0xFF);

    uint8_t p = spritesheet.flags[n];
    if (bitfield == 0xFF) {
        lua_pushinteger(L, p);
    } else {
        bool result = ((1 << bitfield) & p) == 1;
        lua_pushboolean(L, result);
    }
    return 1;
}

int _lua_mget(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint16_t p = map_data[y*128+x];
    lua_pushinteger(L, p);
    return 1;
}

int _lua_pget(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint16_t p = get_pixel(x, y);
    lua_pushinteger(L, p);
    return 1;
}

int _lua_pset(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);
    uint8_t idx = luaL_optinteger(L, 3, drawstate.fg_color);

    int16_t tx = x-drawstate.camera_x;
    int16_t ty = y-drawstate.camera_y;
    if (tx < 0 || tx >= SCREEN_WIDTH || ty < 0 || ty  >= SCREEN_HEIGHT) return 0;
    put_pixel(tx, ty, palette[idx]);
    return 0;
}

int _lua_noop(lua_State* L) {
    float val = luaL_checknumber(L, 1);
    lua_pushinteger(L, 0);
    return 0;
}

int _lua_flr(lua_State* L) {
    z8::fix32 val = luaL_checknumber(L, 1);
    lua_pushinteger(L, z8::fix32::floor(val));
    return 1;
}

int _lua_time(lua_State* L) {
    float delta = ((float)(now() - bootup_time))/1000;
    lua_pushnumber(L, delta);
    return 1;
}

int _lua_dget(lua_State* L) {
    const uint8_t idx = luaL_checkinteger(L, 1);
    lua_pushinteger(L, cartdata[idx]);
    return 1;
}

int _lua_dset(lua_State* L) {
    const uint8_t idx = luaL_checkinteger(L, 1);
    const uint32_t val = luaL_checkinteger(L, 2);
    cartdata[idx] = val;
    return 0;
}


int _lua_printh(lua_State* L) {
    const char* val = luaL_checkstring(L, 1);
    printf("> %s\n", val);
    return 0;
}

int _lua_stub(lua_State* L) {
	// TODO: implement
    return 0;
}

int _lua_camera(lua_State* L) {
    int32_t x = luaL_optinteger(L, 1, 0);
    int32_t y = luaL_optinteger(L, 2, 0);
    int32_t old_x = drawstate.camera_x;
    int32_t old_y = drawstate.camera_y;

    drawstate.camera_x = x;
    drawstate.camera_y = y;

    lua_pushinteger(L, old_x);
    lua_pushinteger(L, old_y);
    return 2;
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
    lua_pushcfunction(L, _lua_pset);
    lua_setglobal(L, "pset");
    lua_pushcfunction(L, _lua_pget);
    lua_setglobal(L, "pget");
    lua_pushcfunction(L, _lua_fget);
    lua_setglobal(L, "fget");
    lua_pushcfunction(L, _lua_mget);
    lua_setglobal(L, "mget");
    lua_pushcfunction(L, _lua_sget);
    lua_setglobal(L, "sget");
    lua_pushcfunction(L, _lua_time);
    lua_setglobal(L, "time");
    lua_pushcfunction(L, _lua_stub);
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
    lua_pushcfunction(L, _lua_noop);
    lua_setglobal(L, "noop");
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

static int p_init_lua(lua_State* L) {
    luaL_checkversion(L);
    lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
    luaL_openlibs(L);  /* open libraries */
    lua_gc(L, LUA_GCRESTART, 0);
    return 1;
}
bool init_lua(const char* script_text) {
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
    if (luaL_dostring(L, (const char*)stdlib_stdlib_lua) == LUA_OK) {
        printf("stdlib loaded\n");
        lua_pop(L, lua_gettop(L));

        if (luaL_dostring(L, script_text) == LUA_OK) {
            lua_pop(L, lua_gettop(L));
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
}

void fontParser(const uint8_t* text) {
    int spriteCount = 0;
    uint8_t* rawbuf = (uint8_t*)malloc(129);
    uint8_t* decbuf = (uint8_t*)malloc(129);
    // 128 bytes per line of data
    // 1 byte per line for \0

    uint16_t lineLen = 0;
    memset(decbuf, 0, 129);
    memset(rawbuf, 0, 129);
    do {
	lineLen = readLine(&text, rawbuf);
	decodeRLE(decbuf, rawbuf, lineLen);
	gfxParser(decbuf, spriteCount, &fontsheet);
	spriteCount++;
    } while (*text != 0);
    free(decbuf);
    free(rawbuf);
}

void cartParser(const uint8_t* text) {
    uint8_t section = 0;
    uint32_t spriteCount = 0;
    char* rawbuf = (char*)malloc(257);
    char* decbuf = (char*)malloc(257);
    // up to 256 bytes per line
    // 1 byte for \0

    memset(rawbuf, 0, 258);
    cart.code = (char*)malloc(0xFFFF);
    memset(cart.code, 0, 0xFFFF);

    uint16_t lineLen = 0;
    uint32_t bytesRead = 0;
    do {
        lineLen = readLine(&text, (uint8_t*)rawbuf);
        // FIXME: BUG: readLine does not take 2 newlines in a row too happily
        if (strncmp(rawbuf, "__lua__", 7) == 0) {
            section = SECT_LUA;
            bytesRead = 0;
            continue;
        }
        if (strncmp(rawbuf, "__gfx__", 7) == 0) {
            section = SECT_GFX;
            spriteCount = 0;
            bytesRead = 0;
            continue;
        }
        if (strncmp(rawbuf, "__gff__", 7) == 0) {
            spriteCount = 0;
            section = SECT_GFF;
            continue;
        }
        if (strncmp(rawbuf, "__label__", 7) == 0) {
            section = SECT_LABEL;
            continue;
        }
        if (strncmp(rawbuf, "__map__", 7) == 0) {
            section = SECT_MAP;
            spriteCount = 0;
            bytesRead = 0;
            continue;
        }
        if (strncmp(rawbuf, "__sfx__", 7) == 0) {
            section = SECT_SFX;
            continue;
        }
        if (strncmp(rawbuf, "__music__", 7) == 0) {
            section = SECT_MUSIC;
            continue;
        }
        if (section > SECT_MAP) {
            break;
            // TODO: implement SFX etc
        }
        switch (section) {
            case SECT_LUA:
                memcpy(cart.code+bytesRead, rawbuf, lineLen);
                break;
            case SECT_GFX:
                decodeRLE((uint8_t*)decbuf, (uint8_t*)rawbuf, lineLen);
                gfxParser((uint8_t*)decbuf, spriteCount, &spritesheet);
                spriteCount++;
                break;
            case SECT_GFF:
                decodeRLE((uint8_t*)decbuf, (uint8_t*)rawbuf, lineLen);
                flagParser((uint8_t*)decbuf, spriteCount, &spritesheet);
                spriteCount++;
                break;
            case SECT_MAP:
                decodeRLE((uint8_t*)decbuf, (uint8_t*)rawbuf, lineLen);
                mapParser(decbuf, spriteCount, map_data);
                spriteCount++;
                break;
        }
        bytesRead += lineLen;
    } while (*text != 0);
    hexDump("Sprites", spritesheet.flags, 256, 64);
    free(decbuf);
    free(rawbuf);
}

void _render(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y) {
    uint16_t idx, val;
    if((x0 < -drawstate.camera_x) && (x0-drawstate.camera_x >= SCREEN_WIDTH)) return;
    if(y0-drawstate.camera_y >= SCREEN_HEIGHT) return;

    for (uint16_t y=0; y<8; y++) {
        int16_t screen_y = y0+y-drawstate.camera_y;
        if (screen_y < 0) continue;
        if (screen_y >= SCREEN_HEIGHT) return;

        for (uint16_t x=0; x<8; x++) {
            uint16_t screen_x = x0+x-drawstate.camera_x;
            if (screen_x >= SCREEN_WIDTH) continue;
            val = s->sprite_data[(sy+y)*128 + x + sx];
            if (paletteIdx != -1) {
                idx = paletteIdx;
            } else {
                idx = val;
            }
            if (drawstate.transparent[val] == 0) {
                const uint8_t* p = palette[idx];
                if(flip_x) {
                    put_pixel(screen_x+8-2*x, screen_y, p);
                } else {
                    put_pixel(screen_x, screen_y, p);
                }

            }
        }
    }
}
void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = n % sprite_count;
    const uint8_t yIndex = n / sprite_count;
    _render(s, xIndex*8, yIndex*8, x0, y0, paletteIdx, flip_x, flip_y);
}

void render_stretched(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t sw, uint16_t sh, uint16_t dx, uint16_t dy,
		      uint16_t dw, uint16_t dh) {
    if(dw == sw && dh == sh) return _render(s, sx, sy, dx, dy, -1, false, false);
    if(dx >= SCREEN_WIDTH) return;
    if(dy >= SCREEN_HEIGHT) return;

    // TODO: this does not clip or flip
    uint32_t ratio_x = (sw << 16)/ dw;
    uint32_t ratio_y = (sh << 16)/ dh;
    for (uint16_t y=0; y<dh; y++) {
        int16_t screen_y = dy+y-drawstate.camera_y;
        if (screen_y < 0) continue;
        if (screen_y >= SCREEN_HEIGHT) return;
        uint16_t yoff = (((y*ratio_y)>>16)+sy)*128;

        for (uint16_t x=0; x<dw; x++) {
            uint8_t val = s->sprite_data[yoff + ((x*ratio_x) >> 16)+sx];
            if (drawstate.transparent[val] == 0){
                const uint8_t* p = palette[val];
                put_pixel(dx+x-drawstate.camera_x, screen_y, p);
            }
        }
    }
}
void gfx_circlefill(uint16_t x, uint16_t y, uint16_t radius, uint8_t* color){
    if(x < 0 || y < 0 || x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) return;
    for (int w = 0; w <= radius * 2; w++)
    {
        int dx = radius - w; // horizontal offset
        if((x + dx) < 0) continue;
        if((x + dx) >= SCREEN_WIDTH) break;
        for (int h = 0; h <= radius * 2; h++)
        {
            int dy = radius - h; // vertical offset
            if((y + dy) >= SCREEN_HEIGHT) break;
            if((y + dy) < 0) continue;
            if ((dx*dx + dy*dy) <= (radius * radius))
            {
                put_pixel(x + dx, y + dy, color);
            }
        }
    }
}
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color){
    const int32_t diameter = (radius * 2);

    int32_t x = (radius - 1);
    int32_t y = 0;
    int32_t tx = 1;
    int32_t ty = 1;
    int32_t error = (tx - diameter);

    while (x >= y)
    {
        //  Each of the following renders an octant of the circle
        put_pixel(centreX + x, centreY - y, color);
        put_pixel(centreX + x, centreY + y, color);
        put_pixel(centreX - x, centreY - y, color);
        put_pixel(centreX - x, centreY + y, color);
        put_pixel(centreX + y, centreY - x, color);
        put_pixel(centreX + y, centreY + x, color);
        put_pixel(centreX - y, centreY - x, color);
        put_pixel(centreX - y, centreY + x, color);

        if (error <= 0)
        {
            ++y;
            error += ty;
            ty += 2;
        }

        if (error > 0)
        {
            --x;
            tx += 2;
            error += (tx - diameter);
        }
    }
}
void gfx_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, const uint8_t* color) {
	for(uint16_t x=x0; x<x1-x0; x++)
		for(uint16_t y=y0; y<y1-y0; y++)
			put_pixel(x, y, color);
}

// callers have to ensure this is not called with x > SCREEN_WIDTH or y > SCREEN_HEIGHT
static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p){
    const uint16_t color = ((p[0] >> 3) << 11) | ((p[1] >> 2) << 5) | (p[2] >> 3);
    frontbuffer[(y*SCREEN_WIDTH+x)  ] = color;

}
void gfx_cls(uint8_t* p) {
    // const uint16_t val = ((p[0] >> 3) << 11) | ((p[1] >> 2) << 5) | (p[2] >> 3);
    const uint16_t val = ((p[0] & 0b11111000) << 8) | ((p[1] & 0b11111100) << 3) | (p[2] >> 3);
    memset(frontbuffer, val, sizeof(frontbuffer));
}

void gfx_rect(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const uint8_t* color) {
    for(uint16_t y=y0; y<=y2; y++)
        for(uint8_t x=x0; x<=x2; x++)
            if ((y==y0) || (y==y2) || (x==x0) || (x==x2))
                put_pixel(x, y, color);
}

void gfx_rectfill(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const uint8_t* color) {
    // this is _inclusive_
    y2 = MIN(SCREEN_HEIGHT-1, y2);
    x2 = MIN(SCREEN_WIDTH-1, x2);
    for(uint16_t y=y0; y<=y2; y++)
        for(uint16_t x=x0; x<=x2; x++)
            put_pixel(x, y, color);
}


uint16_t get_pixel(uint8_t x, uint8_t y) {
	// FIXME: this is incredibly broken
	return frontbuffer[x+y*SCREEN_WIDTH];
}
#endif
