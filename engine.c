#ifndef ENGINE
#define ENGINE
#include "data.h"
#include "parser.c"
#include "synth.c"
#include <cstring>

typedef uint16_t color_t;
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
static color_t frontbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

const z8::fix32 VOL_NORMALIZER = 32767.99f/7.f;
static SFX sfx[64];
uint16_t audiobuf[2*8192]; // FIXME: this is 22k big buffer
void play_sfx_buffer();

// return 440.f * exp2f((key - 33.f) / 12.f);
static z8::fix32 key_to_freq[64] = {
    65.40639132514966,
    69.29565774421802,
    73.41619197935188,
    77.78174593052023,
    82.4068892282175,
    87.30705785825097,
    92.4986056779086,
    97.99885899543733,
    103.82617439498628,
    110.0,
    116.54094037952248,
    123.47082531403103,
    130.8127826502993,
    138.59131548843604,
    146.8323839587038,
    155.56349186104046,
    164.81377845643496,
    174.61411571650194,
    184.9972113558172,
    195.99771799087463,
    207.65234878997256,
    220.0,
    233.08188075904496,
    246.94165062806206,
    261.6255653005986,
    277.1826309768721,
    293.6647679174076,
    311.1269837220809,
    329.6275569128699,
    349.2282314330039,
    369.9944227116344,
    391.99543598174927,
    415.3046975799451,
    440.0,
    466.1637615180899,
    493.8833012561241,
    523.2511306011972,
    554.3652619537442,
    587.3295358348151,
    622.2539674441618,
    659.2551138257398,
    698.4564628660078,
    739.9888454232688,
    783.9908719634985,
    830.6093951598903,
    880.0,
    932.3275230361799,
    987.7666025122483,
    1046.5022612023945,
    1108.7305239074883,
    1174.6590716696303,
    1244.5079348883237,
    1318.5102276514797,
    1396.9129257320155,
    1479.9776908465376,
    1567.981743926997,
    1661.2187903197805,
    1760.0,
    1864.6550460723597,
    1975.533205024496,
    2093.004522404789,
    2217.4610478149766,
    2349.31814333926,
    2489.0158697766474,
};
void play_sfx(SFX* sfx);
#define SECT_LUA   1
#define SECT_GFX   2
#define SECT_GFF   3
#define SECT_LABEL 4
#define SECT_MAP   5
#define SECT_SFX   6
#define SECT_MUSIC 7
#define to_rgb565(r, g, b) (((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3))

static const color_t original_palette[] = {
    to_rgb565(0, 0, 0),         //	black
    to_rgb565(29, 43, 83),      //	dark-blue
    to_rgb565(126, 37, 83),     //	dark-purple
    to_rgb565(0, 135, 81),      //	dark-green
    to_rgb565(171, 82, 54),     //	brown
    to_rgb565(95, 87, 79),      //	dark-grey
    to_rgb565(194, 195, 199),   //	light-grey
    to_rgb565(255, 241, 232),   //	white
    to_rgb565(255, 0, 77),      //	red
    to_rgb565(255, 163, 0),     //	orange
    to_rgb565(255, 236, 39),    //	yellow
    to_rgb565(0, 228, 54),      //	green
    to_rgb565(41, 173, 255),    //	blue
    to_rgb565(131, 118, 156),   //	lavender
    to_rgb565(255, 119, 168),   //	pink
    to_rgb565(255, 204, 170),   //	light-peach 
};
static color_t palette[] = {
    to_rgb565(0, 0, 0),         //	black
    to_rgb565(29, 43, 83),      //	dark-blue
    to_rgb565(126, 37, 83),     //	dark-purple
    to_rgb565(0, 135, 81),      //	dark-green
    to_rgb565(171, 82, 54),     //	brown
    to_rgb565(95, 87, 79),      //	dark-grey
    to_rgb565(194, 195, 199),   //	light-grey
    to_rgb565(255, 241, 232),   //	white
    to_rgb565(255, 0, 77),      //	red
    to_rgb565(255, 163, 0),     //	orange
    to_rgb565(255, 236, 39),    //	yellow
    to_rgb565(0, 228, 54),      //	green
    to_rgb565(41, 173, 255),    //	blue
    to_rgb565(131, 118, 156),   //	lavender
    to_rgb565(255, 119, 168),   //	pink
    to_rgb565(255, 204, 170),   //	light-peach 
};

