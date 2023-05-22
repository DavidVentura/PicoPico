//Make it so we don't need to include any other C files in our build.
#define CNFG_IMPLEMENTATION

//Optional: Use OpenGL to do rendering on appropriate systems.
//#define CNFGOGL

#include "os_generic.h"
#include "CNFG.h"

#include <time.h>
#include <sys/time.h>
#include "backend.h"
#ifndef ENGINE
#include "engine.c"
#endif
#include "data.h"

const uint8_t UPSCALE_FACTOR = 4;
uint32_t* _rgb32_buf;
bool init_platform() {
    return true;
}

bool init_audio() {
	return true;
}
bool init_video()
{
    memset(frontbuffer, 0, sizeof(frontbuffer));
	CNFGSetup("PicoPico", W_SCREEN_WIDTH, W_SCREEN_HEIGHT);
	_rgb32_buf = (uint32_t*)malloc(SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(uint32_t) * UPSCALE_FACTOR*UPSCALE_FACTOR);
	return true;
}

void video_close()
{
	free(_rgb32_buf);
}

void gfx_flip() {
	uint8_t r,g,b,a;
	a = 0xff ;
    for(uint16_t y=0; y<SCREEN_HEIGHT*UPSCALE_FACTOR; y++)
        for(uint16_t x=0; x<SCREEN_WIDTH*UPSCALE_FACTOR; x++){
			uint8_t sx = x/UPSCALE_FACTOR;
			uint8_t sy = y/UPSCALE_FACTOR;

            palidx_t idx = get_pixel(sx, sy);
			color_t color = palette[idx];

			r = (color >> 11) << 3;
			g = ((color >> 5) & 0x3f) << 2;
			b = (color & 0x1f) << 3;

			// ARGB
			_rgb32_buf[y*SCREEN_WIDTH*UPSCALE_FACTOR+x] = (a << 24) | (r << 16) | (g << 8) | b;

        }
 		CNFGBlitImage(_rgb32_buf, 0, 0, SCREEN_WIDTH * UPSCALE_FACTOR, SCREEN_HEIGHT*UPSCALE_FACTOR);
		CNFGSwapBuffers();
    //draw_hud();
}

void draw_hud() {
}
void delay(uint16_t ms) {
	// TODO
	OGUSleep(ms*1000);
}
bool handle_input() {
	// not polling, idk
	return !CNFGHandleInput();
}
uint32_t now() {
	return 0;
}
uint8_t current_hour() {
	return 0;
}
uint8_t current_minute() {
	return 0;
}
uint8_t wifi_strength() {
	return 0;
}
uint8_t battery_left() {
	return 0;
}


// dumbo
void HandleKey( int keycode, int bDown ) {
	if( keycode == 27 ) exit( 0 );
	switch(keycode) {
		case 65361: // left
			buttons_frame[0] = bDown == 2;
		    buttons[0] = bDown;
			break;
		case 65362: // up
			buttons_frame[2] = bDown == 2;
		    buttons[2] = bDown;
			break;
		case 65363: // right
			buttons_frame[1] = bDown == 2;
		    buttons[1] = bDown;
			break;
		case 65364: // down
			printf("b3 %d bf3 %d\n", buttons[3], buttons_frame[3]);
			buttons_frame[3] = buttons[3] == 0 && (buttons_frame[3] == 0);
		    buttons[3] = bDown;
			printf("b3 %d bf3 %d\n", buttons[3], buttons_frame[3]);
			break;
		case 122: // z
		    buttons_frame[4] = bDown == 2;
		    buttons[4] = bDown;
		    break;
		case 120: // x
		    buttons_frame[5] = bDown == 2;
		    buttons[5] = bDown;
		    break;
	}
	printf( "Key: %d -> %d\n", keycode, bDown );
	fflush(stdout);
}
void HandleButton( int x, int y, int button, int bDown ) { }
void HandleMotion( int x, int y, int mask ) { }
void HandleDestroy() {
	exit(0);
}
