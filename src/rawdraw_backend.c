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

#define CNFA_IMPLEMENTATION
#define CNFG_IMPLEMENTATION
#define CNFGOGL

#include "cnfa/CNFA.h"
#include "rawdraw/CNFG.h"


#include <time.h>
#include <sys/time.h>
#include "backend.h"
#ifndef ENGINE
#include "engine.c"
#endif
#include "data.h"

#ifdef ANDROID_BACKEND
const uint8_t UPSCALE_FACTOR = 8;
#else
const uint8_t UPSCALE_FACTOR = 4;
#endif
uint32_t* _rgb32_buf = NULL;
unsigned int tex = 0;


struct CNFADriver * cnfa = NULL;

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

volatile static bool exiting;
bool init_platform() {
	exiting = false;
    return true;
}

void Callback( struct CNFADriver * sd, short * out, short * in, int framesp, int framesr )
{
	if (exiting) return;
	// framesp = size of 1 channel in samples

	memset(out, 0, framesp*2);
	for(uint8_t i=0; i<4; i++)
		fill_buffer((uint16_t*)out, &channels[i], framesp);
}

bool init_audio() {
	printf("Init Audio - Registering callback\n");
#ifdef ANDROID_BACKEND
	InitCNFAAndroid( Callback, "IDK APP", SAMPLE_RATE, 0, 1, 0, SAMPLES_PER_DURATION*2, 0, 0, 0 );
#else
	cnfa = CNFAInit( 
		// no audio on pulse?
		//"PULSE",
		"ALSA", //You can select a plaback driver, or use 0 for default.
		//0, //default
		"cnfa_example", Callback,
		SAMPLE_RATE, //Requested samplerate for playback
		0, //Requested samplerate for recording
		1, //Number of playback channels.
		0, //Number of record channels.
		SAMPLES_PER_DURATION, //Buffer size in frames.
		0, //Could be a string, for the selected input device - but 0 means default.
		0,  //Could be a string, for the selected output device - but 0 means default.
		0 // 'opaque' value if the driver wanted it.
	 );
#endif

    return true;
}
void _init_tex() {
	if(tex) {
		CNFGDeleteTex(tex);
	}
    tex = CNFGTexImage(_rgb32_buf, SCREEN_WIDTH*UPSCALE_FACTOR, SCREEN_HEIGHT * UPSCALE_FACTOR);
    CNFGGetDimensions(&screenx, &screeny );
    glBindTexture( GL_TEXTURE_2D, tex );
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
	_init_tex();
    return true;
}

void video_close()
{
	exiting = true;
	delay(1);
	if(cnfa) CNFAClose(cnfa);
	if(tex) CNFGDeleteTex(tex);
	if (_rgb32_buf) free(_rgb32_buf);
}

void gfx_flip() {
	if(!tex) {
		printf("TRIED TO FLIP WITH NO TEX\n");
		return;
	}

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

            _rgb32_buf[y*SCREEN_WIDTH*UPSCALE_FACTOR+x] = (r << 24) | (g << 16) | (b << 8) | a;
        }
    }


    CNFGClearFrame();
    glTexSubImage2D( GL_TEXTURE_2D, 0, 0, 0, SCREEN_WIDTH * UPSCALE_FACTOR, SCREEN_HEIGHT*UPSCALE_FACTOR, GL_RGBA, GL_UNSIGNED_BYTE, _rgb32_buf);
    CNFGBlitTex(tex, (screenx - SCREEN_WIDTH * UPSCALE_FACTOR)/2, 0, SCREEN_WIDTH * UPSCALE_FACTOR, SCREEN_HEIGHT*UPSCALE_FACTOR);

    draw_hud();

    CNFGSwapBuffers();

}

