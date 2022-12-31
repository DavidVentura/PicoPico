#include "data.h"
#include "engine.h"
#include "backend.h"

static uint32_t cartdata[64];
static Spritesheet spritesheet;
static Spritesheet fontsheet;
static uint8_t map_data[64 * 128];
static uint32_t bootup_time;
static palidx_t frontbuffer[SCREEN_WIDTH/2*SCREEN_HEIGHT];

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

// callers have to ensure this is not called with x > SCREEN_WIDTH or y > SCREEN_HEIGHT
static inline void put_pixel(uint8_t x, uint8_t y, palidx_t p){
    if (x&0x1) {
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] &= 0x0f;
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] |= (p << 4);
    } else {
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] &= 0xf0;
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] |= p;
    }

}

void gfx_circlefill(uint16_t x, uint16_t y, uint16_t radius, palidx_t p){
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
                put_pixel(x + dx, y + dy, p);
            }
        }
    }
}
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, palidx_t color){
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
void gfx_cls(palidx_t c) {
    memset(frontbuffer, ((c & 0xf) << 4) | (c & 0xf), sizeof(frontbuffer));
}

void gfx_rect(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const palidx_t color) {
    x0 = MIN(x0, SCREEN_WIDTH-1);
    x2 = MIN(x2, SCREEN_WIDTH-1);
    y0 = MIN(y0, SCREEN_HEIGHT-1);
    y2 = MIN(y2, SCREEN_HEIGHT-1);

    for(uint16_t y=y0; y<=y2; y++)
        for(uint8_t x=x0; x<=x2; x++)
            if ((y==y0) || (y==y2) || (x==x0) || (x==x2))
                put_pixel(x, y, color);
}

void gfx_rectfill(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const palidx_t color) {
    // this is _inclusive_
    x0 = MIN(x0, SCREEN_WIDTH-1);
    x2 = MIN(x2, SCREEN_WIDTH-1);
    y0 = MIN(y0, SCREEN_HEIGHT-1);
    y2 = MIN(y2, SCREEN_HEIGHT-1);

    for(uint16_t y=y0; y<=y2; y++) {
        for(uint16_t x=x0; x<=x2; x++) {
            put_pixel(x, y, color);
        }
    }
}


inline palidx_t get_pixel(uint8_t x, uint8_t y) {
    if (x&0x1) {
        return (frontbuffer[(y*SCREEN_WIDTH/2+x/2)] & 0xf0) >> 4;
    } else {
        return (frontbuffer[(y*SCREEN_WIDTH/2+x/2)] & 0x0f);
    }
}


static void map(int16_t mapX, int16_t mapY, int16_t screenX, int16_t screenY, uint8_t cellW, uint8_t cellH, uint8_t layerFlags=0) {

    //Map at 0 -16, S 0 0, C 16 16, F 4
    if(mapX<0) return;
    if(mapY<0) return;
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

void render_text(Spritesheet* s, uint16_t sprite, uint8_t x0, uint8_t y0) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = sprite % sprite_count;
    const uint8_t yIndex = sprite / sprite_count;
    uint8_t val;

    for (uint8_t y=0; y<8; y++) {
        if ((y+y0) >= SCREEN_HEIGHT) return;
        // TODO: memcpy if far from edges
        for (uint8_t x=0; x<8; x++) {
            if ((x+x0) >= SCREEN_WIDTH) break;
            val = s->sprite_data[y*128 + x + xIndex*8 + yIndex*8*128];
            if (val!=0) {
                put_pixel(x0+x, y0+y, drawstate.pen_color);
            }
        }
    }
}

void _print(const char* text, const uint8_t textLen, int16_t x, int16_t y, int16_t paletteIdx) {
    // FIXME: this only works for ascii
    // FIXME: this should crop, and return the "cropped" number
    drawstate.pen_color = paletteIdx;

    for (int i = 0; i<textLen; i++) {
        uint8_t c = text[i];
        if (c == 0xe2) { // ❎ = 0xe2 0x9d 0x8e
            c = 151; // X in font
            render_text(&fontsheet, c, x + i * 4 + 2, y);
            i += 2;
        }
        else if (c == 0xf0) { // 🅾  = 0xf0 0x9f 0x85 0xbe
            c = 142; // "circle" in font (square)
            render_text(&fontsheet, c, x + i * 4 + 2, y);
            i += 3;
        } else {
            render_text(&fontsheet, c, x + i * 4, y);
        }
    }

}

void gfx_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, const palidx_t color) {
    for(uint16_t y=y0; y<=y1; y++)
        for(uint16_t x=x0; x<=x1; x++)
            put_pixel(x, y, color);
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
    lua_pushvalue(L, 1);
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
    gfx_cls(palIdx);
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
    gfx_line(x0, y0, x1, y1, col);
    return 0;
}

