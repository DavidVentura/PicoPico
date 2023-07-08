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
	Func_t sgn;
	Func_t oval;
	Func_t ovalfill;
	Func_t circ;
	Func_t circfill;
	Func_t rect;
	Func_t rectfill;
	Func_t line;
	Func_t _sfx;
	Func_t min;
	Func_t max;
	Func_t music;
	Func_t fget;
	Func_t camera;
	Func_t btnp;
	Func_t rnd;
	Func_t sub;
	Func_t pset;
	Func_t count;
	Func_t poke;
	Func_t poke2;
	Func_t poke4;
	Func_t peek;
	Func_t peek2;
	Func_t peek4;
	Func_t color;
	Func_t fillp;
	Func_t sspr;
	Func_t deli;
	// anything with mandatory, fixed # of arguments
	// 0 arg
	void (*_update)();
	void (*_draw)();
	void (*flip)();
	TValue_t (*_time)();
	TValue_t (*t)(); // an alias of time
	 // 1 arg
	TValue_t (*extcmd)(TValue_t);
	TValue_t (*abs)(TValue_t);
	TValue_t (*cos)(TValue_t);
	TValue_t (*sin)(TValue_t);
	TValue_t (*fast_peek)(TValue_t);
	TValue_t (*fast_peek2)(TValue_t);
	TValue_t (*fast_peek4)(TValue_t);
	TValue_t (*dget)(TValue_t);
	TValue_t (*_cartdata)(TValue_t);
	// 2 arg
	TValue_t (*atan2)(TValue_t, TValue_t);
	TValue_t (*shr)(TValue_t, TValue_t);
	TValue_t (*shl)(TValue_t, TValue_t);
	TValue_t (*pget)(TValue_t, TValue_t);
	TValue_t (*sget)(TValue_t, TValue_t);
	TValue_t (*mget)(TValue_t, TValue_t);
	TValue_t (*dset)(TValue_t, TValue_t);
	// 3 arg
	TValue_t (*mset)(TValue_t, TValue_t, TValue_t);
} pico8_t;

#define PLACEHOLDER(name, ...)     TValue_t name(__VA_ARGS__) {\
										printf("Called unimplemented " "\"" #name "\"" "\n");\
										return T_NULL;\
									}
#define void_PLACEHOLDER(name, ...)     void name(__VA_ARGS__) {\
											printf("Called unimplemented " "\"" #name "\"" "\n");\
										}
#define VAR_ARG_PLACEHOLDER(x) 		PLACEHOLDER(x, TVSlice_t a)
#define NO_ARG_PLACEHOLDER(x) 		PLACEHOLDER(x, void)
#define ONE_ARG_PLACEHOLDER(x) 		PLACEHOLDER(x, TValue_t a)
#define TWO_ARG_PLACEHOLDER(x) 		PLACEHOLDER(x, TValue_t a, TValue_t b)
#define THREE_ARG_PLACEHOLDER(x) 	PLACEHOLDER(x, TValue_t a, TValue_t b, TValue_t c)

extern pico8_t pico8;
TValue_t _printh(uint8_t argc, TValue_t* argv);

#endif