void draw_onscreen_controls() {
	CNFGColor( 0x444444FF );

	const float radius = 290.f;
	const int numSegments = 48;  // Number of line segments
	const float angleIncrement = 4*M_PI / (2.0f * numSegments);  // Angle increment

	// Calculate and draw quads for a filled circle
    for (int i = 0; i < numSegments; ++i) {
        float angle1 = 2.0f * M_PI * ((float)(i) / numSegments);
        float angle2 = 2.0f * M_PI * ((float)(i + 1) / numSegments);
        
        float x1 = radius * cos(angle1) + 300;
        float y1 = radius * sin(angle1) + 1500;
        float x2 = radius * cos(angle2) + 300;
        float y2 = radius * sin(angle2) + 1500;
        // good EmitQuad(0.0f, 0.0f, x1, y1, x2, y2, 0.0f, 0.0f);
		// bad EmitQuad(x1, y1, x2, y2, x2, y2, x1, y1);
		EmitQuad( 300,1500,x1,y1,x2,y2,x2,1500 ); // idk reqct
											 // lmao circle made of rects
	}

    for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(button_coords_t); i++) {
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
		if (set || button_coords[i].color != 0) {
			set ? CNFGColor( 0x00000022 ) : CNFGColor( button_coords[i].color );
			CNFGTackRectangle(button_coords[i].coords.x,
					button_coords[i].coords.y,
					button_coords[i].coords.x + button_coords[i].size.x,
					button_coords[i].coords.y + button_coords[i].size.y);
		}
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
void draw_hud() {
#ifdef ANDROID_BACKEND
	draw_onscreen_controls();
#endif
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
            buttons_frame[BTN_IDX_LEFT] = bDown == 2;
            buttons[BTN_IDX_LEFT] = bDown;
            break;
        case 65362: // up
            buttons_frame[BTN_IDX_UP] = bDown == 2;
            buttons[BTN_IDX_UP] = bDown;
            break;
        case 65363: // right
            buttons_frame[BTN_IDX_RIGHT] = bDown == 2;
            buttons[BTN_IDX_RIGHT] = bDown;
            break;
        case 65364: // down
            buttons_frame[BTN_IDX_DOWN] = buttons[BTN_IDX_DOWN] == 0 && (buttons_frame[BTN_IDX_DOWN] == 0);
            buttons[BTN_IDX_DOWN] = bDown;
            break;
        case 122: // z
            buttons_frame[BTN_IDX_A] = bDown == 2;
            buttons[BTN_IDX_A] = bDown;
            break;
        case 120: // x
            buttons_frame[BTN_IDX_B] = bDown == 2;
            buttons[BTN_IDX_B] = bDown;
            break;
    }

#ifdef ANDROID
    if( keycode == 4 ) { AndroidSendToBack( 1 ); } //Handle Physical Back Button.
#endif
    fflush(stdout);
}
void deal_with_button( int x, int y, int button, int bDown) {
    if(!bDown) {
        for(uint8_t i = 0; i<sizeof(buttons)/sizeof(uint8_t); i++) {
            buttons[i] &= ~(1 << button);
        }
    } else {
        for(uint8_t i = 0; i<sizeof(button_coords)/sizeof(button_coords_t); i++) {
            if (x>=button_coords[i].coords.x && x<=(button_coords[i].coords.x+button_coords[i].size.x) && y>=button_coords[i].coords.y && y<=(button_coords[i].coords.y+button_coords[i].size.y)) {
                //buttons_frame[i] = bDown && !buttons[i];
                int bitIndex = 0;
                int mask = button_coords[i].buttonMask; // this is something like (1 << UP) | (1 << LEFT)
                while (mask != 0) {
                    if (mask & 1) {
                        buttons[bitIndex] |= (1 << button); // bitIndex = "UP" or "LEFT"
                    }
                    mask >>= 1;
                    bitIndex++;
                }
            }
        }
    }
}
void HandleButton( int x, int y, int button, int bDown ) {
#ifdef ANDROID
    deal_with_button(x, y, button, bDown);
#endif
}

void HandleMotion( int x, int y, int button ) {
#ifdef ANDROID_BACKEND
    bool seen = false;
    for(uint8_t i = 0; i<sizeof(button_coords)/sizeof(button_coords_t); i++) {
        if (x>=button_coords[i].coords.x && x<=(button_coords[i].coords.x+button_coords[i].size.x) && y>=button_coords[i].coords.y && y<=(button_coords[i].coords.y+button_coords[i].size.y)) {
            deal_with_button(x, y, button, 1);
            seen = true;
        }
    }
    if(!seen) deal_with_button(x, y, button, 0);
#endif
}
void HandleDestroy() {
    exit(0);
}

#ifdef ANDROID_BACKEND
void HandleSuspend()
{
	if(tex) {
		CNFGDeleteTex(tex);
	}
}

void HandleResume()
{
	_init_tex();
	suspended = false;
}
#endif

