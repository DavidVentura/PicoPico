#define ENGINE
#include "data.h"
#include "parser.c"
#include <string.h>

lua_State *L = NULL;
int buttons[6] = {0};

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

void render(Spritesheet* s, uint8_t n, uint8_t x0, uint8_t y0, int paletteIdx);
static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p);
static void gfx_map(uint8_t mapX, uint8_t mapY,
		    uint8_t screenX, uint8_t screenY,
		    uint8_t cellW, uint8_t cellH, uint8_t layerFlags);
void gfx_cls(uint8_t*);
void gfx_rect(uint8_t x, uint8_t y, uint8_t w, uint8_t h, const uint8_t* color);
void gfx_rectfill(uint8_t x, uint8_t y, uint8_t w, uint8_t h, const uint8_t* color);
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color);
bool init_video();
bool handle_input();
void delay(uint8_t ms);
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
lua_State* init_lua(const char* script_text) {
    lua_State *state = luaL_newstate();
    luaL_openlibs(state);

    if (luaL_dostring(state, stdlib_stdlib_lua) == LUA_OK) {
	lua_pop(state, lua_gettop(state));
    }

    if (luaL_dostring(state, script_text) == LUA_OK) {
	lua_pop(state, lua_gettop(state));
	return state;
    }
    puts(lua_tostring(state, lua_gettop(state)));
    lua_close(state);
    return NULL;
}

void engine_init() {
    memset(drawstate.transparent, 0, sizeof(drawstate.transparent));
    drawstate.transparent[0] = 1;

    memset(&fontsheet.sprite_data, 0xFF, 128*120);
    memset(map_data, 0, sizeof(map_data));
}
void fontParser(char* text) {
    int spriteCount = 0;
    char* buf = (char*)malloc(129);
    do {
	readLine(&text, buf);
	gfxParser(buf, spriteCount, &fontsheet);
	spriteCount++;
    } while (*text != 0);
    free(buf);
}

void cartParser(char* text) {
    uint8_t section = 0;
    uint32_t spriteCount = 0;
    char* buf = (char*)malloc(257);
    memset(buf, 0, 257);
    memset(cart.code, 0, sizeof(cart.code));

    uint32_t lineLen = 0;
    uint32_t bytesRead = 0;
    do {
	lineLen = readLine(&text, buf);
	if (strncmp(buf, "__lua__", 7) == 0) {
	    section = SECT_LUA;
	    bytesRead = 0;
	    continue;
	}
	if (strncmp(buf, "__gfx__", 7) == 0) {
	    section = SECT_GFX;
	    spriteCount = 0;
	    bytesRead = 0;
	    continue;
	}
	if (strncmp(buf, "__gff__", 7) == 0) {
	    section = SECT_GFF;
	    continue;
	}
	if (strncmp(buf, "__label__", 7) == 0) {
	    section = SECT_LABEL;
	    continue;
	}
	if (strncmp(buf, "__map__", 7) == 0) {
	    section = SECT_MAP;
	    spriteCount = 0;
	    bytesRead = 0;
	    continue;
	}
	if (strncmp(buf, "__sfx__", 7) == 0) {
	    section = SECT_SFX;
	    continue;
	}
	if (strncmp(buf, "__music__", 7) == 0) {
	    section = SECT_MUSIC;
	    continue;
	}
	if (section > SECT_MAP) {
		break;
	}
	switch (section) {
	    case SECT_LUA:
		memcpy(cart.code+bytesRead, buf, lineLen);
		break;
	    case SECT_GFX:
		gfxParser(buf, spriteCount, &spritesheet);
		spriteCount++;
		break;
	    case SECT_MAP:
		mapParser(buf, spriteCount, map_data);
		spriteCount++;
		break;
	}
	bytesRead += lineLen;
    } while (*text != 0);
    free(buf);
}

void _render(Spritesheet* s, uint8_t sx, uint8_t sy, uint8_t x0, uint8_t y0, int paletteIdx) {
    uint8_t idx, val;

    for (uint8_t y=0; y<8; y++) {
	for (uint8_t x=0; x<8; x++) {
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
void render(Spritesheet* s, uint8_t n, uint8_t x0, uint8_t y0, int paletteIdx) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = n % sprite_count;
    const uint8_t yIndex = n / sprite_count;
    _render(s, xIndex*8, yIndex*8, x0, y0, paletteIdx);
}

void render_stretched(Spritesheet* s, uint8_t sx, uint8_t sy, uint8_t sw, uint8_t sh, uint8_t dx, uint8_t dy,
		      uint8_t dw, uint8_t dh) {
    if(dw == sw && dh == sh) return _render(s, sx, sy, dx, dy, -1);

    // TODO: this does not clip or flip
    uint32_t ratio_x = (sw << 16)/ dw;
    uint32_t ratio_y = (sh << 16)/ dh;
    for (uint8_t y=0; y<dh; y++) {
	uint16_t yoff = (((y*ratio_y)>>16)+sy)*128;
	for (uint8_t x=0; x<dw; x++) {
	    uint8_t val = s->sprite_data[yoff + ((x*ratio_x) >> 16)+sx];
	    if (drawstate.transparent[val] == 0){
		    const uint8_t* p = palette[val];
		    put_pixel(dx+x-drawstate.camera_x, dy+y-drawstate.camera_y, p);
	    }
	}
    }
}