void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y);
void render_stretched(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t sw, uint16_t sh, uint16_t dx, uint16_t dy, uint16_t dw, uint16_t dh);
static inline void put_pixel(uint8_t x, uint8_t y, const color_t p);
uint16_t get_pixel(uint8_t x, uint8_t y);
static void gfx_map(uint8_t mapX, uint8_t mapY,
		    int16_t screenX, int16_t screenY,
		    uint8_t cellW, uint8_t cellH, uint8_t layerFlags);
void gfx_cls(color_t);
void gfx_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const color_t color);
void gfx_rectfill(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const color_t color);
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, color_t color);
void gfx_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, const color_t color);
void gfx_circlefill(uint16_t x, uint16_t y, uint16_t radius, color_t color);
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
        int16_t ty = screenY+(y-mapY)*8;

        for(uint8_t x = mapX; x < mapX+cellW; x++) {
            int16_t tx = screenX+(x-mapX)*8;
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
    const color_t origColor = palette[origIdx];
    const color_t newColor = original_palette[newIdx];

    palette[origIdx] = newColor;
    return 0;
}

int _lua_cls(lua_State* L) {
    uint8_t palIdx = luaL_optinteger(L, 1, 0);
    color_t color = palette[palIdx];
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
    if (col == -1) {
        printf("lua_line: unknown color not implemented\n");
        return 0;
    }
    drawstate.line_x = x1;
    drawstate.line_y = y1;
    gfx_line(x0, y0, x1, y1, palette[col]);
    return 0;
}

int _lua_rect(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint8_t x2 = luaL_checkinteger(L, 3);
    uint8_t y2 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);
    if (col == -1) {
        printf("lua_rect: unknown color not implemented\n");
        return 0;
    }
	    
    gfx_rect(x, y, x2, y2, palette[col]);
    return 0;
}

int _lua_rectfill(lua_State* L) {
    int8_t x = luaL_checkinteger(L, 1);
    int8_t y = luaL_checkinteger(L, 2);
    int8_t x2 = luaL_checkinteger(L, 3);
    int8_t y2 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);
    if (col == -1) {
        printf("lua_rectfill: unknown color not implemented\n");
        return 0;
    }

    gfx_rectfill(x, y, x2, y2, palette[col]);
    return 0;
}

int _lua_circfill(lua_State* L) {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_optinteger(L, 3, 4);
    int col = luaL_optinteger(L, 4, -1);

    if (col == -1) {
        printf("lua_circfill: unknown color not implemented\n");
        return 0;
    }

    gfx_circlefill(x-drawstate.camera_x, y-drawstate.camera_y, r, palette[col]);
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


int _lua_sfx(lua_State* L) {
    int16_t n       = luaL_checkinteger(L, 1);
    int16_t channel = luaL_optinteger(L, 2, -1);
    int16_t offset  = luaL_optinteger(L, 3, 0);
    int16_t length  = luaL_optinteger(L, 4, 31);
    printf("Play sfx %d on channel %d with offset %d and len %d\n", n, channel, offset, length);
    //if(n==1 || n==5 || n ==0 || n == 4) {
    uint32_t n1 = now();
    play_sfx(&sfx[n]);
    play_sfx_buffer();
    uint32_t n2 = now();
    printf("took %d\n", n2 -n1);
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
            spriteCount = 0;
            continue;
        }
        if (strncmp(rawbuf, "__music__", 7) == 0) {
            section = SECT_MUSIC;
            continue;
        }
        if (section > SECT_SFX) {
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
            case SECT_SFX:
                decodeRLE((uint8_t*)decbuf, (uint8_t*)rawbuf, lineLen);
                SFXParser(decbuf, spriteCount, sfx);
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
    // hexDump("Sprites", spritesheet.flags, 256, 64);
    // hexDump("SFX 2", &sfx[1], 256, 64);
    printf("duration %d\n", sfx[1].duration);
    for(uint8_t i=0; i<32; i++) {
        Note n = sfx[1].notes[i];
        printf("key %d w %d vol %d fx %d\n", n.key, n.waveform, n.volume, n.effect);
    }
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
                const color_t p = palette[idx];
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
                const color_t p = palette[val];
                put_pixel(dx+x-drawstate.camera_x, screen_y, p);
            }
        }
    }
}
void gfx_circlefill(uint16_t x, uint16_t y, uint16_t radius, color_t color){
    if(x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) return;
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
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, color_t color){
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
void gfx_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, const color_t color) {
    for(uint16_t y=y0; y<y1-y0; y++)
        for(uint16_t x=x0; x<x1-x0; x++)
            put_pixel(x, y, color);
}

