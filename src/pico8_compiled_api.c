#include "pico8api.h"
#include "engine.h"
#include "backend.h"
#include "fix32.h"
#include "lua.h"
#include "lua_math.h"
#include "lua_table.h"

TValue_t cls(TVSlice_t args) {
	int16_t idx = __opt_int(args, 0, 0);
    gfx_cls(idx);
	return T_NULL;
}

TValue_t spr(TVSlice_t args) {
	uint16_t n = 	__get_int(args, 0);
	int16_t x = 	__opt_int(args, 1, 0);
	int16_t y = 	__opt_int(args, 2, 0);
	fix32_t w = 	__opt_num(args, 3, fix32_from_int8(1));
	fix32_t h = 	__opt_num(args, 4, fix32_from_int8(1));
	bool flip_x = 	__opt_bool(args, 5, false);
	bool flip_y = 	__opt_bool(args, 6, false);
	// printf("sprite with spr=%d x=%d y=%d w=%d.%d h=%d.%d, flipx=%d, flipy=%d\n", n, x, y, w.i, w.f, h.i, h.f, flip_x, flip_y);
	render_many(&spritesheet, n, x, y, -1, flip_x, flip_y, w, h);
	return T_NULL;
}

TValue_t _map(TVSlice_t args) {

	int16_t mapX 		= __get_int(args, 0);
	int16_t mapY 		= __get_int(args, 1);
	int16_t screenX 	= __get_int(args, 2);
	int16_t screenY 	= __get_int(args, 3);
	uint8_t cellW 		= __get_int(args, 4);
	uint8_t cellH 		= __get_int(args, 5);
	uint8_t layerFlags 	= __opt_int(args, 6, 0);

	map(mapX, mapY, screenX, screenY, cellW, cellH, layerFlags);
	return T_NULL;
}
TValue_t btn(TVSlice_t args) {
	uint8_t argcount = args.num;
	if (argcount == 0) {
		uint8_t bitfield = 0;
		for(uint8_t i=0; i<6; i++) {
			bitfield |= ((buttons[i]) << i);
		}
		return TNUM(bitfield);
	} else if (argcount == 1) {
		int16_t idx = __opt_int(args, 0, -1);
		if(idx==-1) return TBOOL(0);
		return TBOOL(buttons[idx]);
	} else {
		printf("Unsupported btn/btnp with 2 args\n");
		return TNUM(0);
	}
}
TValue_t btnp(TVSlice_t args) {
	// FIXME: merge with btn
	uint8_t argcount = args.num;
	if (argcount == 0) {
		uint8_t bitfield = 0;
		for(uint8_t i=0; i<6; i++) {
			bitfield |= ((buttons_frame[i]) << i);
		}
		return TNUM(bitfield);
	} else if (argcount == 1) {
		int16_t idx = __opt_int(args, 0, -1);
		if(idx==-1) return TBOOL(0);
		return TBOOL(buttons_frame[idx]);
	} else {
		printf("Unsupported btn/btnp with 2 args\n");
		return TNUM(0);
	}
}
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
TValue_t print(TVSlice_t args) {
	// returns the X coordinate of the next character to be printed
	Str_t* str;
	assert(args.num>0);
	if (args.elems[0].tag == STR) {
		str = __get_str(args, 0);
	} else if (args.elems[0].tag == NUL){
		//str = GETSTRP(TSTR("nilstr"));
		//i think this shouldn't be happening ->
		//print_trace();
		assert(false);
	} else {
		assert(args.elems[0].tag == NUM); // bool/etc implemented
		char buf[12] = {0};
		print_fix32(args.elems[0].num, buf);
		str = GETSTRP(TSTR((buf)));
	}
	int16_t x 			= __get_int(args, 1);
	int16_t y 			= __get_int(args, 2);
    int16_t paletteIdx 	= __opt_int(args, 3, drawstate.pen_color);

    return TNUM(_print(str->data, (uint8_t)str->len, x-drawstate.camera_x, y-drawstate.camera_y, paletteIdx));
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
		assert(false); // TODO impl vvv
        //_replace_palette(palIdx);
        return T_NULL;
    }

    const uint8_t origIdx = __get_int(args, 0);
    const uint8_t newIdx = __get_int(args, 1);
    pal_map[origIdx] = newIdx;
    return T_NULL;
}

TValue_t dget(TValue_t idx) {
	assert(idx.tag == NUM);
	assert(idx.num.f == 0);
    return TNUM(cartdata[idx.num.i]);
}

TValue_t dset(TValue_t idx, TValue_t value) {
	assert(idx.tag == NUM);
	assert(idx.num.f == 0);
	assert(value.tag == NUM);
	assert(value.num.f == 0);

    cartdata[idx.num.i] = value.num.i;
    return T_NULL;
}

TValue_t pset(TVSlice_t args) {
    int16_t x = __get_int(args, 0);
    int16_t y = __get_int(args, 1);
    int16_t idx = __opt_int(args, 2, drawstate.pen_color);
    _pset(x, y, idx);
    return T_NULL;
}

TValue_t _time() {
	uint32_t _now_with_ms = now();
	uint32_t _delta_sec = (_now_with_ms - bootup_time) / 1000;
	uint32_t _delta_ms  = (_now_with_ms - bootup_time) % 1000;
	// fix32 integer part is signed, we get to keep 15 bits, will wrap around at
	// 9.1 hours
	fix32_t _now = fix32_from_parts(_delta_sec & 0x8fff, (uint16_t)_delta_ms);
    return TNUM(_now);
}

TValue_t camera(TVSlice_t args) {
    int16_t x = __opt_int(args, 0, 0);
    int16_t y = __opt_int(args, 1, 0);
    //int16_t old_x = drawstate.camera_x;
    //int16_t old_y = drawstate.camera_y;

    drawstate.camera_x = x;
    drawstate.camera_y = y;

	// it's going to suck when i need to figure out how to implement tuples
    return T_NULL;
}

TValue_t palt(TVSlice_t arg) {
    uint8_t argcount = arg.num;
    if (argcount == 0) {
        // reset for all colors
        reset_transparency();
        return T_NULL;
    }
    if (argcount == 1) {
        // TODO: should this use fix32?? not sure if rotr is what i want
        uint16_t bitfield = __get_int(arg, 0);
        for(uint8_t idx = 0; idx < 16; idx++) {
            drawstate.transparent[idx] = (bitfield & 1);
            bitfield >>= 1;
        }
        return T_NULL;
    }
    uint8_t idx = __get_int(arg, 0);
    bool transparent = __get_bool(arg, 1);
    drawstate.transparent[idx] = transparent;

    return T_NULL;
}

#include "pico8_placeholders.c"

pico8_t pico8 = {
	.cls=cls,
	.btn=btn,
	.map=_map,
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
	.t=_time, // an alias of time
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
}
