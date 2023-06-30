#ifndef PICO8_API
#define PICO8_API
#include "lua.h"
typedef struct pico8_s {
	Func_t btn;
	Func_t cls;
	Func_t map;
	Func_t pal;
	Func_t print;
	Func_t spr;
	Func_t oval;
	Func_t ovalfill;
	Func_t circ;
	Func_t circfill;
	Func_t rect;
	Func_t rectfill;
	Func_t line;
	TValue_t (*cos)(TValue_t);
} pico8_t;

extern pico8_t pico8;
TValue_t _printh(uint8_t argc, TValue_t* argv);
TValue_t rnd(TValue_t v);
TValue_t add(TValue_t tab, TValue_t v);
TValue_t del(TValue_t tab, TValue_t v);
void foreach(TValue_t t, Func_t f);

#define printh(x)	   		_Generic(x, TValue_t: print_tvalue)(x)
#endif
