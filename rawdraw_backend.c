//Make it so we don't need to include any other C files in our build.
#include "rawdraw/os_generic.h"
#ifdef ANDROID_BACKEND
#include <GLES3/gl3.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android_native_app_glue.h>
#include <android/sensor.h>
#include "CNFGAndroid.h"
#endif

#define CNFG_IMPLEMENTATION
#define CNFGOGL

#include "rawdraw/CNFG.h"


#include <time.h>
#include <sys/time.h>
#include "backend.h"
#ifndef ENGINE
#include "engine.c"
#endif
#include "data.h"

const uint8_t UPSCALE_FACTOR = 8;
uint32_t* _rgb32_buf;
unsigned int tex;

typedef struct {
    uint16_t x;
    uint16_t y;
} coords_t;

typedef struct {
    uint8_t buttonMask;
    coords_t coords;
    coords_t size;
    uint32_t color;
} button_coords_t;

const button_coords_t button_coords[] = {
    { 1 << BTN_IDX_UP,    {200, 1200}, {195, 195}, 0x00000000},
    { 1 << BTN_IDX_LEFT,  {  0, 1400}, {195, 195}, 0x00000000},
    { 1 << BTN_IDX_RIGHT, {400, 1400}, {195, 195}, 0x00000000},
    { 1 << BTN_IDX_DOWN,  {200, 1600}, {195, 195}, 0x00000000},

    // diagonals
    { (1 << BTN_IDX_UP)   | (1 << BTN_IDX_LEFT),    {  0, 1200}, {195, 195}, 0x00000000},
    { (1 << BTN_IDX_DOWN) | (1 << BTN_IDX_LEFT),    {  0, 1600}, {195, 195}, 0x00000000},
    { (1 << BTN_IDX_UP)   | (1 << BTN_IDX_RIGHT),   {400, 1200}, {195, 195}, 0x00000000},
    { (1 << BTN_IDX_DOWN) | (1 << BTN_IDX_RIGHT),   {400, 1600}, {195, 195}, 0x00000000},

    { 1 << BTN_IDX_A,  {650, 1400}, {250, 250}, 0xFFFFFF44},
    { 1 << BTN_IDX_B,  {800, 1250}, {250, 250}, 0xFFFFFF44},

};

short screenx, screeny;
unsigned frames = 0;
double ThisTime;
double LastFPSTime;

bool init_platform() {
    return true;
}

bool init_audio() {
    return true;
}
bool init_video()
{
    memset(frontbuffer, 0, sizeof(frontbuffer));
#ifdef ANDROID_BACKEND
    CNFGSetupFullscreen( "PicoPico", 0 );
#else
    CNFGSetup("PicoPico", SCREEN_WIDTH*UPSCALE_FACTOR, SCREEN_HEIGHT * UPSCALE_FACTOR);
#endif
    _rgb32_buf = (uint32_t*)malloc(SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(uint32_t) * UPSCALE_FACTOR*UPSCALE_FACTOR);
    tex = CNFGTexImage(_rgb32_buf, SCREEN_WIDTH*UPSCALE_FACTOR, SCREEN_HEIGHT * UPSCALE_FACTOR);
    CNFGGetDimensions(&screenx, &screeny );
    glBindTexture( GL_TEXTURE_2D, tex );
    LastFPSTime = OGGetAbsoluteTime();
    return true;
}

void video_close()
{
    free(_rgb32_buf);
}

void gfx_flip() {

    for(uint8_t i = 0; i<sizeof(buttons_frame)/ sizeof(buttons_frame[0]); i++) {
        buttons_frame[i] = buttons[i] > 0 && (buttons_frame[i] == 0);
    }
    uint8_t r,g,b,a;
    a = 0xff ;

    for(uint16_t y=0; y<SCREEN_HEIGHT*UPSCALE_FACTOR; y++) {
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
        }
    }


    CNFGClearFrame();
    glTexSubImage2D( GL_TEXTURE_2D, 0, 0, 0, SCREEN_WIDTH * UPSCALE_FACTOR, SCREEN_HEIGHT*UPSCALE_FACTOR, GL_RGBA, GL_UNSIGNED_BYTE, _rgb32_buf);
    CNFGBlitTex(tex, (screenx - SCREEN_WIDTH * UPSCALE_FACTOR)/2, 0, SCREEN_WIDTH * UPSCALE_FACTOR, SCREEN_HEIGHT*UPSCALE_FACTOR);
    frames++;
	CNFGColor( 0x444444FF );

	const float radius = 300.f;
	const int numSegments = 36;  // Number of line segments
	const float angleIncrement = 4*M_PI / (2.0f * numSegments);  // Angle increment

	// Calculate and draw quads for a filled circle
    for (int i = 0; i < numSegments; ++i) {
        float angle1 = 2.0f * M_PI * (static_cast<float>(i) / numSegments);
        float angle2 = 2.0f * M_PI * (static_cast<float>(i + 1) / numSegments);
        
        float x1 = radius * cos(angle1) + 300;
        float y1 = radius * sin(angle1) + 1500;
        float x2 = radius * cos(angle2) + 300;
        float y2 = radius * sin(angle2) + 1500;
        // good EmitQuad(0.0f, 0.0f, x1, y1, x2, y2, 0.0f, 0.0f);
		// bad EmitQuad(x1, y1, x2, y2, x2, y2, x1, y1);
		EmitQuad( 300,1500,x1,y1,x2,y2,x2,1500 ); // idk reqct
											 // lmao circle made of rects
	}

	/*
	for (int i = 0; i <= numSegments; ++i) {
        float angle = i * angleIncrement + M_PI;
        float x1 = radius * cos(angle)  + 300;
        float y1 = radius * sin(angle)  + 1500;
        float x2 = radius * cos(angle + angleIncrement)  + 300;
        float y2 = radius * sin(angle + angleIncrement)  + 1500;
		//printf("at %f,%f -> %f, %f\n", x1, y1, x2, y2);
		CNFGTackSegment(x1, y1, x2, y2);
		CNFGTackSegment(x1+1, y1+1, x2+1, y2+1); // double width
		CNFGTackSegment(x1-1, y1-1, x2-1, y2-1); // double width
    }
	*/
    draw_hud();

    CNFGSwapBuffers();

    ThisTime = OGGetAbsoluteTime();
    if( ThisTime > LastFPSTime + 1 )
    {
    //    printf( "FPS: %d\n", frames );
        frames = 0;
        LastFPSTime+=1;
    }
}

