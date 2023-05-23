//Make it so we don't need to include any other C files in our build.
#include "os_generic.h"
#ifdef ANDROID_BACKEND
#include <GLES3/gl3.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android_native_app_glue.h>
#include <android/sensor.h>
#include "CNFGAndroid.h"
#endif

#define CNFG_IMPLEMENTATION
#define CNFG3D

#include "CNFG.h"

//Optional: Use OpenGL to do rendering on appropriate systems.
//#define CNFGOGL

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

typedef struct {
	uint16_t x;
	uint16_t y;
} coords;

const coords button_coords[] = {
	[BTN_IDX_UP] =   	{250, 800}, 
	[BTN_IDX_LEFT] = 	{100, 950}, 
	[BTN_IDX_RIGHT] = 	{400, 950}, 
	[BTN_IDX_DOWN] = 	{250, 1100}, 

	[BTN_IDX_A] = 		{700, 1000}, 
	[BTN_IDX_B] = 		{850, 850}, 
};

const uint16_t BTN_WIDTH = 160;
const uint16_t BTN_HEIGHT = 160;

bool init_platform() {
    return true;
}

bool init_audio() {
	return true;
}
bool init_video()
{
    memset(frontbuffer, 0, sizeof(frontbuffer));
	//CNFGSetup("PicoPico", W_SCREEN_WIDTH, W_SCREEN_HEIGHT);
	CNFGSetupFullscreen( "PicoPico", 0 );
	_rgb32_buf = (uint32_t*)malloc(SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(uint32_t) * UPSCALE_FACTOR*UPSCALE_FACTOR);
	return true;
}

void video_close()
{
	free(_rgb32_buf);
}

void gfx_flip() {
	CNFGClearFrame();
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

			// android R....
			_rgb32_buf[y*SCREEN_WIDTH*UPSCALE_FACTOR+x] = (r << 24) | (g << 16) | (b << 8) | a;
			// ARGB
			//_rgb32_buf[y*SCREEN_WIDTH*UPSCALE_FACTOR+x] = (a << 24) | (r << 16) | (g << 8) | b;
			//_rgb32_buf[y*SCREEN_WIDTH*UPSCALE_FACTOR+x] = (a << 24) | (r << 16) | (g << 8) | b;

        }
	CNFGBlitImage(_rgb32_buf, 0, 0, SCREEN_WIDTH * UPSCALE_FACTOR, SCREEN_HEIGHT*UPSCALE_FACTOR);
    draw_hud();
	CNFGSwapBuffers();
}

void draw_hud() {
	for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(coords); i++) {
		buttons[i] ? CNFGColor( 0xFFFFFF88 ) : CNFGColor( 0xFFFFFF44 );
		CNFGTackRectangle(button_coords[i].x,
						  button_coords[i].y,
						  button_coords[i].x + BTN_WIDTH,
						  button_coords[i].y + BTN_HEIGHT);
	}
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

#ifdef ANDROID
	if( keycode == 4 ) { AndroidSendToBack( 1 ); } //Handle Physical Back Button.
#endif
	printf( "Key: %d -> %d\n", keycode, bDown );
	fflush(stdout);
}
void HandleButton( int x, int y, int button, int bDown ) {
	if(!bDown) {
		memset(buttons, sizeof(buttons), 0);
	}
	for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(coords); i++) {
		if (x>=button_coords[i].x && x<=button_coords[i].x+BTN_WIDTH && y>=button_coords[i].y && y<=button_coords[i].y+BTN_HEIGHT) {
			buttons_frame[i] = bDown && !buttons[i];
			buttons[i] = bDown;
		}
	}
}

void HandleMotion( int x, int y, int mask ) { }
void HandleDestroy() {
	exit(0);
}
