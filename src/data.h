#ifndef DATA
#define DATA
#include <assert.h>
#include <stdint.h>
#include "fix32.h"
// The memory used by Lua is entirely separate from the PICO-8 memory and is limited to 2 MiB. 
// this does not include the "General use / extended map" 32KB chunk
uint8_t ram[0x5DFF - 0x4300]; // 7KB
typedef uint8_t  palidx_t;
typedef uint16_t color_t;
typedef void (*game_entrypoint_t)();

struct GameCart {
    const uint8_t  name_len;
    const char*    name;

    const uint32_t code_len;
    const uint8_t* code;

    const uint16_t gff_len;
    const uint8_t* gff;

    const uint16_t gfx_len;
    const uint8_t* gfx;

    const uint16_t sfx_len;
    const uint8_t* sfx;

    const uint16_t map_len;
    const uint8_t* map;

    const uint16_t label_len;
    const uint8_t* label;

	game_entrypoint_t _preinit_fn;
	game_entrypoint_t _init_fn;
	game_entrypoint_t _update_fn;
	game_entrypoint_t _draw_fn;
};


typedef struct GameCart GameCart;
#include "generated/static_game_data.h"
#define SAMPLE_RATE 22050
uint8_t buttons[6] = 	{0, 0, 0, 0, 0, 0};
uint8_t buttons_frame[6] =  {0, 0, 0, 0, 0, 0};

#define SAMPLES_PER_DURATION 183
const uint8_t NOTES_PER_SFX = 32;

struct Spritesheet {
	uint8_t sprite_data[128 * 128]; // 16KB, could be 8 with nibble packing
	uint8_t flags[256];
};
typedef struct Spritesheet Spritesheet;


typedef struct DrawState_s {
	uint8_t     pen_color   ;
	uint8_t     bg_color    ;
	uint8_t     clip_x      ;
	uint8_t     clip_y      ;
	uint8_t     clip_w      ;
	uint8_t     clip_h      ;
	int16_t     camera_x    ;
	int16_t     camera_y    ;
	uint16_t    line_x      ;
	uint16_t    line_y      ;
	uint8_t     cursor_x    ;
	uint8_t     cursor_y    ;
	uint8_t     transparent[16];
} DrawState_t;

DrawState_t DrawState;

struct Note {
    uint8_t key;        //  pitch / C# / etc ; 0-0x40
    uint8_t waveform;   // triangle / ..; 0-0xF
    uint8_t volume;     // 0-7
    uint8_t effect;     // 0-7
};
typedef struct Note Note;
// this takes 32 bits but actually need 10 (4->2bytes)
// 6 for key (pitch), 1 for each of waveform, volume, effect
// times 32 notes per SFX = 64 bytes wasted
// times 64 SFX per game = 4KB wasted
// need to check performance first to see if it's not a problem

struct SFX {
    uint8_t id;
    uint8_t duration;
    uint8_t loop_start;
    uint8_t loop_end;
    Note notes[32];
};
typedef struct SFX SFX;

struct Channel {
    uint8_t id;
    SFX* sfx;
    uint8_t sfx_id;
    // TODO: review if <offset> can go back to uint16_t, 
    // currently it overflows (eg: celeste sfx 38), but the formula
    // samples_per_duration * notes_per_sfx * duration
    // may not need the <notes_per_sfx> ??
    uint32_t offset; // in samples
    fix32_t phi;
};

typedef struct Channel Channel;

DrawState_t drawstate = {
	.pen_color   = 7,
	.bg_color    = 0,
	.clip_x      = 0,
	.clip_y      = 0,
	.clip_w      = SCREEN_WIDTH,
	.clip_h      = SCREEN_HEIGHT,
	.camera_x    = 0,
	.camera_y    = 0,
	.line_x      = 0,
	.line_y      = 0,
	.cursor_x    = 0,
	.cursor_y    = 0,
	.transparent = {0},
};

#define to_rgb565(r, g, b) (((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3))

const color_t original_palette[] = {
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

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))
#endif

