#include "data.h"

static Spritesheet hud_sprites;
static Spritesheet label;

// is 128*16*2 = 4KB
// Could be 64*8*2 = 1KB
static uint8_t hud_buffer[SCREEN_WIDTH*HUD_HEIGHT*2];


// position is an index, from the right
inline void _draw_hud_sprite(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t xOffset, uint16_t yOffset) {
    for (uint16_t y=(sy*8); y<((sy+1)*8); y++) {
        for (uint16_t x=(sx*8); x<((sx+1)*8); x++) {
            uint8_t val = s->sprite_data[y*SCREEN_WIDTH + x];
            if (val > 0) {
                const color_t p = original_palette[val];
                uint16_t first_byte = (((y+yOffset)-(sy*8))*SCREEN_WIDTH*2+(x-(sx*8))*2 + xOffset);
                hud_buffer[first_byte  ] = (p >> 8);
                hud_buffer[first_byte+1] = p & 0xFF;
            }
        }
    }
}
