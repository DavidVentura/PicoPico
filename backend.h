// these must be implemented by each specific backend
#ifndef BACKEND_H
#define BACKEND_H
bool init_video();
void video_close();
void draw_hud();
void gfx_flip();
void delay(uint16_t ms);
bool handle_input();
uint32_t now();
bool init_audio();
bool init_platform();

uint8_t current_hour();
uint8_t current_minute();
uint8_t wifi_strength();
uint8_t battery_left();

#endif
