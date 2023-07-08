#include "pico8api.h"
#include "engine.h"
#include "backend.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lua.h"
#include "lua_math.h"
#include "lua_table.h"

void gfx_line(int16_t x0, int16_t y0, int16_t x1, int16_t y1, const palidx_t color);
// callers have to ensure this is not called with x > SCREEN_WIDTH or y > SCREEN_HEIGHT
void put_pixel(uint8_t x, uint8_t y, palidx_t p){
    if (x&0x1) {
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] &= 0x0f;
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] |= (pal_map[p] << 4);
    } else {
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] &= 0xf0;
        frontbuffer[(y*SCREEN_WIDTH/2+x/2)] |= pal_map[p];
    }
}

void guarded_put_pixel(int16_t x, int16_t y, palidx_t p){
	if(x>=0&&x<SCREEN_WIDTH && y<SCREEN_HEIGHT&&y>=0) {
		put_pixel(x, y, p);
	}
}

void gfx_ovalfill(int16_t x0, int16_t y0, int16_t x1, int16_t y1, palidx_t p){
   int a = abs (x1 - x0), b = abs (y1 - y0), b1 = b & 1; /* values of diameter */
   long dx = 4 * (1 - a) * b * b, dy = 4 * (b1 + 1) * a * a; /* error increment */
   long err = dx + dy + b1 * a * a, e2; /* error of 1.step */

   if (x0 > x1) { x0 = x1; x1 += a; } /* if called with swapped points */
   if (y0 > y1) y0 = y1; /* .. exchange them */
   y0 += (b + 1) / 2;
   y1 = y0-b1;   /* starting pixel */
   a *= 8 * a; b1 = 8 * b * b;
   do
   {
	   for(int16_t y=y1; y<=y0; y++){
		   guarded_put_pixel(x0, y, p);
		   guarded_put_pixel(x1, y, p);
	   }
       e2 = 2 * err;
       if (e2 >= dx)
       {
          x0++;
          x1--;
          err += dx += b1;
       } /* x step */
       if (e2 <= dy)
       {
          y0++;
          y1--;
          err += dy += a;
       }  /* y step */
   } while (x0 <= x1);
   while (y0-y1 < b)
   {  /* too early stop of flat ellipses a=1 */
       guarded_put_pixel(x0-1, y0, p); /* -> finish tip of ellipse */
       guarded_put_pixel(x1+1, y0++, p);
       guarded_put_pixel(x0-1, y1, p);
       guarded_put_pixel(x1+1, y1--, p);
   }
}

void gfx_oval(int16_t x0, int16_t y0, int16_t x1, int16_t y1, palidx_t p){
   int a = abs (x1 - x0), b = abs (y1 - y0), b1 = b & 1; /* values of diameter */
   long dx = 4 * (1 - a) * b * b, dy = 4 * (b1 + 1) * a * a; /* error increment */
   long err = dx + dy + b1 * a * a, e2; /* error of 1.step */

   if (x0 > x1) { x0 = x1; x1 += a; } /* if called with swapped points */
   if (y0 > y1) y0 = y1; /* .. exchange them */
   y0 += (b + 1) / 2;
   y1 = y0-b1;   /* starting pixel */
   a *= 8 * a; b1 = 8 * b * b;
   do
   {
       guarded_put_pixel(x1, y0, p); /*   I. Quadrant */
       guarded_put_pixel(x0, y0, p); /*  II. Quadrant */
       guarded_put_pixel(x0, y1, p); /* III. Quadrant */
       guarded_put_pixel(x1, y1, p); /*  IV. Quadrant */
       e2 = 2 * err;
       if (e2 >= dx)
       {
          x0++;
          x1--;
          err += dx += b1;
       } /* x step */
       if (e2 <= dy)
       {
          y0++;
          y1--;
          err += dy += a;
       }  /* y step */
   } while (x0 <= x1);
   while (y0-y1 < b)
   {  /* too early stop of flat ellipses a=1 */
       guarded_put_pixel(x0-1, y0, p); /* -> finish tip of ellipse */
       guarded_put_pixel(x1+1, y0++, p);
       guarded_put_pixel(x0-1, y1, p);
       guarded_put_pixel(x1+1, y1--, p);
   }
}

