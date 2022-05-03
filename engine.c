#define ENGINE
#include "data.h"
#include "parser.c"
#include <string.h>

static lua_State *L = NULL;
int buttons[6] = {0};

static uint8_t ram[32768];
static Spritesheet spritesheet;
static Spritesheet fontsheet;
static uint8_t map_data[32 * 128];
static uint64_t bootup_time;

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

void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx);
static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p);
static void gfx_map(uint8_t mapX, uint8_t mapY,
		    uint8_t screenX, uint8_t screenY,
		    uint8_t cellW, uint8_t cellH, uint8_t layerFlags);
void gfx_cls(uint8_t*);
void gfx_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint8_t* color);
void gfx_rectfill(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint8_t* color);
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color);
bool init_video();
bool handle_input();
void delay(uint16_t ms);
void gfx_flip();
void video_close();
uint64_t now();

static void gfx_map(uint8_t mapX, uint8_t mapY,
		    uint8_t screenX, uint8_t screenY,
		    uint8_t cellW, uint8_t cellH, uint8_t layerFlags) {

    for(uint8_t y = mapY; y < mapY+cellH; y++) {
	for(uint8_t x = mapX; x < mapX+cellW; x++) {
	    render(&spritesheet, map_data[x+y*128], screenX+(x-mapX)*8, screenY+(y-mapY)*8, -1);
	}
    }
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

void engine_init() {
    memset(drawstate.transparent, 0, sizeof(drawstate.transparent));
    drawstate.transparent[0] = 1;

    memset(&fontsheet.sprite_data, 0xFF, 128*120);
    memset(map_data, 0, sizeof(map_data));
}
void fontParser(uint8_t* text) {
    int spriteCount = 0;
    uint8_t* rawbuf = (uint8_t*)malloc(129);
    uint8_t* decbuf = (uint8_t*)malloc(129);
    // 128 bytes per line of data
    // 1 byte per line for \0

    uint16_t lineLen = 0;
    do {
	lineLen = readLine(&text, rawbuf);
	decodeRLE(decbuf, rawbuf, lineLen);
	gfxParser(decbuf, spriteCount, &fontsheet);
	spriteCount++;
    } while (*text != 0);
    free(decbuf);
    free(rawbuf);
}

void cartParser(uint8_t* text) {
    uint8_t section = 0;
    uint32_t spriteCount = 0;
    char* rawbuf = (char*)malloc(258);
    char* decbuf = (char*)malloc(257);
    // up to 256 bytes per line
    // 1 byte for \0
    // 1 byte to indicate whether it's RLE-encoded

    memset(rawbuf, 0, 258);
    memset(cart.code, 0, sizeof(cart.code));

    uint16_t lineLen = 0;
    uint32_t bytesRead = 0;
    do {
	lineLen = readLine(&text, (uint8_t*)rawbuf);
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
	}
	switch (section) {
	    case SECT_LUA:
		memcpy(cart.code+bytesRead, rawbuf, lineLen);
		break;
	    case SECT_GFX:
		decodeRLE((uint8_t*)decbuf, (uint8_t*)rawbuf, lineLen);
		gfxParser((uint8_t*)rawbuf, spriteCount, &spritesheet);
		spriteCount++;
		break;
	    case SECT_MAP:
		decodeRLE((uint8_t*)decbuf, (uint8_t*)rawbuf, lineLen);
		mapParser(rawbuf, spriteCount, map_data);
		spriteCount++;
		break;
	}
	bytesRead += lineLen;
    } while (*text != 0);
    free(decbuf);
    free(rawbuf);
}

void _render(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t x0, uint16_t y0, int paletteIdx) {
    uint16_t idx, val;
    if(x0 >= SCREEN_WIDTH) return;
    if(y0 >= SCREEN_HEIGHT) return;

    for (uint16_t y=0; y<8; y++) {
	for (uint16_t x=0; x<8; x++) {
	    val = s->sprite_data[(sy+y)*128 + x + sx];
	    if (paletteIdx != -1) {
		    idx = paletteIdx;
	    } else {
		    idx = val;
	    }
	    if (drawstate.transparent[val] == 0) {
		    const uint8_t* p = palette[idx];
		    put_pixel(x0+x-drawstate.camera_x, y0+y-drawstate.camera_y, p);
	    }
	}
    }
}
void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = n % sprite_count;
    const uint8_t yIndex = n / sprite_count;
    _render(s, xIndex*8, yIndex*8, x0, y0, paletteIdx);
}

void render_stretched(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t sw, uint16_t sh, uint16_t dx, uint16_t dy,
		      uint16_t dw, uint16_t dh) {
    if(dw == sw && dh == sh) return _render(s, sx, sy, dx, dy, -1);
    if(dx >= SCREEN_WIDTH) return;
    if(dy >= SCREEN_HEIGHT) return;

    // TODO: this does not clip or flip
    uint32_t ratio_x = (sw << 16)/ dw;
    uint32_t ratio_y = (sh << 16)/ dh;
    for (uint16_t y=0; y<dh; y++) {
	uint16_t yoff = (((y*ratio_y)>>16)+sy)*128;
	for (uint16_t x=0; x<dw; x++) {
	    uint8_t val = s->sprite_data[yoff + ((x*ratio_x) >> 16)+sx];
	    if (drawstate.transparent[val] == 0){
		    const uint8_t* p = palette[val];
		    put_pixel(dx+x-drawstate.camera_x, dy+y-drawstate.camera_y, p);
	    }
	}
    }
}
