#include "data.h"
#include "backend.h"
#include "pico8api.h"
#include <string.h> //memset

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

void drawHud() {
    memset(hud_buffer, 0x00, sizeof(hud_buffer));
    _draw_hud_sprite(&hud_sprites, 3 - battery_left(), 0, 18*13, 0); // bat
    _draw_hud_sprite(&hud_sprites, 3 - wifi_strength(), 1, 18*12, 0); // wifi

    uint8_t hour_fdigit, hour_ldigit, min_fdigit, min_ldigit;
    hour_fdigit = current_hour() / 10;
    hour_ldigit = current_hour() % 10;
    min_fdigit = current_minute() / 10;
    min_ldigit = current_minute() % 10;
    _draw_hud_sprite(&fontsheet, hour_fdigit, 3, 110, 3);
    _draw_hud_sprite(&fontsheet, hour_ldigit, 3, 118, 3);
    _draw_hud_sprite(&fontsheet, 10, 3, 126, 3); // :, 6 wide, centered at 128 (which is 2x, so 64)
    _draw_hud_sprite(&fontsheet, min_fdigit, 3, 134, 3);
    _draw_hud_sprite(&fontsheet, min_ldigit, 3, 142, 3);
    draw_hud();
}
