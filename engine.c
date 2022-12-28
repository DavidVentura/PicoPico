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
static Spritesheet hud_sprites;
static uint8_t map_data[64 * 128];
static uint32_t bootup_time;
static color_t frontbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];
static uint8_t hud_buffer[SCREEN_WIDTH*HUD_HEIGHT*2];

// TODO: consider shifting << 2**12 (slightly above max range) or 2**11
const z8::fix32 VOL_NORMALIZER = 32767.99f/7.f;

static SFX sfx[64];
static Channel channels[4];
const uint8_t SAMPLES_PER_BUFFER = 6;

uint16_t audiobuf[SAMPLES_PER_DURATION*SAMPLES_PER_BUFFER];
//
// this is can fit an SFX of duration 1;
// so filling this buffer $duration times will play an entire SFX
// it could be anywhere from 1x to 32x
// at 1x, this buffers 5.46ms of data
// and at 32x; 174ms
// 4x sounds reasonable; 21.8ms             (1464 bytes)
// 6x is 32.76 ~ 1 frame (33ms)             (2196 bytes)
// 8x is 43.6ms which is fairly noticeable  (2928 bytes)
// --------
// this total should not exceed 4092 bytes; which is the max supported by ESP32
// which means choices are between 4 and 8

// return 440.f * exp2f((key - 33.f) / 12.f);
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
void render_many(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y, z8::fix32 width, z8::fix32 height);
inline void _fast_render(Spritesheet* s, uint16_t sx, uint16_t sy, int16_t x0, int16_t y0);
static inline void put_pixel(uint8_t x, uint8_t y, const color_t p);
uint16_t get_pixel(uint8_t x, uint8_t y);
static void map(uint8_t mapX, uint8_t mapY,
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

static void map(uint8_t mapX, uint8_t mapY, int16_t screenX, int16_t screenY, uint8_t cellW, uint8_t cellH, uint8_t layerFlags=0) {

    const uint8_t sprite_count = 16;

    for(uint8_t y = mapY; y < mapY+cellH; y++) {
        int16_t ty = screenY+(y-mapY)*8;

        for(uint8_t x = mapX; x < mapX+cellW; x++) {
            uint8_t sprite = map_data[x+y*128];
            if(sprite==0) continue;

            int16_t tx = screenX+(x-mapX)*8;
            uint8_t flags = spritesheet.flags[sprite];
            const uint8_t xIndex = sprite % sprite_count;
            const uint8_t yIndex = sprite / sprite_count;

            if ((flags & layerFlags) == layerFlags && sprite != 0) {
                render(&spritesheet, sprite, tx, ty, -1, false, false);
            }
        }
    }
}

void _print(const char* text, const uint8_t textLen, int16_t x, int16_t y, int16_t paletteIdx) {
    // FIXME: this only works for ascii
    // FIXME: this should crop, and return the "cropped" number
    drawstate.pen_color = paletteIdx;

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

}
int _lua_print(lua_State* L) {
    int16_t textLen = 0;
    const char* text = luaL_checklstring(L, 1, (size_t*)&textLen);
    const int16_t x = luaL_checkinteger(L, 2);
    const int16_t y = luaL_checkinteger(L, 3);
    const int16_t paletteIdx = luaL_optinteger(L, 4, drawstate.pen_color);

    _print(text, textLen, x, y, paletteIdx);
    lua_pushnumber(L, x + textLen * 4);
    return 1;
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


void _replace_palette(uint8_t palIdx, lua_State* L) {
    // Push another reference to the table on top of the stack (so we know
    // where it is, and this function can work for negative, positive and
    // pseudo indices
    lua_pushvalue(L, -1);
    // stack now contains: -1 => table
    lua_pushnil(L);
    // stack now contains: -1 => nil; -2 => table
    while (lua_next(L, -2))
    {
        // stack now contains: -1 => value; -2 => key; -3 => table
        const uint8_t value = luaL_checkinteger(L, -1);
        const uint8_t key = luaL_checkinteger(L, -2);
        palette[key] = value; // replace color
        // pop value, leaving original key
        lua_pop(L, 1);
        // stack now contains: -1 => key; -2 => table
    }
    // stack now contains: -1 => table (when lua_next returns 0 it pops the key
    // but does not push anything.)
    // Pop table
    lua_pop(L, 1);
    // Stack is now the same as it was on entry to this function
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
    if(lua_istable(L, 1)) {
        uint8_t palIdx = luaL_optinteger(L, 2, 0);
        _replace_palette(palIdx, L);
        return 0;
    }

    int origIdx = luaL_checkinteger(L, 1);
    int newIdx = luaL_checkinteger(L, 2);
    const color_t origColor = palette[origIdx];
    const color_t newColor = original_palette[newIdx];

    palette[origIdx] = newColor;
    return 0;
}

inline void cls(uint8_t palIdx = 0) {
    color_t color = palette[palIdx];
    gfx_cls(color);
}
int _lua_cls(lua_State* L) {
    uint8_t palIdx = luaL_optinteger(L, 1, 0);
    cls(palIdx);
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

inline void spr(int8_t n, z8::fix32 x, z8::fix32 y, z8::fix32 w = z8::fix32(1.0f), z8::fix32 h = z8::fix32(1.0f), bool flip_x = false, bool flip_y = false) {
    render_many(&spritesheet, n, (int8_t)x, (int8_t)y, -1, flip_x==1, flip_y==1, w, h);
}

int _lua_spr(lua_State* L) {
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

    spr(n, x, y, w, h, flip_x, flip_y);

    return 0;
}

int _lua_line(lua_State* L) {
    //TODO: handle all cases https://pico-8.fandom.com/wiki/Line
    uint8_t x0 = luaL_optinteger(L, 1, drawstate.line_x);
    uint8_t y0 = luaL_optinteger(L, 2, drawstate.line_y);
    uint8_t x1 = luaL_optinteger(L, 3, 0);
    uint8_t y1 = luaL_optinteger(L, 4, 0);
    int col = luaL_optinteger(L, 5, drawstate.pen_color);
    drawstate.pen_color = col;
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
    int col = luaL_optinteger(L, 5, drawstate.pen_color);
    drawstate.pen_color = col;
	    
    gfx_rect(x, y, x2, y2, palette[col]);
    return 0;
}

int _lua_rectfill(lua_State* L) {
    int8_t x = luaL_checkinteger(L, 1);
    int8_t y = luaL_checkinteger(L, 2);
    int8_t x2 = luaL_checkinteger(L, 3);
    int8_t y2 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_rectfill(x, y, x2, y2, palette[col]);
    return 0;
}

int _lua_circ(lua_State* L) {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_optinteger(L, 3, 4);
    int col = luaL_optinteger(L, 4, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_circle(x-drawstate.camera_x, y-drawstate.camera_y, r, palette[col]);
    return 0;
}

int _lua_circfill(lua_State* L) {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_optinteger(L, 3, 4);
    int col = luaL_optinteger(L, 4, drawstate.pen_color);
    drawstate.pen_color = col;

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

    map(mapX, mapY, screenX, screenY, cellW, cellH, layerFlags);
    return 0;
}

uint8_t btn(uint8_t idx) {
    return buttons[idx];
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
    lua_pushboolean(L, btn(idx));
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

inline uint8_t _sget(int16_t x, int16_t y) {
    if (x < 0 || x > 127 || y < 0 || y > 127)
        return 0;
    return spritesheet.sprite_data[y*128+x];
}
int _lua_sget(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);

    lua_pushinteger(L, _sget(x, y));
    return 1;
}

int _lua_fget(lua_State* L) {
    uint8_t n = luaL_checkinteger(L, 1);
    uint8_t bitfield = luaL_optinteger(L, 2, 0xFF);

    uint8_t p = spritesheet.flags[n];
    if (bitfield == 0xFF) {
        lua_pushinteger(L, p);
    } else {
        bool result = ((1 << bitfield) & p) > 0;
        lua_pushboolean(L, result);
    }
    return 1;
}

int _lua_mset(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint8_t n = luaL_checkinteger(L, 3);
    map_data[y*128+x] = n;
    return 0;
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

inline void _pset(int16_t x, int16_t y, int16_t idx) {
    drawstate.pen_color = idx;
    if(drawstate.transparent[idx] == 1)
        return;
    int16_t tx = x-drawstate.camera_x;
    int16_t ty = y-drawstate.camera_y;
    if (tx < 0 || tx >= SCREEN_WIDTH || ty < 0 || ty  >= SCREEN_HEIGHT) return;
    put_pixel(tx, ty, palette[idx]);
}

int _lua_pset(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);
    uint8_t idx = luaL_optinteger(L, 3, drawstate.pen_color);
    _pset(x, y, idx);
    return 0;
}

int _lua_time(lua_State* L) {
    float delta = (float)(now() - bootup_time);
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


int _lua_stat(lua_State* L) {
    uint8_t n = luaL_checkinteger(L, 1);
    if (n >=16 && n<=26) // 16..26 == 46..56
        n += 30;
    switch(n) {
        case 49: // 19 also -- sfx id
            if (channels[3].sfx == NULL) {
                lua_pushinteger(L, -1);
            } else {
                lua_pushinteger(L, channels[3].sfx_id);
            }
            break;
        case 53: // 23 also -- note number
            if (channels[3].sfx == NULL) {
                lua_pushinteger(L, -1);
            } else {
                uint16_t note_id = channels[3].offset / (SAMPLES_PER_DURATION * channels[3].sfx->duration);
                lua_pushinteger(L, note_id);
            }
            break;
        case 102: // bbs information: domain if web; 0 for local
            lua_pushinteger(L, 0);
            break;
        default:
            printf("Warn: got stat(%d) which is not implemented\n", n);
            lua_pushinteger(L, 0);
    }
    return 1;
}

int _lua_sfx(lua_State* L) {
    int16_t n       = luaL_optinteger(L, 1, -1);
    int16_t channel = luaL_optinteger(L, 2, -1);
    int16_t offset  = luaL_optinteger(L, 3, 0);
    int16_t length  = luaL_optinteger(L, 4, 31);
    if(channel == -1) {
        for(uint8_t i=0; i<4; i++) {
            if (channels[i].sfx == NULL) {
                // FIXME: still have to ignore music
                channel = i;
                break;
            }
        }
        if (channel == -1) {
            printf("no empty channels! kicking sfx from #0\n");
            channel = 0;
        }
    }

    if(n==-1) { // NULL SFX
        channels[channel].sfx      = NULL;
        channels[channel].sfx_id   = 0;
        channels[channel].offset   = 0;
        channels[channel].phi      = 0;
        return 0;
    }

    // channels[channel].length = 0; // TODO
    channels[channel].offset    = 0; // TODO
    channels[channel].sfx       = &sfx[n];
    channels[channel].sfx_id    = n;
    channels[channel].phi       = 0;

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

int _lua_clip(lua_State* L) {
    uint8_t old_x = drawstate.clip_x;
    uint8_t old_y = drawstate.clip_y;
    uint8_t old_w = drawstate.clip_w;
    uint8_t old_h = drawstate.clip_h;

    uint8_t argcount = lua_gettop(L);
    if(argcount == 0) {
        drawstate.clip_x = 0;
        drawstate.clip_y = 0;
        drawstate.clip_w = SCREEN_WIDTH;
        drawstate.clip_h = SCREEN_HEIGHT;
    } else {
        uint8_t x = luaL_checkinteger(L, 1);
        uint8_t y = luaL_checkinteger(L, 2);
        uint8_t w = luaL_checkinteger(L, 3);
        uint8_t h = luaL_checkinteger(L, 4);
        bool previous = lua_toboolean(L, 5);

        if (previous == true) {
            drawstate.clip_x += x;
            drawstate.clip_y += y;
        } else {
            drawstate.clip_x = x;
            drawstate.clip_y = y;
        }

        drawstate.clip_w = w;
        drawstate.clip_h = h;
    }

    lua_pushinteger(L, old_x);
    lua_pushinteger(L, old_y);
    lua_pushinteger(L, old_w);
    lua_pushinteger(L, old_h);
    return 4;
}

int _lua_color(lua_State* L) {
    uint8_t c = luaL_optinteger(L, 1, 6);
    uint8_t old_color = drawstate.pen_color;
    drawstate.pen_color = c;
    lua_pushinteger(L, old_color);
    return 1;
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
    uint8_t* decbuf = (uint8_t*)malloc(129);
    // 128 bytes per line of data
    // 1 byte per line for \0

    uint16_t lineLen = 0;
    memset(decbuf, 0, 129);
    memset(rawbuf, 0, 129);
    do {
	    lineLen = readLine(&text, rawbuf);
	    decodeRLE(decbuf, rawbuf, lineLen);
	    gfxParser(decbuf, spriteCount, sheet);
	    spriteCount++;
    } while (*text != 0);
    free(decbuf);
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


// position is an index, from the right
inline void _draw_hud_sprite(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t xOffset, uint16_t yOffset) {
    for (uint16_t y=(sy*8); y<((sy+1)*8); y++) {
        for (uint16_t x=(sx*8); x<((sx+1)*8); x++) {
            uint8_t val = s->sprite_data[y*SCREEN_WIDTH + x];
            if (val > 0) {
                const color_t p = original_palette[val];
                uint16_t first_byte = (((y+yOffset)-(sy*8))*SCREEN_WIDTH*2+(x-(sx*8))*2 + xOffset);
                hud_buffer[first_byte  ] = (p >> 8);
                hud_buffer[first_byte+1] = p & 0xFF;
            }
        }
    }
}
inline void _fast_render(Spritesheet* s, uint16_t sx, uint16_t sy, int16_t x0, int16_t y0) {
    uint16_t val;

    int16_t ymin = MAX(0, -(y0-drawstate.camera_y));
    int16_t xmin = MAX(0, -(x0-drawstate.camera_x));

    int16_t ymax = 8;
    int16_t xmax = 8;

    ymax = MAX(0, MIN(SCREEN_HEIGHT-(int16_t)(y0-drawstate.camera_y), ymax));
    xmax = MAX(0, MIN(SCREEN_WIDTH -(int16_t)(x0-drawstate.camera_x), xmax));

    xmin = MIN(xmin, xmax);
    ymin = MIN(ymin, ymax);

    if(xmin>=xmax) return;

    for (uint16_t y=ymin; y<ymax; y++) {
        int16_t screen_y = y0+y-drawstate.camera_y;

        for (uint16_t x=xmin; x<xmax; x++) {
            uint16_t screen_x = x0+x-drawstate.camera_x;
            // if (screen_x >= SCREEN_WIDTH) break;
            val = s->sprite_data[(sy+y)*128 + x + sx];
            if (drawstate.transparent[val] == 0) {
                const color_t p = palette[val];
                put_pixel(screen_x, screen_y, p);
            }
        }
    }
}

void _render(Spritesheet* s, uint16_t sx, uint16_t sy, int16_t x0, int16_t y0, int paletteIdx, bool flip_x, bool flip_y, z8::fix32 width, z8::fix32 height) {
    color_t p;
    uint16_t val;

    int16_t ymin = MAX(0, -(y0-drawstate.camera_y));
    int16_t xmin = MAX(0, -(x0-drawstate.camera_x));

    int16_t ymax = z8::fix32::ceil(8*height);
    int16_t xmax = z8::fix32::ceil(8*width);

//    ymax = MAX(0, MIN((SCREEN_HEIGHT-1)-(int16_t)(y0-drawstate.camera_y+ymax), ymax));
//    xmax = MAX(0, MIN((SCREEN_WIDTH -1)-(int16_t)(x0-drawstate.camera_x+xmax), xmax));

    xmin = MIN(xmin, xmax);
    ymin = MIN(ymin, ymax);

    if(xmin>=xmax) return;

    for (uint16_t y=ymin; y<ymax; y++) {
        int16_t screen_y = y0+y-drawstate.camera_y;
        //if (screen_y < 0) continue;
        if (screen_y >= SCREEN_HEIGHT) return;

        for (uint16_t x=xmin; x<xmax; x++) {
            uint16_t screen_x = x0+x-drawstate.camera_x;
            if (screen_x >= SCREEN_WIDTH) break;
            val = s->sprite_data[(sy+y)*128 + x + sx];
            if (drawstate.transparent[val] != 0) {
                continue;
            }

            if (paletteIdx != -1) {
                p = palette[paletteIdx];
            } else {
                p = palette[val];
            }

            if(flip_x) {
                put_pixel(screen_x+8-2*x, screen_y, p);
            } else {
                put_pixel(screen_x, screen_y, p);
            }

        }
    }
}

inline void render_many(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y, z8::fix32 width, z8::fix32 height) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = n % sprite_count;
    const uint8_t yIndex = n / sprite_count;
    _render(s, xIndex*8, yIndex*8, x0, y0, paletteIdx, flip_x, flip_y, width, height);
}

inline void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = n % sprite_count;
    const uint8_t yIndex = n / sprite_count;
    _render(s, xIndex*8, yIndex*8, x0, y0, paletteIdx, flip_x, flip_y, 1, 1);
}

void render_stretched(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t sw, uint16_t sh, uint16_t dx, uint16_t dy,
		      uint16_t dw, uint16_t dh) {
    if(dw == sw && dh == sh) return _render(s, sx, sy, dx, dy, -1, false, false, 1, 1);
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
    uint16_t r_sq = radius * radius;
    if(x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) return;
    for (int w = 0; w <= radius * 2; w++) {
        int dx = radius - w; // horizontal offset
        uint16_t dx_sq = dx * dx;
        if((x + dx) < 0) continue;
        if((x + dx) >= SCREEN_WIDTH) break;
        for (int h = 0; h <= radius * 2; h++) {
            int dy = radius - h; // vertical offset
            if((y + dy) >= SCREEN_HEIGHT) break;
            if((y + dy) < 0) continue;
            if ((dx_sq + dy*dy) <= r_sq) {
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
    x0 = MIN(x0, SCREEN_WIDTH-1);
    x2 = MIN(x2, SCREEN_WIDTH-1);
    y0 = MIN(y0, SCREEN_HEIGHT-1);
    y2 = MIN(y2, SCREEN_HEIGHT-1);

    for(uint16_t y=y0; y<=y2; y++)
        for(uint8_t x=x0; x<=x2; x++)
            if ((y==y0) || (y==y2) || (x==x0) || (x==x2))
                put_pixel(x, y, color);
}

void gfx_rectfill(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const color_t color) {
    // this is _inclusive_
    x0 = MIN(x0, SCREEN_WIDTH-1);
    x2 = MIN(x2, SCREEN_WIDTH-1);
    y0 = MIN(y0, SCREEN_HEIGHT-1);
    y2 = MIN(y2, SCREEN_HEIGHT-1);

    for(uint16_t y=y0; y<=y2; y++) {
        uint16_t yoff = y*SCREEN_WIDTH;
        for(uint16_t x=x0; x<=x2; x++) {
            frontbuffer[(yoff+x)  ] = color;
        }
    }
}


inline uint16_t get_pixel(uint8_t x, uint8_t y) {
	// FIXME: this is incredibly broken
	return frontbuffer[x+y*SCREEN_WIDTH];
}

void fill_buffer(uint16_t* buf, Channel* c, uint16_t samples) {
    SFX* sfx = c->sfx;
    if(sfx == NULL) {
        return;
    }

    // buffer sizes are always multiples of SAMPLES_PER_DURATION
    // which ensures the notes will always play _entire_ "duration" blocks
    for(uint16_t s=0; s<samples; s++) {
        uint16_t note_id = c->offset / (SAMPLES_PER_DURATION * sfx->duration);

        Note n = sfx->notes[note_id];
        z8::fix32 freq = key_to_freq[n.key];
        const z8::fix32 delta = freq / SAMPLE_RATE;

        c->offset += SAMPLES_PER_DURATION;
        if (n.volume == 0) {
            c->phi += SAMPLES_PER_DURATION * delta;
            s += SAMPLES_PER_DURATION-1;
            continue;
        }
        // printf("Note id %d has fx %d\n", note_id, n.effect);
        z8::fix32 volume = n.volume; // can be modified by `n.effect`

        const z8::fix32 norm_vol = VOL_NORMALIZER*volume;
        // const uint16_t n_effect = n.effect; // alias for memory access?
        const uint16_t n_waveform = n.waveform; // alias for memory access?

        for(uint16_t _s=0; _s<SAMPLES_PER_DURATION; _s++) {
            // TODO: apply FX per _sample_ ?? gonna suck
            const z8::fix32 w = waveform(n_waveform, c->phi);
            const int16_t sample = (int16_t)(norm_vol*w);
            uint16_t _offset = (_s+s);

            // NOTE: this is += so that all sfx can be played in parallel
            buf[_offset] += sample;
            if(buf[_offset] < sample) // wrap around
                buf[_offset] = USHRT_MAX;

            c->phi += delta;
        }

        s += SAMPLES_PER_DURATION-1;
    }

    if(c->offset >= (SAMPLES_PER_DURATION*NOTES_PER_SFX*sfx->duration)) {
        c->sfx      = NULL;
        c->sfx_id   = 0;
        c->offset   = 0;
        c->phi      = 0;
    }
}
#endif
