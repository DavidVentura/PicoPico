#ifndef PICO8_API
#define PICO8_API
#include "lua.h"
typedef struct pico8_s {
	// anything with variable # of arguments is Func_t
	Func_t btn;
	Func_t cls;
	Func_t map;
	Func_t pal;
	Func_t palt;
	Func_t print;
	Func_t spr;
	Func_t oval;
	Func_t ovalfill;
	Func_t circ;
	Func_t circfill;
	Func_t rect;
	Func_t rectfill;
	Func_t line;
	Func_t sfx;
	Func_t min;
	Func_t max;
	Func_t music;
	Func_t fget;
	Func_t camera;
	Func_t btnp;
	Func_t rnd;
	Func_t sub;
	Func_t pset;
	Func_t poke;
	// anything with mandatory, fixed # of arguments
	TValue_t (*time)();
	TValue_t (*abs)(TValue_t);
	TValue_t (*cos)(TValue_t);
	TValue_t (*sin)(TValue_t);
	TValue_t (*dget)(TValue_t);
	TValue_t (*cartdata)(TValue_t);
	TValue_t (*atan2)(TValue_t, TValue_t);
	TValue_t (*shr)(TValue_t, TValue_t);
	TValue_t (*shl)(TValue_t, TValue_t);
	TValue_t (*sget)(TValue_t, TValue_t);
	TValue_t (*mget)(TValue_t, TValue_t);
	TValue_t (*dset)(TValue_t, TValue_t);
} pico8_t;

extern pico8_t pico8;
TValue_t _printh(uint8_t argc, TValue_t* argv);
TValue_t add(TValue_t tab, TValue_t v);
TValue_t del(TValue_t tab, TValue_t v);
TValue_t* all(TValue_t tab);
void _foreach(TValue_t t, Func_t f);
Func_t _foreach_tvalue(TValue_t f);

#define printh print_tvalue
#endif
