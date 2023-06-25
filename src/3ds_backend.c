// Simple citro2d untextured shape example
#include <3ds.h>
#include <citro3d.h>
#include <citro2d.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>


#define COMBINED_IDX(x, y) ((y) << 6) | ((x) >> 1)
#define BITMASK(n) (1U<<(n))

#define demo_SAMPLESPERBUF (SAMPLE_RATE / 30)
#define demo_BYTESPERSAMPLE 2

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
float scaling_factor = 2.f;
size_t stream_offset = 0;
u16 *audioBuffer;
ndspWaveBuf waveBuf[2];
bool which_buf = false;
C2D_Text instructions;
C2D_TextBuf g_staticBuf;

void _render() {
	//	necessary??
	GSPGPU_FlushDataCache(pico_pixel_buffer, pixel_buffer_size);

	C3D_SyncDisplayTransfer(
			(u32*)pico_pixel_buffer, GX_BUFFER_DIM(128, 128),
			(u32*)(pico_tex->data), GX_BUFFER_DIM(128, 128),
			(GX_TRANSFER_FLIP_VERT(0) | GX_TRANSFER_OUT_TILED(1) | GX_TRANSFER_RAW_COPY(0) |
			 GX_TRANSFER_IN_FORMAT(GX_TRANSFER_FMT_RGB565) | GX_TRANSFER_OUT_FORMAT(GX_TRANSFER_FMT_RGB565) |
			 GX_TRANSFER_SCALING(GX_TRANSFER_SCALE_NO))
			);

	C3D_FrameBegin(C3D_FRAME_SYNCDRAW);


	C2D_TargetClear(topTarget, CLEAR_COLOR);
	C2D_SceneBegin(topTarget);

	/*
	 * // necessary??
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
			scaling_factor,
			scaling_factor); // losing 16px; fractional scaling is terrible. 1.f is "too small"
	C2D_Flush();

	// Draw text labels on bottom
	/*
	C2D_TargetClear(bottomTarget, CLEAR_COLOR);
	C2D_SceneBegin(bottomTarget);
	C2D_DrawText(&instructions, C2D_AtBaseline | C2D_WithColor | C2D_AlignCenter, 150.0f, 40.0f, 0.5f, 0.75f, 0.75f, C2D_Color32f(1.0f,1.0f,1.0f,1.0f));
	C2D_Flush();
	*/

	C3D_FrameEnd(0);
}
bool init_video() {

	//APT_SetAppCpuTimeLimit(35); // apparently 25% is the sweet spot for os core usage?
	// Init libs
	gfxInitDefault();
	consoleInit(GFX_BOTTOM, NULL);
	C3D_Init(C3D_DEFAULT_CMDBUF_SIZE);
	C2D_Init(C2D_DEFAULT_MAX_OBJECTS);
	C2D_Prepare();
	

	// Create screens
	topTarget = C2D_CreateScreenTarget(GFX_TOP, GFX_LEFT);
	bottomTarget = C2D_CreateScreenTarget(GFX_BOTTOM, GFX_LEFT);

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

	g_staticBuf  = C2D_TextBufNew(100);
	C2D_TextParse(&instructions, g_staticBuf, "SELECT to resize\nSTART to quit");
	C2D_TextOptimize(&instructions);
	return true;
}
//---------------------------------------------------------------------------------
//----------------------------------------------------------------------------
void _fill_buffer(void *audioBuffer,size_t offset, size_t size, int frequency ) {
//----------------------------------------------------------------------------

	u16 *dest = (u16*)audioBuffer;

	for (int i=0; i<size; i++) {

		s16 sample = INT16_MAX * sin(frequency*(2*M_PI)*(offset+i)/SAMPLE_RATE);

		dest[i] = sample;
		//dest[i] = (sample<<16) | (sample & 0xffff);
	}

	DSP_FlushDataCache(audioBuffer,size);

}

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
	_render();

	// FIXME: design is expecting an audio callback. maybe timer?
	/*
	for(uint8_t i=0; i<4; i++)
		fill_buffer((uint16_t*)waveBuf.data_pcm16, &channels[i], waveBuf.nsamples);

	DSP_FlushDataCache(audioBuffer, waveBuf.nsamples); // num samples, but bytes-per-sample? 2?
	*/
	if (waveBuf[which_buf].status == NDSP_WBUF_DONE) {
		//_fill_buffer(waveBuf[which_buf].data_pcm16, stream_offset, waveBuf[which_buf].nsamples,440);
		memset(waveBuf[which_buf].data_pcm16, 0, waveBuf[which_buf].nsamples*2); // bytes per buff
		for(uint8_t i=0; i<4; i++)
			fill_buffer((uint16_t*)waveBuf[which_buf].data_pcm16, &channels[i], waveBuf[which_buf].nsamples);
		ndspChnWaveBufAdd(0, &waveBuf[which_buf]);
		stream_offset += waveBuf[which_buf].nsamples;
		which_buf = !which_buf;
	}

}


uint32_t now() {
	return (uint32_t)osGetTime();
}
uint8_t battery_left() {
	return 0;
}
void video_close() {

	// free resources
	C3D_TexDelete(pico_tex);

	linearFree(pico_tex);
	linearFree(pico_subtex);
    linearFree(pico_pixel_buffer);

	// Deinit libs
	C2D_Fini();
	C3D_Fini();

	ndspExit();
	linearFree(audioBuffer);
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
	if (kDown & KEY_SELECT) {
		if (scaling_factor == 2.f) {
			scaling_factor = 1.f;
		} else {
			scaling_factor = 2.f;
		}
	}

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

	return false;
}

void delay(unsigned short ms) {
	svcSleepThread( ((uint64_t)ms)* 1000000LL);
}
bool init_audio() {

	audioBuffer = (u16*)linearAlloc(SAMPLES_PER_DURATION*SAMPLES_PER_BUFFER*demo_BYTESPERSAMPLE*2); // 2 bufs
	ndspInit();

	ndspSetOutputMode(NDSP_OUTPUT_MONO);

	ndspChnSetInterp(0, NDSP_INTERP_LINEAR);
	ndspChnSetRate(0, SAMPLE_RATE);
	ndspChnSetFormat(0, NDSP_FORMAT_MONO_PCM16);

	float mix[12];
	memset(mix, 0, sizeof(mix));
	mix[0] = 1.0;
	mix[1] = 1.0;
	ndspChnSetMix(0, mix);

	memset(&waveBuf,0,sizeof(waveBuf));
	waveBuf[0].data_vaddr = &audioBuffer[0];
	waveBuf[0].nsamples = SAMPLES_PER_DURATION*SAMPLES_PER_BUFFER;
	waveBuf[1].data_vaddr = &audioBuffer[SAMPLES_PER_DURATION*SAMPLES_PER_BUFFER*demo_BYTESPERSAMPLE];
	waveBuf[1].nsamples = SAMPLES_PER_DURATION*SAMPLES_PER_BUFFER;
	// 6 * 183 = 1092. example uses 5512 for 2 channels
	ndspChnWaveBufAdd(0, &waveBuf[0]);
	ndspChnWaveBufAdd(0, &waveBuf[1]);
	return true;
}
uint8_t wifi_strength() {
	return osGetWifiStrength();
}
void draw_hud() {
}

