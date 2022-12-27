#include <SDL.h>
#include <sys/time.h>
#ifndef ENGINE
#include "engine.c"
#endif
#include "data.h"

//Screen dimension constants

SDL_Window* gWindow = NULL;
SDL_Renderer* gRenderer = NULL;
SDL_Event e;

bool init_video()
{
	memset(frontbuffer, 0, sizeof(frontbuffer));

    //Initialize SDL
    if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO ) < 0 )
    {
	printf( "SDL could not initialize! SDL_Error: %s\n", SDL_GetError() );
	return false;
    }
    //Create window
    gWindow = SDL_CreateWindow( "Pico Pico", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, W_SCREEN_WIDTH, W_SCREEN_HEIGHT, SDL_WINDOW_SHOWN );
    if( gWindow == NULL )
    {
	printf( "Window could not be created! SDL_Error: %s\n", SDL_GetError() );
	return false;
    }
    gRenderer = SDL_CreateRenderer( gWindow, -1, SDL_RENDERER_ACCELERATED );
    if( gRenderer == NULL )
    {
	printf( "Renderer could not be created! SDL Error: %s\n", SDL_GetError() );
	return false;
    }
    SDL_RenderSetLogicalSize(gRenderer, SCREEN_WIDTH, SCREEN_HEIGHT + HUD_HEIGHT);
    SDL_SetRenderDrawColor( gRenderer, 0x00, 0x00, 0x00, 0x00 );
    SDL_RenderClear(gRenderer);
    SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );

    return true;
}

void video_close()
{
    SDL_DestroyRenderer( gRenderer);
    SDL_DestroyWindow( gWindow );
    gWindow = NULL;
    gRenderer = NULL;

    //Quit SDL subsystems
    SDL_Quit();
}

void draw_hud() {
    for(uint8_t y=0; y<HUD_HEIGHT; y++) {
        for(uint8_t x=0; x<SCREEN_WIDTH; x++){
            uint16_t first_byte_pos = x*2+y*SCREEN_WIDTH*2;
            uint8_t msb = hud_buffer[first_byte_pos  ];
            uint8_t lsb = hud_buffer[first_byte_pos+1];
            uint16_t color = (((uint16_t)msb)<<8) | lsb;
            SDL_SetRenderDrawColor(gRenderer, (color >> 11) << 3, ((color >> 5) & 0x3f) << 2, (color & 0x1f) << 3, 0xFF );
            SDL_RenderDrawPoint(gRenderer, x, y);
        }
    }
}

void gfx_flip() {
    for(uint8_t y=0; y<SCREEN_HEIGHT; y++)
        for(uint8_t x=0; x<SCREEN_WIDTH; x++){
            uint16_t color = frontbuffer[x+y*SCREEN_HEIGHT];
            // uint16_t color = 0xffff;
            SDL_SetRenderDrawColor(gRenderer, (color >> 11) << 3, ((color >> 5) & 0x3f) << 2, (color & 0x1f) << 3, 0xFF );
            SDL_RenderDrawPoint(gRenderer, x, y + HUD_HEIGHT);
        }
    draw_hud();
    SDL_RenderPresent(gRenderer);
    SDL_UpdateWindowSurface( gWindow );
}

void delay(uint16_t ms) {
    SDL_Delay(ms);
}

bool handle_input() {
    while( SDL_PollEvent( &e ) != 0 )
    {
	//User requests quit
	if( e.type == SDL_QUIT )
	{
	    return true;
	} else if (e.type == SDL_KEYDOWN) {
	    switch( e.key.keysym.sym )
	    {
		case SDLK_LEFT:
		    buttons[0] = 1;
		    break;

		case SDLK_RIGHT:
		    buttons[1] = 1;
		    break;

		case SDLK_UP:
		    buttons[2] = 1;
		    break;

		case SDLK_DOWN:
		    buttons[3] = 1;
		    break;

		case SDLK_z:
		    buttons[4] = 1;
		    break;

		case SDLK_x:
		    buttons[5] = 1;
		    break;

		case SDLK_ESCAPE:
		case SDLK_q:
		    return true;

	    }
	} else if (e.type == SDL_KEYUP) {
	    switch( e.key.keysym.sym )
	    {
		case SDLK_LEFT:
		    buttons[0] = 0;
		    break;

		case SDLK_RIGHT:
		    buttons[1] = 0;
		    break;

		case SDLK_UP:
		    buttons[2] = 0;
		    break;

		case SDLK_DOWN:
		    buttons[3] = 0;
		    break;

		case SDLK_z:
		    buttons[4] = 0;
		    break;

		case SDLK_x:
		    buttons[5] = 0;
		    break;

	    }
	}
    }
    return false;
}
uint32_t now() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (((long long)tv.tv_sec)*1000)+(tv.tv_usec/1000);
}

void MyAudioCallback(void* userdata, Uint8* stream, int len) {
    uint16_t samples = SAMPLES_PER_DURATION * SAMPLES_PER_BUFFER;
    memset(stream, 0, len);
    for(uint8_t i=0; i<4; i++)
        fill_buffer((uint16_t*)stream, &channels[i], samples);
}

bool init_audio() {

    SDL_AudioSpec want, have;
    SDL_AudioDeviceID dev;

    SDL_memset(&want, 0, sizeof(want)); /* or SDL_zero(want) */
    want.freq = SAMPLE_RATE;
    want.format = AUDIO_S16LSB;
    want.channels = 1;
    want.samples = SAMPLES_PER_DURATION*SAMPLES_PER_BUFFER;
    want.callback = MyAudioCallback;  // you wrote this function elsewhere.
    dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if(dev < 0) {
        printf("Failed to OpenAudioDevice\n");
        return false;
    }

    printf("dev %d\n", dev); 
    SDL_PauseAudioDevice(dev, 0);
    SDL_Delay(0);
    return true;
}