void draw_hud() {
    for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(button_coords_t); i++) {
		if(button_coords[i].color == 0) continue;
        bool set = true;
        int bitIndex = 0;
        int mask = button_coords[i].buttonMask; // this is something like (1 << UP) | (1 << LEFT)
        while (mask != 0) {
            if (mask & 1) {
                //printf("bitindex %d \n", bitIndex);
                set &= buttons[bitIndex] > 0;
            }
            mask >>= 1;
            bitIndex++;
        }
        set ? CNFGColor( 0xFFFFFF88 ) : CNFGColor( button_coords[i].color );
        CNFGTackRectangle(button_coords[i].coords.x,
                          button_coords[i].coords.y,
                          button_coords[i].coords.x + button_coords[i].size.x,
                          button_coords[i].coords.y + button_coords[i].size.y);
    }
	CNFGColor( 0x000000FF );
	CNFGTackSegment(200, 1200, 200, 1800); // first vertical
	CNFGTackSegment(400, 1200, 400, 1800); // second vertical
	CNFGTackSegment(201, 1200, 201, 1800); // first vertical
	CNFGTackSegment(401, 1200, 401, 1800); // second vertical
	CNFGTackSegment(199, 1200, 199, 1800); // first vertical
	CNFGTackSegment(399, 1200, 399, 1800); // second vertical

	CNFGTackSegment(  0, 1400, 600, 1400); // first horizontal
	CNFGTackSegment(  0, 1600, 600, 1600); // second horizontal

}
void delay(uint16_t ms) {
    OGUSleep(ms*1000);
}
bool handle_input() {
    // not polling, idk
    return !CNFGHandleInput();
}
uint32_t now() {
    double milliseconds = OGGetAbsoluteTime() * 1000.0;
    double integerPart, decimalPart;

    decimalPart = modf(milliseconds, &integerPart);

    integerPart = fmod(integerPart, UINT32_MAX - 1000);
    return integerPart + decimalPart;
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
void deal_with_button( int x, int y, int button, int bDown) {
    if(!bDown) {
        for(uint8_t i = 0; i<sizeof(buttons)/sizeof(buttons[0]); i++) {
            buttons[i] &= ~(1 << button);
        }
    } else {
        for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(button_coords_t); i++) {
            if (x>=button_coords[i].coords.x && x<=(button_coords[i].coords.x+button_coords[i].size.x) && y>=button_coords[i].coords.y && y<=(button_coords[i].coords.y+button_coords[i].size.y)) {
                //buttons_frame[i] = bDown && !buttons[i];
                int bitIndex = 0;
                int mask = button_coords[i].buttonMask; // this is something like (1 << UP) | (1 << LEFT)
                while (mask != 0) {
                    if (mask & 1) {
                        printf("bitindex %d \n", bitIndex);
                        buttons[bitIndex] |= (1 << button); // bitIndex = "UP" or "LEFT"
                    }
                    mask >>= 1;
                    bitIndex++;
                }
            }
        }
    }
    for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(button_coords_t); i++) {
        printf("%x ", buttons[i]);
    }
    printf("\n");
}
void HandleButton( int x, int y, int button, int bDown ) {
    printf("down %d,%d b:%d down:%d\n", x,y,button,bDown);
    deal_with_button(x, y, button, bDown);
}

void HandleMotion( int x, int y, int button ) {
    bool seen = false;
    for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(button_coords_t); i++) {
        if (x>=button_coords[i].coords.x && x<=(button_coords[i].coords.x+button_coords[i].size.x) && y>=button_coords[i].coords.y && y<=(button_coords[i].coords.y+button_coords[i].size.y)) {
            deal_with_button(x, y, button, 1);
            seen = true;
        }
    }
    if(!seen) deal_with_button(x, y, button, 0);
}
void HandleDestroy() {
    exit(0);
}

void HandleSuspend()
{
}

void HandleResume()
{
}
