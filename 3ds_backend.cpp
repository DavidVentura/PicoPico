#include "main.cpp"
// Simple citro2d untextured shape example
#include <3ds.h>
#include <citro3d.h>
#include <citro2d.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>


//#define SCREEN_WIDTH  400
//#define SCREEN_HEIGHT 240

#define COMBINED_IDX(x, y) ((y) << 6) | ((x) >> 1)
#define BITMASK(n) (1U<<(n))

static C2D_Image pico_image;

C3D_Tex *pico_tex;
Tex3DS_SubTexture *pico_subtex;

C3D_RenderTarget* topTarget;
C3D_RenderTarget* bottomTarget;

u16* pico_pixel_buffer;

const GPU_TEXCOLOR texColor = GPU_RGB565;

#define CLEAR_COLOR 0xFF000000
#define BYTES_PER_PIXEL 2

size_t pixel_buffer_size = SCREEN_WIDTH*SCREEN_HEIGHT*BYTES_PER_PIXEL;
size_t pixIdx = 0;



uint8_t getPixelNibble(const int x, const int y, uint8_t* targetBuffer) {
	if (x < 0 || x > 127 || y < 0 || y > 128) {
		return 0;
	}

	return (BITMASK(0) & x) 
		? targetBuffer[COMBINED_IDX(x, y)] >> 4  //just last 4 bits
		: targetBuffer[COMBINED_IDX(x, y)] & 0x0f; //just first 4 bits
}

void setPixelNibble(const int x, const int y, uint8_t value, uint8_t* targetBuffer) {
	if (x < 0 || x > 127 || y < 0 || y > 128) {
		return;
	}

	targetBuffer[COMBINED_IDX(x, y)] = (BITMASK(0) & x)
		? (targetBuffer[COMBINED_IDX(x, y)] & 0x0f) | (value << 4 & 0xf0)
		: (targetBuffer[COMBINED_IDX(x, y)] & 0xf0) | (value & 0x0f);
}

void drawRectangle(int x, int y, int w, int h, uint8_t c, uint8_t* targetBuffer) {
	c = c & 0x0F;

	for(int i = 0; i < h; i++) {
		for (int j = 0; j < w; j++) {
			setPixelNibble(x + j, y + i, c, targetBuffer);
		}
	}

	/*
	for(int j = 0; j < h; j++) {
		memset(targetBuffer + COMBINED_IDX(x, y), ((c << 4) & c), x / 2);
	}
	*/
}


bool init_video() {
	//Initialize console on top screen. Using NULL as the second argument tells the console library to use the internal console structure as current one

	// Init libs
	gfxInitDefault();
	//consoleInit(GFX_BOTTOM, NULL);
	C3D_Init(C3D_DEFAULT_CMDBUF_SIZE);
	C2D_Init(C2D_DEFAULT_MAX_OBJECTS);
	C2D_Prepare();
	

	// Create screens
	topTarget = C2D_CreateScreenTarget(GFX_TOP, GFX_LEFT);

	pico_tex = (C3D_Tex*)linearAlloc(sizeof(C3D_Tex));


	C3D_TexInitVRAM(pico_tex, 128, 128, texColor);
	C3D_TexSetFilter(pico_tex, GPU_NEAREST, GPU_NEAREST);

	

	pico_subtex = (Tex3DS_SubTexture*)linearAlloc(sizeof(Tex3DS_SubTexture));
	pico_subtex->width = 128;
	pico_subtex->height = 128;
	pico_subtex->left = 0.0f;
	pico_subtex->top = 1.0f;
	pico_subtex->right = 1.0f;
	pico_subtex->bottom = 0.0f;

	pico_image.tex = pico_tex;
	pico_image.subtex = pico_subtex;

	pico_pixel_buffer = (u16*)linearAlloc(pixel_buffer_size);

	return true;
}
//---------------------------------------------------------------------------------

