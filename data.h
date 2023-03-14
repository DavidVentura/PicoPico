#ifndef DATA
#define DATA
#include <cassert>
#include <stdint.h>
// The memory used by Lua is entirely separate from the PICO-8 memory and is limited to 2 MiB. 
// this does not include the "General use / extended map" 32KB chunk
static uint8_t ram[0x5DFF - 0x4300]; // 7KB
typedef uint8_t  palidx_t;
typedef uint16_t color_t;
struct GameCart {
    const uint8_t  name_len;
    const char*    name;

    const uint16_t code_len;
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
};

typedef struct GameCart GameCart;
#include "static_game_data.h"
#define SAMPLE_RATE 22050
uint8_t buttons[6] = 	{0, 0, 0, 0, 0, 0};
uint8_t buttons_frame[6] =  {0, 0, 0, 0, 0, 0};

const uint8_t SAMPLES_PER_DURATION = 183;
const uint8_t NOTES_PER_SFX = 32;

struct Spritesheet {
	uint8_t sprite_data[128 * 128]; // 16KB, could be 8 with nibble packing
	uint8_t flags[256];
};
typedef struct Spritesheet Spritesheet;


struct DrawState {
	uint8_t     pen_color   = 7;
	uint8_t     bg_color    = 0;
	uint8_t     clip_x      = 0;
	uint8_t     clip_y      = 0;
	uint8_t     clip_w      = SCREEN_WIDTH;
	uint8_t     clip_h      = SCREEN_HEIGHT;
	int16_t     camera_x    = 0;
	int16_t     camera_y    = 0;
	uint16_t    line_x      = 0;
	uint16_t    line_y      = 0;
	uint8_t     cursor_x    = 0;
	uint8_t     cursor_y    = 0;
	uint8_t     transparent[16];
};

typedef struct DrawState DrawState;

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
    uint8_t id = 0;
    SFX* sfx;
    uint8_t sfx_id = 0;
    // TODO: review if <offset> can go back to uint16_t, 
    // currently it overflows (eg: celeste sfx 38), but the formula
    // samples_per_duration * notes_per_sfx * duration
    // may not need the <notes_per_sfx> ??
    uint32_t offset = 0; // in samples
    z8::fix32 phi = 0;
};

typedef struct Channel Channel;

static DrawState drawstate;

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

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

void hexDump (
    const char * desc,
    const void * addr,
    const int len,
    int perLine
) {
    // Silently ignore silly per-line values.

    if (perLine < 4 || perLine > 129) perLine = 128;

    int i;
    unsigned char buff[perLine+1];
    const unsigned char * pc = (const unsigned char *)addr;

    // Output description if given.

    if (desc != NULL) printf ("%s:\n", desc);

    // Length checks.

    if (len == 0) {
        printf("  ZERO LENGTH\n");
        return;
    }
    if (len < 0) {
        printf("  NEGATIVE LENGTH: %d\n", len);
        return;
    }

    // Process every byte in the data.

    for (i = 0; i < len; i++) {
        // Multiple of perLine means new or first line (with line offset).

        if ((i % perLine) == 0) {
            // Only print previous-line ASCII buffer for lines beyond first.

            if (i != 0) printf ("  %s\n", buff);

            // Output the offset of current line.

            printf ("  %04x ", i);
        }

        // Now the hex code for the specific character.

        printf (" %02x", pc[i]);

        // And buffer a printable ASCII character for later.

        if ((pc[i] < 0x20) || (pc[i] > 0x7e)) // isprint() may be better.
            buff[i % perLine] = '.';
        else
            buff[i % perLine] = pc[i];
        buff[(i % perLine) + 1] = '\0';
    }

    // Pad out last line if not exactly perLine characters.

    while ((i % perLine) != 0) {
        printf ("   ");
        i++;
    }

    // And print the final ASCII buffer.

    printf ("  %s\n", buff);
}
void smallHexDump (const void * addr, const int len) {
    int i;
    unsigned char buff[len+1];
    const unsigned char * pc = (const unsigned char *)addr;
    assert(len > 0);

    for (i = 0; i < len; i++) {
        if ((i % len) == 0) {
            if (i != 0) printf ("  %s\n", buff);
        }
        printf (" %02x", pc[i]);
        buff[(i % len) + 1] = '\0';
    }
    printf ("  %s\n", buff);
}
#endif

