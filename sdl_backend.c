#include <SDL.h>
#include <SDL_image.h>
#ifndef ENGINE
#include "engine.c"
#endif
#include "data.h"

//Screen dimension constants
const int V_SCREEN_WIDTH = 128;
const int V_SCREEN_HEIGHT = 128;
const int SCREEN_WIDTH = 512;
const int SCREEN_HEIGHT = 512;

SDL_Window* gWindow = NULL;
SDL_Renderer* gRenderer = NULL;
SDL_Event e;

void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color)
{
    if (color != NULL)
	SDL_SetRenderDrawColor(gRenderer, color[0], color[1], color[2], 255);
    const int32_t diameter = (radius * 2);

    int32_t x = (radius - 1);
    int32_t y = 0;
    int32_t tx = 1;
    int32_t ty = 1;
    int32_t error = (tx - diameter);

    while (x >= y)
    {
	//  Each of the following renders an octant of the circle
	SDL_RenderDrawPoint(gRenderer, centreX + x, centreY - y);
	SDL_RenderDrawPoint(gRenderer, centreX + x, centreY + y);
	SDL_RenderDrawPoint(gRenderer, centreX - x, centreY - y);
	SDL_RenderDrawPoint(gRenderer, centreX - x, centreY + y);
	SDL_RenderDrawPoint(gRenderer, centreX + y, centreY - x);
	SDL_RenderDrawPoint(gRenderer, centreX + y, centreY + x);
	SDL_RenderDrawPoint(gRenderer, centreX - y, centreY - x);
	SDL_RenderDrawPoint(gRenderer, centreX - y, centreY + x);

	if (error <= 0)
	{
	    ++y;
	    error += ty;
	    ty += 2;
	}

	if (error > 0)
	{
	    --x;
	    tx += 2;
	    error += (tx - diameter);
	}
    }
}

bool init_video()
{

    //Initialize SDL
    if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
    {
	printf( "SDL could not initialize! SDL_Error: %s\n", SDL_GetError() );
	return false;
    }
    //Create window
    gWindow = SDL_CreateWindow( "Pico Pico", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN );
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
    SDL_RenderSetLogicalSize(gRenderer, V_SCREEN_WIDTH, V_SCREEN_HEIGHT);
    SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );

    return true;
}

void put_pixel(uint8_t x, uint8_t y, const uint8_t* p){
	SDL_SetRenderDrawColor(gRenderer, *p, *(p+1), *(p+2), 0xFF );
	SDL_RenderDrawPoint(gRenderer, x, y);
}
SDL_Texture* loadTexture(char* path)
{
    SDL_Surface* loaded = IMG_Load(path);
    if( loaded == NULL )
    {
	printf( "Unable to load image %s! SDL Error: %s\n", path, SDL_GetError() );
	SDL_FreeSurface(loaded);
	return NULL;
    }
    SDL_SetColorKey(loaded, SDL_TRUE, SDL_MapRGB( loaded->format, 0, 0x00, 0x00 ) );

    SDL_Texture* newTexture = SDL_CreateTextureFromSurface( gRenderer, loaded);
    if( newTexture == NULL )
    {
	printf( "Unable to create texture! SDL Error: %s\n", SDL_GetError() );
	SDL_FreeSurface(loaded);
	return NULL;
    }

    SDL_FreeSurface(loaded);
    return newTexture;
}

void video_close()
{
    SDL_DestroyRenderer( gRenderer);
    SDL_DestroyWindow( gWindow );
    gWindow = NULL;
    gRenderer = NULL;

    //Quit SDL subsystems
    IMG_Quit();
    SDL_Quit();
}


void gfx_flip() {
	SDL_RenderPresent(gRenderer);
	SDL_UpdateWindowSurface( gWindow );
}
void delay(uint8_t ms) {
	SDL_Delay(ms );
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

	    }
	}
    }
    return false;
}

char* readFile(char* path, int* fileLen) {
    FILE *f = fopen(path, "rb");
    fseek(f, 0, SEEK_END);
    *fileLen = (int)ftell(f);
    fseek(f, 0, SEEK_SET);

    char *string = malloc(*fileLen + 1);
    fread(string, *fileLen, 1, f);
    fclose(f);

    string[*fileLen] = 0;
    return string;
}

void gfx_cls() {
    SDL_SetRenderDrawColor( gRenderer, 0x00, 0x00, 0x00, 0x00 );
    SDL_RenderClear( gRenderer );
}

void gfx_rectfill(uint8_t x, uint8_t y, uint8_t w, uint8_t h, const uint8_t* color) {
    if ( color != NULL ) {
	SDL_SetRenderDrawColor(gRenderer, color[0], color[1], color[2], 255);
    }
    SDL_Rect rect = {.x = x, .y = y, .w = w, .h = h };
    SDL_RenderFillRect(gRenderer, &rect);
}