int _lua_rect(lua_State* L) {
    uint8_t x = luaL_checkinteger(L, 1);
    uint8_t y = luaL_checkinteger(L, 2);
    uint8_t x2 = luaL_checkinteger(L, 3);
    uint8_t y2 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, drawstate.pen_color);
    drawstate.pen_color = col;
	    
    gfx_rect(x, y, x2, y2, col);
    return 0;
}

int _lua_rectfill(lua_State* L) {
    int8_t x = luaL_checkinteger(L, 1);
    int8_t y = luaL_checkinteger(L, 2);
    int8_t x2 = luaL_checkinteger(L, 3);
    int8_t y2 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_rectfill(x, y, x2, y2, col);
    return 0;
}

int _lua_circ(lua_State* L) {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_optinteger(L, 3, 4);
    int col = luaL_optinteger(L, 4, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_circle(x-drawstate.camera_x, y-drawstate.camera_y, r, col);
    return 0;
}

int _lua_ovalfill(lua_State* L) {
    // FIXME  this is just a circle..
    int x0 = luaL_checkinteger(L, 1);
    int y0 = luaL_checkinteger(L, 2);
    int x1 = luaL_checkinteger(L, 3);
    int y1 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_circlefill(x0-drawstate.camera_x, y0-drawstate.camera_y, x1-x0, col);
    return 0;
}

int _lua_circfill(lua_State* L) {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_optinteger(L, 3, 4);
    int col = luaL_optinteger(L, 4, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_circlefill(x-drawstate.camera_x, y-drawstate.camera_y, r, col);
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

uint8_t btn(lua_State* L, uint8_t* _buttons) {
    uint8_t argcount = lua_gettop(L);
    if (argcount == 0) {
	uint8_t bitfield = 0;
	for(uint8_t i=0; i<6; i++) {
	    bitfield |= ((_buttons[i]) << i);
	}
    	return bitfield;
    } else if (argcount == 1) {
    	int idx = luaL_optinteger(L, 1, -1);
	if(idx==-1) return 0;
    	return _buttons[idx];
    } else {
	printf("Unsupported btn/btnp with 2 args\n");
    	return 0;
    }
}
int _lua_btnp(lua_State* L) {
    lua_pushboolean(L, btn(L, buttons_frame));
    return 1;
}
int _lua_btn(lua_State* L) {
    lua_pushboolean(L, btn(L, buttons));
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
    uint16_t x = luaL_checkinteger(L, 1);
    uint16_t y = luaL_checkinteger(L, 2);
    uint8_t n = luaL_checkinteger(L, 3);
    map_data[y*128+x] = n;
    return 0;
}

int _lua_mget(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);
    if (x<0 || y<0) {
    	lua_pushinteger(L, 0);
    	return 1;
    }
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
    put_pixel(tx, ty, idx);
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
    fflush(stdout);
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

int _lua_poke(lua_State* L) {
    uint8_t argcount = lua_gettop(L);
    uint16_t addr = luaL_checkinteger(L, 1);
    for(uint8_t arg=0; arg<argcount-1; arg++){
	uint8_t value = luaL_checkinteger(L, 2+arg);
	// printf("Writing %d to %d\n", value, addr+arg);
	ram[addr+arg] = value;
    }
    return 0;
}

int _lua_flip(lua_State* L) {
    flip();
    return 0;
}

int _lua_fillp(lua_State* L) {
    uint8_t argcount = lua_gettop(L);
    // TODO: implement fillp
    if (argcount==0) {
        return 0;
    }
    uint16_t addr = luaL_checkinteger(L, 1);
    return 0;
}
int _lua_reload(lua_State* L) {
    uint8_t argcount = lua_gettop(L);
    // TODO: implement reload
    if (argcount==0) {
        return 0;
    }
    return 0;
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
                put_pixel(screen_x, screen_y, val);
            }
        }
    }
}

void _render(Spritesheet* s, uint16_t sx, uint16_t sy, int16_t x0, int16_t y0, int paletteIdx, bool flip_x, bool flip_y, z8::fix32 width, z8::fix32 height) {
    palidx_t p;
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
                p = paletteIdx;
            } else {
                p = val;
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
                put_pixel(dx+x-drawstate.camera_x, screen_y, val);
            }
        }
    }
}