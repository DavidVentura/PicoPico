#ifndef ENGINE_H
#define ENGINE_H

#define BTN_IDX_LEFT 	0
#define BTN_IDX_RIGHT 	1
#define BTN_IDX_UP 		2
#define BTN_IDX_DOWN 	3
#define BTN_IDX_A 		4
#define BTN_IDX_B 		5
#define BTN_IDX_SEL 	255
#define BTN_IDX_START 	255

void render(Spritesheet* s, uint16_t n, uint16_t x0, uint16_t y0, int paletteIdx, bool flip_x, bool flip_y);
void render_stretched(Spritesheet* s, uint16_t sx, uint16_t sy, uint16_t sw, uint16_t sh, uint16_t dx, uint16_t dy, uint16_t dw, uint16_t dh);
void render_many(Spritesheet* s, uint16_t n, int16_t x0, int16_t y0, int paletteIdx, bool flip_x, bool flip_y, z8::fix32 width, z8::fix32 height);
inline void _fast_render(Spritesheet* s, uint16_t sx, uint16_t sy, int16_t x0, int16_t y0);
void reset_transparency();
void flip();
//static inline void put_pixel(uint8_t x, uint8_t y, const color_t p);
//uint16_t get_pixel(uint8_t x, uint8_t y);
// backend.h ?
volatile static bool suspended;
#endif
