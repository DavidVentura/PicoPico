#include <SDL.h>
#include <sys/time.h>
#ifndef ENGINE
#include "engine.c"
#endif
#include "data.h"

//Screen dimension constants
const int V_SCREEN_WIDTH = 128;
const int V_SCREEN_HEIGHT = 128;

static uint16_t buffer[128*128];
SDL_Window* gWindow = NULL;
SDL_Renderer* gRenderer = NULL;
SDL_Event e;

void gfx_circlefill(int16_t x, int16_t y, int16_t radius, uint8_t* color)
{
    if (color != NULL)
	SDL_SetRenderDrawColor(gRenderer, color[0], color[1], color[2], 255);
    for (int w = 0; w < radius * 2; w++)
    {
        for (int h = 0; h < radius * 2; h++)
        {
            int dx = radius - w; // horizontal offset
            int dy = radius - h; // vertical offset
            if ((dx*dx + dy*dy) <= (radius * radius))
            {
                put_pixel(x + dx, y + dy, color);
            }
        }
    }
}

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
	put_pixel(centreX + x, centreY - y, color);
	put_pixel(centreX + x, centreY + y, color);
	put_pixel(centreX - x, centreY - y, color);
	put_pixel(centreX - x, centreY + y, color);
	put_pixel(centreX + y, centreY - x, color);
	put_pixel(centreX + y, centreY + x, color);
	put_pixel(centreX - y, centreY - x, color);
	put_pixel(centreX - y, centreY + x, color);

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
	memset(buffer, 0, sizeof(buffer));

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

static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p){
    if (y >= V_SCREEN_HEIGHT) return;
    if (x >= V_SCREEN_WIDTH) return;
	SDL_SetRenderDrawColor(gRenderer, *p, *(p+1), *(p+2), 0xFF );
    SDL_RenderDrawPoint(gRenderer, x, y);
    // FIXME this is wrong
    buffer[x+y*V_SCREEN_HEIGHT] = (p-palette[0])/3;
}

uint16_t get_pixel(uint8_t x, uint8_t y) {
	return buffer[x+y*128];
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

		case SDLK_x:
		    buttons[4] = 1;
		    break;

		case SDLK_z:
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

		case SDLK_x:
		    buttons[4] = 0;
		    break;

		case SDLK_z:
		    buttons[5] = 0;
		    break;

	    }
	}
    }
    return false;
}

void gfx_cls(uint8_t* color) {
    SDL_SetRenderDrawColor( gRenderer, color[0], color[1], color[2], 0x00 );
    SDL_RenderClear( gRenderer );
}

void gfx_rect(uint8_t x, uint8_t y, uint8_t w, uint8_t h, const uint8_t* color) {
    if ( color != NULL ) {
	SDL_SetRenderDrawColor(gRenderer, color[0], color[1], color[2], 255);
    }
    SDL_Rect rect = {.x = x, .y = y, .w = w, .h = h };
    SDL_RenderDrawRect(gRenderer, &rect);
}

void gfx_rectfill(uint8_t x, uint8_t y, uint8_t w, uint8_t h, const uint8_t* color) {
    if ( color != NULL ) {
	SDL_SetRenderDrawColor(gRenderer, color[0], color[1], color[2], 255);
    }
    SDL_Rect rect = {.x = x, .y = y, .w = w, .h = h };
    SDL_RenderFillRect(gRenderer, &rect);
}
uint32_t now() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (((long long)tv.tv_sec)*1000)+(tv.tv_usec/1000);
}

void gfx_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, const uint8_t* color) {
    if ( color != NULL ) {
	SDL_SetRenderDrawColor(gRenderer, color[0], color[1], color[2], 255);
    }
	SDL_RenderDrawLine(gRenderer, x0, y0, x1, y1);
}
