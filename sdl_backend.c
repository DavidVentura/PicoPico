#include <SDL.h>
#include <SDL_mixer.h>
#include <sys/time.h>
#ifndef ENGINE
#include "engine.c"
#endif
#include "data.h"

//Screen dimension constants

Mix_Chunk* aSound;
SDL_Window* gWindow = NULL;
SDL_Renderer* gRenderer = NULL;
SDL_Event e;
uint8_t smallbitbuf[SAMPLE_RATE*2];

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
    SDL_RenderSetLogicalSize(gRenderer, SCREEN_WIDTH, SCREEN_HEIGHT);
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

void gfx_flip() {
    for(uint8_t y=0; y<SCREEN_HEIGHT; y++)
        for(uint8_t x=0; x<SCREEN_WIDTH; x++){
            uint16_t color = frontbuffer[x+y*SCREEN_HEIGHT];
            // uint16_t color = 0xffff;
            SDL_SetRenderDrawColor(gRenderer, (color >> 11) << 3, ((color >> 5) & 0x3f) << 2, (color & 0x1f) << 3, 0xFF );
            SDL_RenderDrawPoint(gRenderer, x, y);
        }
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
            printf("sound\n");
            // channel, sound, repeat#
		    buttons[4] = 1;
		    break;

		case SDLK_x:
		    buttons[5] = 1;
		    break;

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


void play_sfx_buffer(){
    for(uint16_t i=0; i<sizeof(smallbitbuf)/2; i++) {
        smallbitbuf[i*2  ] = audiobuf[i] >> 8;
        smallbitbuf[i*2+1] = audiobuf[i] & 0x00ff;
    }
    Mix_PlayChannel(-1, aSound, 0);
}

bool init_audio() {
    if( Mix_OpenAudio(SAMPLE_RATE, AUDIO_S16MSB, 1, 256 ) < 0 ) { // 256 = BUFFER SIZE
        printf( "SDL_mixer could not initialize! SDL_mixer Error: %s\n", Mix_GetError() );
        return false;
    }

    aSound = (Mix_Chunk*)malloc(sizeof(Mix_Chunk));
    aSound->allocated = 0;
    aSound->abuf = smallbitbuf; // FIXME
    aSound->alen = sizeof(smallbitbuf)/2; // FIXME
    aSound->volume = 96;

    return true;
}