// callers have to ensure this is not called with x > SCREEN_WIDTH or y > SCREEN_HEIGHT
static inline void put_pixel(uint8_t x, uint8_t y, const color_t c){
    frontbuffer[(y*SCREEN_WIDTH+x)  ] = c;

}
void gfx_cls(color_t c) {
    memset(frontbuffer, c, sizeof(frontbuffer));
}

void gfx_rect(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const color_t color) {
    for(uint16_t y=y0; y<=y2; y++)
        for(uint8_t x=x0; x<=x2; x++)
            if ((y==y0) || (y==y2) || (x==x0) || (x==x2))
                put_pixel(x, y, color);
}

void gfx_rectfill(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const color_t color) {
    // this is _inclusive_
    y2 = MIN(SCREEN_HEIGHT-1, y2);
    x2 = MIN(SCREEN_WIDTH-1, x2);

    for(uint16_t y=y0; y<=y2; y++) {
        uint16_t yoff = y*SCREEN_WIDTH;
        for(uint16_t x=x0; x<=x2; x++) {
            frontbuffer[(yoff+x)  ] = color;
        }
    }
}


uint16_t get_pixel(uint8_t x, uint8_t y) {
	// FIXME: this is incredibly broken
	return frontbuffer[x+y*SCREEN_WIDTH];
}

void play_sfx(SFX* sfx) {
    z8::fix32 phi = 0;
    uint8_t volume = 96;

    const uint8_t SAMPLES_PER_DURATION = 183;
    float const offset_per_second = SAMPLE_RATE / (SAMPLES_PER_DURATION * sfx->duration);
    float const offset_per_sample = offset_per_second / SAMPLE_RATE;
    printf("Each sample lasts %f\n", offset_per_sample);

    memset(audiobuf, 0, sizeof(audiobuf));
    //for(uint16_t s=0; s<32; s++) {
    const uint16_t samples = SAMPLES_PER_DURATION * sfx->duration;

    uint16_t lastWithVolume = 0;
    // FIXME: 32 notes; but overflows
    for(uint16_t s=offset; s<32; s++) {
        // TODO: this plays all notes; maybe should stop?
        Note n = sfx->notes[s];
        if (n.volume == 0) {
            continue;
        }
        lastWithVolume = s;
        const z8::fix32 freq = key_to_freq[n.key];
        const z8::fix32 delta = freq / SAMPLE_RATE;
        const z8::fix32 norm_vol = VOL_NORMALIZER*n.volume;
        const uint16_t sample_offset = s*samples;
        const uint16_t n_effect = n.effect; // alias for memory access?

        for(uint16_t i=0; i<samples; i++) {
            // this will be called ~11 thousand times at duration 2
            // more at higher speeds?
            const z8::fix32 w = waveform(n_effect, phi);
            const int16_t sample = (int16_t)(norm_vol*w);
            // const uint16_t offset = sample_offset+(i*2);

            audiobuf[sample_offset+i] = sample;
            //audiobuf[sample_offset+i] = (sample >> 8)| ((sample & 0x00FF) << 8);
            //audiobuf[offset  ] = sample >> 8;
            //audiobuf[offset+1] = sample & 0x00ff;

            phi = phi + delta;
        }
    }

    // 30 = notes
    // 2 = uint16
    // samples = len
    bytesLeft = (lastWithVolume-offset)*samples; // sizeof(audiobuf);
}
#endif