void gfx_circlefill(int16_t x, int16_t y, int16_t radius, palidx_t p){
    uint32_t r_sq = radius * radius;
    for (int w = 0; w <= radius * 2; w++) {
        int dx = radius - w; // horizontal offset
        uint32_t dx_sq = dx * dx;
        if((x + dx) < 0) continue;
        if((x + dx) >= SCREEN_WIDTH) continue;
        for (int h = 0; h <= radius * 2; h++) {
            int dy = radius - h; // vertical offset
            if((y + dy) >= SCREEN_HEIGHT) continue;
            if((y + dy) < 0) continue;
            if ((dx_sq + dy*dy) <= r_sq) {
                guarded_put_pixel(x + dx, y + dy, p);
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

    while (x >= y) {
        //  Each of the following renders an octant of the circle
        guarded_put_pixel(centreX + x, centreY - y, color);
        guarded_put_pixel(centreX + x, centreY + y, color);
        guarded_put_pixel(centreX - x, centreY - y, color);
        guarded_put_pixel(centreX - x, centreY + y, color);
        guarded_put_pixel(centreX + y, centreY - x, color);
        guarded_put_pixel(centreX + y, centreY + x, color);
        guarded_put_pixel(centreX - y, centreY - x, color);
        guarded_put_pixel(centreX - y, centreY + x, color);

        if (error <= 0) {
            ++y;
            error += ty;
            ty += 2;
        }

        if (error > 0) {
            --x;
            tx += 2;
            error += (tx - diameter);
        }
    }
}


void gfx_cls(palidx_t c) {
    memset(frontbuffer, ((c & 0xf) << 4) | (c & 0xf), sizeof(frontbuffer));
}

void gfx_rect(int16_t x0, int16_t y0, int16_t x2, int16_t y2, const palidx_t color) {
    x0 = MAX(0, MIN(x0, SCREEN_WIDTH-1));
    x2 = MIN(x2, SCREEN_WIDTH-1);
    y0 = MAX(0, MIN(y0, SCREEN_HEIGHT-1));
    y2 = MIN(y2, SCREEN_HEIGHT-1);

    for(int16_t y=y0; y<=y2; y++)
        for(int16_t x=x0; x<=x2; x++)
            if ((y==y0) || (y==y2) || (x==x0) || (x==x2))
                guarded_put_pixel(x, y, color);
}

void gfx_rectfill(int16_t x0, int16_t y0, int16_t x2, int16_t y2, const palidx_t color) {
    // this is _inclusive_
    x0 = MAX(0, MIN(x0, SCREEN_WIDTH-1));
    x2 = MIN(x2, SCREEN_WIDTH-1);
    y0 = MAX(0, MIN(y0, SCREEN_HEIGHT-1));
    y2 = MIN(y2, SCREEN_HEIGHT-1);

    for(int16_t y=y0; y<=y2; y++) {
        for(int16_t x=x0; x<=x2; x++) {
            guarded_put_pixel(x, y, color);
        }
    }
}


palidx_t get_pixel(uint8_t x, uint8_t y) {
    if (x&0x1) {
        return (frontbuffer[(y*SCREEN_WIDTH/2+x/2)] & 0xf0) >> 4;
    } else {
        return (frontbuffer[(y*SCREEN_WIDTH/2+x/2)] & 0x0f);
    }
}


//uint8_t btn(lua_State* L, uint8_t* _buttons) {
TValue_t btn(TVSlice_t args) {
	/*
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
	*/
	assert(args.num==1);
	int16_t idx = __opt_int(args, 0, -1);
	if(idx==-1) return TNUM(0);
	return TBOOL(buttons[idx]);
}

TValue_t cls(TVSlice_t args) {
	int16_t idx = __opt_int(args, 0, 0);
    gfx_cls(idx);
	return T_NULL;
}

TValue_t spr(TVSlice_t args) {
	uint16_t n = 	__get_int(args, 0);
	fix32_t x = 	__get_num(args, 1);
	fix32_t y = 	__get_num(args, 2);
	fix32_t w = 	__opt_num(args, 3, fix32_from_int8(1));
	fix32_t h = 	__opt_num(args, 4, fix32_from_int8(1));
	bool flip_x = 	__opt_bool(args, 5, false);
	bool flip_y = 	__opt_bool(args, 6, false);
	//printf("sprite with spr=%d x=%d y=%d w=%d.%d h=%d.%d, flipx=%d, flipy=%d\n", n, x.i, y.i, w.i, w.f, h.i, h.f, flip_x, flip_y);
	render_many(&spritesheet, n, x.i, y.i, -1, flip_x, flip_y, w, h);
}

//void map(int16_t mapX, int16_t mapY, int16_t screenX, int16_t screenY, uint8_t cellW, uint8_t cellH, uint8_t layerFlags) {
TValue_t map(TVSlice_t args) {

	int16_t mapX 		= __get_int(args, 0);
	int16_t mapY 		= __get_int(args, 1);
	int16_t screenX 	= __get_int(args, 2);
	int16_t screenY 	= __get_int(args, 3);
	uint8_t cellW 		= __get_int(args, 4);
	uint8_t cellH 		= __get_int(args, 5);
	uint8_t layerFlags 	= __opt_int(args, 6, 0);

    //Map at 0 -16, S 0 0, C 16 16, F 4
    if(mapX<0) return T_NULL;
    if(mapY<0) return T_NULL;
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
	return T_NULL;
}

void render_text(Spritesheet* s, uint16_t sprite, uint8_t x0, uint8_t y0, uint8_t width_ratio, uint8_t height_ratio) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = sprite % sprite_count;
    const uint8_t yIndex = sprite / sprite_count;
    uint8_t val;

    if (drawstate.bg_color) {
        for (uint8_t y=0; y<7*height_ratio; y++) {
            if ((y+y0-1) >= SCREEN_HEIGHT) return;
            for (uint8_t x=0; x<9*width_ratio; x++) {
                if ((x+x0-1) >= SCREEN_WIDTH) break;
                put_pixel(x0+x-1, y0+y-1, drawstate.bg_color);
            }
        }
    }
    for (uint8_t y=0; y<6*height_ratio; y++) {
        if ((y+y0) >= SCREEN_HEIGHT) return;
        // TODO: memcpy if far from edges
        for (uint8_t x=0; x<8*width_ratio; x++) {
            if ((x+x0) >= SCREEN_WIDTH) break;
            val = s->sprite_data[y/height_ratio*128 + x/width_ratio + xIndex*8 + yIndex*8*128];
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

    int16_t print_x_offset = x;
    int16_t print_y_offset = y;
	uint8_t char_width = 4;
    int16_t print_width_ratio = 1;
    int16_t print_height_ratio = 1;
    int16_t old_pen;

	uint8_t i = 0;
	while (i<textLen) {
		bool printed_double_wide = false;
		uint8_t c = text[i];
        // FIXME: have to handle all control chars in a row
		switch(c) {
			case 6: // \^ change rendering modes
				if (i==textLen-1) return; // text ends in \^; probably illegal
				i++;
				if (i==textLen-1) return; // text ends in \^<MODE>; pointless
				c = text[i];
				switch(c) {
					case 'w':
						print_width_ratio = 2; // FIXME, maybe *= 2?
						break;
					case 't':
						print_height_ratio = 2;
						break;
					case 'i': // inverted
						old_pen = drawstate.pen_color;
						drawstate.pen_color = drawstate.bg_color;
						drawstate.bg_color = old_pen;
						break;
                    case 'g': // home
                        print_x_offset = x;
                        print_y_offset = y;
                        break;
                    case '-': // disable something
                        if (i==textLen-1) return; // text ends in \^-; probably illegal
                        i++;
                        if (i==textLen-1) return; // text ends in \^-<MODE>; pointless
                        c = text[i];
                        switch(c) {
                            case 'i': // inverted
                                // FIXME probably not how it should be done
                                old_pen = drawstate.pen_color;
                                drawstate.pen_color = drawstate.bg_color;
                                drawstate.bg_color = old_pen;
                                break;
                            default:
                                printf("supposed to disable %c now\n", c);
                        }
                        break;
				}
				i++;
				c = text[i];
				break;
			case '\n':
                print_x_offset = x;
                print_y_offset += 6;
				if (i==textLen-1) return; // text ends in \n; pointless
				i++;
				c = text[i];
				break;
			case '\f':
				// TODO: hex colors (a-f)
				if (i==textLen-1) return; // text ends in \f; probably illegal
				i++;
				drawstate.pen_color = text[i] - '0'; // ascii numbers are offset by '0'
				if (i==textLen-1) return; // text ends in \f<COLOR>; pointless
				i++;
				c = text[i];
				break;
			case 0x2: // \#
				// TODO: hex colors (a-f)
				if (i==textLen-1) return; // text ends in \#; probably illegal
				i++;
				drawstate.bg_color = text[i] - '0'; // ascii numbers are offset by '0'
				if (i==textLen-1) return; // text ends in \#<COLOR>; pointless
				i++;
				c = text[i];
				break;
			case 0xe2: 
				i++;
				c = text[i];
				switch(c) {
					case 0x9d:// ❎ = 0xe2 0x9d 0x8e
						printed_double_wide = true;
						c = 151; // X in font
						i += 1;
						break;
					case 0x99:// ❤️ = 0xe2 0x99 0xa5
						printed_double_wide = true;
						c = 135; // heart in font
						i += 1;
						break;
					case 0xac:// U/L/D
						i++;
						c = text[i];
						switch (c) {
							case 0x86: // U
								printed_double_wide = true;
								c = 9*16+4; // UP
								i += 3;
								break;
							case 0x85: // L
								printed_double_wide = true;
								c = 8*16+11; // L
								i += 3;
								break;
							case 0x87: // D
								printed_double_wide = true;
								c = 8*16+3; // D
								i += 3;
								break;
						}
						break;
					case 0x9e: // RIGHT = 0xe2 0x9e +4
						printed_double_wide = true;
						c = 9*16+1; // RIGHT
						i += 4;
						break;
				}
				break;
			case 0xf0: // 🅾  = 0xf0 0x9f 0x85 0xbe
				printed_double_wide = true;
				c = 142; // "circle" in font (square)
				i += 6;
				break;
		}
		if (c > 15) { // FIXME: this covers \^w\^t (many specials in a row)
			render_text(&fontsheet, c, print_x_offset, print_y_offset, print_width_ratio, print_height_ratio);
			print_x_offset += (char_width * print_width_ratio);
			i++;
		}
		if (printed_double_wide)
			print_x_offset += (char_width * print_width_ratio);
	}
	drawstate.bg_color = 0;

}

// Bresenham line algorithm
// https://gist.github.com/bert/1085538
void gfx_line(int16_t x0, int16_t y0, int16_t x1, int16_t y1, const palidx_t color) {
    int16_t dx =  abs (x1 - x0), sx = x0 < x1 ? 1 : -1;
    int16_t dy = -abs (y1 - y0), sy = y0 < y1 ? 1 : -1; 
    int16_t err = dx + dy, e2; /* error value e_xy */

    for (;;){  /* loop */
        guarded_put_pixel(x0,y0, color);
        if (x0 == x1 && y0 == y1) break;
        e2 = 2 * err;
        if (e2 >= dy) { err += dy; x0 += sx; } /* e_xy+e_x > 0 */
        if (e2 <= dx) { err += dx; y0 += sy; } /* e_xy+e_y < 0 */
    }
}
TValue_t print(TVSlice_t args) {
	Str_t* str;
	assert(args.num>0);
	if (args.elems[0].tag == STR) {
		str = __get_str(args, 0);
	} else {
		assert(args.elems[0].tag == NUM); // bool/etc implemented
		char buf[12] = {0};
		print_fix32(args.elems[0].num, buf);
		str = GETSTRP(TSTR((buf)));
	}
	int16_t x 			= __get_int(args, 1);
	int16_t y 			= __get_int(args, 2);
    int16_t paletteIdx 	= __opt_int(args, 3, drawstate.pen_color);

    _print(str->data, (uint8_t)str->len, x-drawstate.camera_x, y-drawstate.camera_y, paletteIdx);
	return T_NULL;
}
TValue_t pal(TVSlice_t args) {
    // TODO: significant functionality missing
    // https://pico-8.fandom.com/wiki/Pal
    if (args.num == 0) {
        memcpy(pal_map, orig_pal_map, sizeof(orig_pal_map));
        reset_transparency();
        return T_NULL;
    }
    if(args.elems[0].tag == TAB) {
        uint8_t palIdx = __opt_int(args, 1, 0);
		assert(false);
        //_replace_palette(palIdx);
        return T_NULL;
    }

    const uint8_t origIdx = __get_int(args, 0);
    const uint8_t newIdx = __get_int(args, 1);
    pal_map[origIdx] = newIdx;
    return T_NULL;
}
/*

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

inline void spr(uint16_t n, fix32_t x, fix32_t y, fix32_t w = fix32_t(1.0f), fix32_t h = fix32_t(1.0f), bool flip_x = false, bool flip_y = false) {
    render_many(&spritesheet, n, (int16_t)x, (int16_t)y, -1, flip_x, flip_y, w, h);
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
    fix32_t w = luaL_optinteger(L, 4, 1.0);
    fix32_t h = luaL_optinteger(L, 5, 1.0);

    bool flip_x = false;
    bool flip_y = false;

    if (argcount >= 6)
        flip_x = lua_toboolean(L, 6);
    if (argcount >= 7)
        flip_y = lua_toboolean(L, 7);

    spr(n, x, y, w, h, flip_x, flip_y);

    return 0;
}
*/

TValue_t line(TVSlice_t args) {
    //TODO: handle all cases https://pico-8.fandom.com/wiki/Line
    int16_t x0 = __opt_int(args, 0, drawstate.line_x);
    int16_t y0 = __opt_int(args, 1, drawstate.line_y);
    int16_t x1 = __opt_int(args, 2, 0);
    int16_t y1 = __opt_int(args, 3, 0);
    int16_t col =__opt_int(args, 4, drawstate.pen_color);
    drawstate.pen_color = col;
    drawstate.line_x = x1;
    drawstate.line_y = y1;
    gfx_line(x0-drawstate.camera_x, y0-drawstate.camera_y, x1-drawstate.camera_x, y1-drawstate.camera_y, col);
    return T_NULL;
}

TValue_t rect(TVSlice_t args) {
    int16_t x =  __get_int(args, 0);
    int16_t y =  __get_int(args, 1);
    int16_t x2 = __get_int(args, 2);
    int16_t y2 = __get_int(args, 3);
    int col = 	 __opt_int(args, 4, drawstate.pen_color);
    drawstate.pen_color = col;
	    
    gfx_rect(x-drawstate.camera_x, y-drawstate.camera_y, x2-drawstate.camera_x, y2-drawstate.camera_y, col);
    return T_NULL;
}

TValue_t rectfill(TVSlice_t args) {
    int16_t x =  __get_int(args, 0);
    int16_t y =  __get_int(args, 1);
    int16_t x2 = __get_int(args, 2);
    int16_t y2 = __get_int(args, 3);
    int col = 	 __opt_int(args, 4, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_rectfill(x-drawstate.camera_x, y-drawstate.camera_y, x2-drawstate.camera_x, y2-drawstate.camera_y, col);
    return T_NULL;
}

TValue_t circ(TVSlice_t args) {
    int x =   __get_int(args, 0);
    int y =   __get_int(args, 1);
    int r =   __opt_int(args, 2, 4);
    int col = __opt_int(args, 3, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_circle(x-drawstate.camera_x, y-drawstate.camera_y, r, col);
    return T_NULL;
}

TValue_t oval(TVSlice_t args) {
    int x0 =  __get_int(args, 0);
    int y0 =  __get_int(args, 1);
    int x1 =  __get_int(args, 2);
    int y1 =  __get_int(args, 3);
    int col = __opt_int(args, 4, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_oval(x0-drawstate.camera_x, y0-drawstate.camera_y, x1-drawstate.camera_x, y1-drawstate.camera_y, col);
    return T_NULL;
}
TValue_t ovalfill(TVSlice_t args) {
    int x0 =  __get_int(args, 0);
    int y0 =  __get_int(args, 1);
    int x1 =  __get_int(args, 2);
    int y1 =  __get_int(args, 3);
    int col = __opt_int(args, 4, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_ovalfill(x0-drawstate.camera_x, y0-drawstate.camera_y, x1-drawstate.camera_x, y1-drawstate.camera_y, col);
    return T_NULL;
}

TValue_t circfill(TVSlice_t args) {
    int x =   __get_int(args, 0);
    int y =   __get_int(args, 1);
    int r =   __opt_int(args, 2, 4);
    int col = __opt_int(args, 3, drawstate.pen_color);
    drawstate.pen_color = col;

    gfx_circlefill(x-drawstate.camera_x, y-drawstate.camera_y, r, col);
    return T_NULL;
}

/*
int _lua_map(lua_State* L) {
    uint8_t argcount = lua_gettop(L);
    if (argcount == 0) {
        return 0;
    }
    int mapX = luaL_checkinteger(L, 1);
    int mapY = luaL_checkinteger(L, 2);
    int screenX = luaL_checkinteger(L, 3);
    int screenY = luaL_checkinteger(L, 4);
    int cellW = luaL_checkinteger(L, 5);
    int cellH = luaL_checkinteger(L, 6);
    uint32_t layerFlags = luaL_optinteger(L, 7, 0x0);

    cellW = MIN(cellW, 63);
    cellH = MIN(cellH, 63);
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
    uint8_t argcount = lua_gettop(L);
    if (argcount == 0) {
        lua_pushinteger(L, btn(L, buttons_frame));
        return 1;
    }
    lua_pushboolean(L, btn(L, buttons_frame));
    return 1;
}
int _lua_btn(lua_State* L) {
    lua_pushboolean(L, btn(L, buttons));
    // printf("Button state for %d is %d\n", idx, buttons[idx]);
    return 1;
}

int _lua_srand(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    srand(x);
    return 0;
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
int _lua_sset(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);
    int16_t c = luaL_optinteger(L, 3, drawstate.pen_color);
	if(x>=0 && x<128 && y>=0 && y<128) {
		spritesheet.sprite_data[y*128+x] = c;
	}
    return 0;
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
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);
    uint8_t n = luaL_checkinteger(L, 3);
    map_data[x+y*128] = n;
    return 0;
}

int _lua_mget(lua_State* L) {
    int16_t x = luaL_checkinteger(L, 1);
    int16_t y = luaL_checkinteger(L, 2);
    if (x<0 || y<0 || x>63 || y> 63) {
    	lua_pushinteger(L, 0);
    	return 1;
    }
    uint16_t p = map_data[y*128+x];
    lua_pushinteger(L, p);
    return 1;
}

int _lua_pget(lua_State* L) {
    uint16_t x = luaL_checkinteger(L, 1);
    uint16_t y = luaL_checkinteger(L, 2);
    uint16_t p;
    if (x>127 || y>127) {
        p = 0;
    } else {
        p = get_pixel(x, y);
    }
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
    float delta = (float)(now() - bootup_time)/1000.0f;
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
int _lua_cursor(lua_State* L) {
    const int16_t old_cursor_x = drawstate.cursor_x;
    const int16_t old_cursor_y = drawstate.cursor_y;
    const int16_t old_cursor_c = drawstate.pen_color;

	const int16_t x = luaL_optinteger(L, 1, 0);
    const int16_t y = luaL_optinteger(L, 2, 0);
    const int16_t paletteIdx = luaL_optinteger(L, 3, drawstate.pen_color);

	drawstate.cursor_x = x;
	drawstate.cursor_y = y;
	drawstate.pen_color = paletteIdx;

    lua_pushnumber(L, old_cursor_x);
    lua_pushnumber(L, old_cursor_y);
    lua_pushnumber(L, old_cursor_c);

    return 3;
}
int _lua_reload(lua_State* L) {
    uint8_t argcount = lua_gettop(L);
    // TODO: implement reload
    if (argcount==0) {
        return 0;
    }
    return 0;
}

int _extcmd(lua_State* L) {
    const char* val = luaL_checkstring(L, 1);
    // TODO: implement
    printf("Got extcmd: %s, ignoring\n", val);
    return 0;
}

int _lua_poke4(lua_State* L) {
    uint8_t argcount = lua_gettop(L);
    if (argcount==0) {
        return 0;
    }
    uint16_t addr = luaL_checkinteger(L, 1);
    if (addr >= 0x6000 && addr <= 0x7fff) {
        printf("poke4 on %x\n", addr);
	addr = (addr - 0x6000) / 2;
        for(uint8_t arg=0; arg<argcount-1; arg++){
	        uint32_t value = luaL_checkinteger(L, 2+arg);
            // printf("fb[%lx] = %d, sizeof(fb) = %lx\n", addr+arg*sizeof(uint8_t), value, sizeof(frontbuffer));
            frontbuffer[addr+arg*sizeof(uint8_t)+0] = (value & 0x000f) >> 0;
            frontbuffer[addr+arg*sizeof(uint8_t)+1] = (value & 0x00f0) >> 8;
            frontbuffer[addr+arg*sizeof(uint8_t)+2] = (value & 0x0f00) >> 16;
            frontbuffer[addr+arg*sizeof(uint8_t)+3] = (value & 0xf000) >> 24;
	}
	return 0;
    }
    for(uint8_t arg=0; arg<argcount-1; arg++){
	uint32_t value = luaL_checkinteger(L, 2+arg);
	printf("-Writing %d to %x\n", value, addr+arg);
	fflush(stdout);
	ram[addr+arg*sizeof(uint32_t)+0] = (value & 0x000f) >>  0;
	ram[addr+arg*sizeof(uint32_t)+1] = (value & 0x00f0) >>  8;
	ram[addr+arg*sizeof(uint32_t)+2] = (value & 0x0f00) >> 16;
	ram[addr+arg*sizeof(uint32_t)+3] = (value & 0xf000) >> 24;
    }
    return 0;
}
*/
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

void _render(Spritesheet* s, uint16_t sx, uint16_t sy, int16_t x0, int16_t y0, int paletteIdx, bool flip_x, bool flip_y, fix32_t width, fix32_t height) {
    palidx_t p;
    uint16_t val;
	//printf("Called render with sx=%d sy=%d x0=%d y0=%d\n", sx, sy, x0, y0);

    int16_t ymin = MAX(0, -(y0-drawstate.camera_y));
    int16_t xmin = MAX(0, -(x0-drawstate.camera_x));

    int16_t ymax = fix32_ceil(fix32_mul(height, fix32_from_int8(8))).i;
    int16_t xmax = fix32_ceil(fix32_mul(width, fix32_from_int8(8))).i;

	//
//    ymax = MAX(0, MIN((SCREEN_HEIGHT-1)-(int16_t)(y0-drawstate.camera_y+ymax), ymax));
//    xmax = MAX(0, MIN((SCREEN_WIDTH -1)-(int16_t)(x0-drawstate.camera_x+xmax), xmax));

    xmin = MIN(xmin, xmax);
    ymin = MIN(ymin, ymax);

    if(xmin>=xmax) return;
	assert(width.f==0); // change screen_x == ...*1 to *width
	assert(width.i==1); // change screen_x == ...*1 to *width

	for (int16_t y=ymin; y<ymax; y++) {
		int16_t screen_y = y0+y-drawstate.camera_y;
		//if (screen_y < 0) continue;
		if (screen_y >= SCREEN_HEIGHT) return;
		if (sy >= 128) return; // TODO: these 128 are spritesheet height

		for (int16_t x=xmin; x<xmax; x++) {
			int16_t screen_x;
			if(flip_x) {
				screen_x = x0-drawstate.camera_x-x+8*1; // width; // FIXME 1=width
			} else {
				screen_x = x0+x-drawstate.camera_x;
			}

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

			put_pixel(screen_x, screen_y, p);

		}
	}
}

void render_many(Spritesheet* s, uint16_t n, int16_t x0, int16_t y0, int paletteIdx, bool flip_x, bool flip_y, fix32_t width, fix32_t height) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = n % sprite_count;
    const uint8_t yIndex = n / sprite_count;
    _render(s, xIndex*8, yIndex*8, x0, y0, paletteIdx, flip_x, flip_y, width, height);
}

inline void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y) {
    const uint8_t sprite_count = 16;
    const uint8_t xIndex = n % sprite_count;
    const uint8_t yIndex = n / sprite_count;
    _render(s, xIndex*8, yIndex*8, x0, y0, paletteIdx, flip_x, flip_y, fix32_from_int8(1), fix32_from_int8(1));
}

void render_stretched(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t sw, uint16_t sh, uint16_t dx, uint16_t dy,
		      uint16_t dw, uint16_t dh) {

    if(dw == sw && dh == sh) return _render(s, sx, sy, dx, dy, -1, false, false, fix32_from_uint16(dw/8), fix32_from_uint16(dh/8));
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
	    //if(dx+x-drawstate.camera_x < 0) continue;
	    //if(dx+x-drawstate.camera_x >= SCREEN_WIDTH) continue;
            uint8_t val = s->sprite_data[(yoff + ((x*ratio_x) >> 16)+sx)] % 15; // FIXME mod15 is alternate palette..
            if (drawstate.transparent[val] == 0){
                put_pixel(dx+x-drawstate.camera_x, screen_y, val);
            }
        }
    }
}

#include "pico8_placeholders.c"

pico8_t pico8 = {
	.cls=cls,
	.btn=btn,
	.map=map,
	.spr=spr,
	.print=print,
	.pal=pal,
	.rect=rect,
	.rectfill=rectfill,
	.circ=circ,
	.circfill=circfill,
	.oval=oval,
	.ovalfill=ovalfill,
	.line=line,
	.btnp=btnp,
	.palt=palt,
	.sgn=sgn,
	.sfx=_sfx,
	.music=music,
	.fget=fget,
	.camera=camera,
	.pset=pset,
	.poke=poke,
	.poke2=poke2,
	.poke4=poke4,
	.peek=peek,
	.peek2=peek2,
	.peek4=peek4,
	.color=color,
	.fillp=fillp,
	.sspr=sspr,
	._update=NULL, // these are set by `load_game_code`
	._draw=NULL,
	.flip=flip,
	._time=_time,
	.t=time_alias_t, // an alias of time
	.menuitem=menuitem,
	.reload=reload,
	 // 1 arg
	.extcmd=extcmd,
	.fast_peek=fast_peek,
	.fast_peek2=fast_peek2,
	.fast_peek4=fast_peek4,
	.dget=dget,
	.cartdata=_cartdata,
	// 2 arg
	.pget=pget,
	.sget=sget,
	.mget=mget,
	.dset=dset,
	// 3 arg
	.mset=mset,
};
