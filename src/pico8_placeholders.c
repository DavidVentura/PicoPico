#include "pico8.h"
VAR_ARG_PLACEHOLDER(palt);
VAR_ARG_PLACEHOLDER(_sfx);
VAR_ARG_PLACEHOLDER(music);
VAR_ARG_PLACEHOLDER(fget);
VAR_ARG_PLACEHOLDER(camera);
VAR_ARG_PLACEHOLDER(btnp);
VAR_ARG_PLACEHOLDER(pset);
VAR_ARG_PLACEHOLDER(poke);
VAR_ARG_PLACEHOLDER(poke2);
VAR_ARG_PLACEHOLDER(poke4);
VAR_ARG_PLACEHOLDER(peek);
VAR_ARG_PLACEHOLDER(peek2);
VAR_ARG_PLACEHOLDER(peek4);
VAR_ARG_PLACEHOLDER(color);
VAR_ARG_PLACEHOLDER(fillp);
VAR_ARG_PLACEHOLDER(sspr);
VAR_ARG_PLACEHOLDER(menuitem);
VAR_ARG_PLACEHOLDER(reload);
// anything with mandatory, fixed # of arguments
// 0 arg
NO_ARG_PLACEHOLDER(_time);
NO_ARG_PLACEHOLDER(time_alias_t);
// 1 arg
ONE_ARG_PLACEHOLDER(extcmd);
ONE_ARG_PLACEHOLDER(fast_peek);
ONE_ARG_PLACEHOLDER(fast_peek2);
ONE_ARG_PLACEHOLDER(fast_peek4);
ONE_ARG_PLACEHOLDER(dget);
ONE_ARG_PLACEHOLDER(_cartdata);
// 2 arg
TWO_ARG_PLACEHOLDER(pget);
TWO_ARG_PLACEHOLDER(sget);
TWO_ARG_PLACEHOLDER(mget);
TWO_ARG_PLACEHOLDER(dset);
// 3 arg
THREE_ARG_PLACEHOLDER(mset);