void gfx_flip() {
	// 1.5-1.8ms menu frame
	// 1.0-1.3ms menu without copying the pix buffer
	// 1.44-1,74ms menu frame no TargetClear

	//write pixel data to to texture
    for(uint8_t y=0; y<SCREEN_HEIGHT; y++) {
        for(uint8_t x=0; x<SCREEN_WIDTH; x++){
            palidx_t idx = get_pixel(x, y);
	    	color_t color = palette[idx];
			pico_pixel_buffer[y*SCREEN_WIDTH+x] = color;
        }
	}

	GSPGPU_FlushDataCache(pico_pixel_buffer, pixel_buffer_size);

	C3D_SyncDisplayTransfer(
			(u32*)pico_pixel_buffer, GX_BUFFER_DIM(128, 128),
			(u32*)(pico_tex->data), GX_BUFFER_DIM(128, 128),
			(GX_TRANSFER_FLIP_VERT(0) | GX_TRANSFER_OUT_TILED(1) | GX_TRANSFER_RAW_COPY(0) |
			 GX_TRANSFER_IN_FORMAT(GX_TRANSFER_FMT_RGB565) | GX_TRANSFER_OUT_FORMAT(GX_TRANSFER_FMT_RGB565) |
			 GX_TRANSFER_SCALING(GX_TRANSFER_SCALE_NO))
			);

	C3D_FrameBegin(C3D_FRAME_SYNCDRAW);

	//C2D_TargetClear(topTarget, CLEAR_COLOR);
	C2D_SceneBegin(topTarget);

	/*
	pico_subtex->width = 128;
	pico_subtex->height = 128;
	pico_subtex->left = 0.0f;
	pico_subtex->top = 1.0f;
	pico_subtex->right = 1.0f;
	pico_subtex->bottom = 0.0f;
	*/

	C2D_DrawImageAtRotated(
			pico_image,
			200,
			120,
			.5,
			0,
			NULL,
			//1.5f,
			//1.5f);
			2.f,
			2.f); // losing 16px
	C2D_Flush();
	C3D_FrameEnd(0);
}

uint32_t now() {
	return (svcGetSystemTick()/CPU_TICKS_PER_MSEC);
}
uint8_t battery_left() {
	return 0;
}
void video_close() {
	C3D_TexDelete(pico_tex);

	linearFree(pico_tex);
	linearFree(pico_subtex);
    linearFree(pico_pixel_buffer);

	// Deinit libs
	C2D_Fini();
	C3D_Fini();
	gfxExit();
}

uint8_t current_hour() {
	return 0;
}

uint8_t current_minute() {
	return 0;
}

bool handle_input() {
	if (!aptMainLoop()) return false;
	hidScanInput();
	//hidKeysDown returns information about which buttons have been just pressed (and they weren't in the previous frame)
	uint32_t kDown = hidKeysDown();
	//hidKeysHeld returns information about which buttons have are held down in this frame
	uint32_t kHeld = hidKeysHeld();
	//hidKeysUp returns information about which buttons have been just released
	uint32_t kUp = hidKeysUp();

	uint32_t current_down = kDown | kHeld;
    memset(buttons, 0, sizeof(buttons));
    memset(buttons_frame, 0, sizeof(buttons_frame));

	if (current_down & KEY_START) return true;

	if (current_down & KEY_LEFT) 		buttons[BTN_IDX_LEFT] 	= 1;
	if (current_down & KEY_RIGHT) 		buttons[BTN_IDX_RIGHT] 	= 1;
	if (current_down & KEY_UP) 			buttons[BTN_IDX_UP] 	= 1;
	if (current_down & KEY_DOWN) 		buttons[BTN_IDX_DOWN] 	= 1;
	if (current_down & (KEY_A | KEY_X)) buttons[BTN_IDX_A] 		= 1;
	if (current_down & (KEY_B | KEY_Y)) buttons[BTN_IDX_B] 		= 1;

	if (kDown & KEY_LEFT) 			buttons_frame[BTN_IDX_LEFT] 	= 1;
	if (kDown & KEY_RIGHT) 			buttons_frame[BTN_IDX_RIGHT] 	= 1;
	if (kDown & KEY_UP) 			buttons_frame[BTN_IDX_UP] 		= 1;
	if (kDown & KEY_DOWN) 			buttons_frame[BTN_IDX_DOWN] 	= 1;
	if (kDown & (KEY_A | KEY_X)) 	buttons_frame[BTN_IDX_A] 		= 1;
	if (kDown & (KEY_B | KEY_Y)) 	buttons_frame[BTN_IDX_B] 		= 1;

	printf("\x1b[6;1H"); //Move the cursor to the fourth row because on the third one we'll write the circle pad position
	printf("Input %8lx\r", current_down);
	return false;
}

void delay(unsigned short ms) {
	svcSleepThread( ((uint64_t)ms)* 1000000LL);
}
bool init_audio() {
	return true;
}
uint8_t wifi_strength() {
	return 0;
}
void draw_hud() {
}

