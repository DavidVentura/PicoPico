#ifndef DATA
#define DATA
#include <stdint.h>
#include "static_game_data.h"
#define SAMPLE_RATE 22050
int buttons[6] = {0};

const uint8_t SAMPLES_PER_DURATION = 183;
const uint8_t NOTES_PER_SFX = 32;

struct Spritesheet {
	uint8_t sprite_data[128 * 128]; // 16KB, could be 8 with nibble packing
	uint8_t flags[256];
};
typedef struct Spritesheet Spritesheet;


struct DrawState {
	uint8_t     pen_color   = 7;
	uint8_t     clip_x      = 0;
	uint8_t     clip_y      = 0;
	uint8_t     clip_w      = SCREEN_WIDTH;
	uint8_t     clip_h      = SCREEN_HEIGHT;
	int16_t     camera_x    = 0;
	int16_t     camera_y    = 0;
	uint16_t    line_x      = 0;
	uint16_t    line_y      = 0;
	uint8_t     transparent[15];
};

typedef struct DrawState DrawState;

struct Cart {
    char* code;
};

typedef struct Cart Cart;
static Cart cart;

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
    uint8_t duration;
    uint8_t loop_start;
    uint8_t loop_end;
    Note notes[32];
};
typedef struct SFX SFX;

struct Channel {
    SFX* sfx;
    uint8_t sfx_id = 0;
    uint16_t offset = 0; // in samples
    z8::fix32 phi = 0;
};

typedef struct Channel Channel;

static DrawState drawstate;

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

