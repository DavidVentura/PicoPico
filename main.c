#include <SDL.h>
#include <SDL_image.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdio.h>

//Screen dimension constants
const int V_SCREEN_WIDTH = 128;
const int V_SCREEN_HEIGHT = 128;

const int SCREEN_WIDTH = 512;
const int SCREEN_HEIGHT = 512;
SDL_Window* gWindow = NULL;
SDL_Renderer* gRenderer = NULL;

struct Spritesheet {
    SDL_Texture* texture;
    int width;
    int height;
};
typedef struct Spritesheet Spritesheet;

Spritesheet* spritesheet = NULL;
Spritesheet* fontsheet = NULL;

lua_State *L = NULL;

int buttons[4] = {0,0,0,0};

const int palette[][3] = {
    {0, 0, 0}, //	black
    {29, 43, 83}, //	dark-blue
    {126, 37, 83}, //	dark-purple
    {0, 135, 81}, //	dark-green
    {171, 82, 54}, //	brown
    {95, 87, 79}, //	dark-grey
    {194, 195, 199}, //	light-grey
    {255, 241, 232}, //	white
    {255, 0, 77}, //	red
    {255, 163, 0}, //	orange
    {255, 236, 39}, //	yellow
    {0, 228, 54}, //	green
    {41, 173, 255}, //	blue
    {131, 118, 156}, //	lavender
    {255, 119, 168}, //	pink
    {255, 204, 170}, //	light-peach 
};


void DrawCircle(SDL_Renderer * renderer, int32_t centreX, int32_t centreY, int32_t radius);
// -
lua_State* init_lua(char* script);
void _to_lua_call(char* fn);
// -

void renderSprite(Spritesheet* s, int n, int x, int y) {
    const int sprite_size = 32;
    const int out_sprite_size = 8;
    const int sprite_count = 16;

    SDL_Rect renderQuad = { x, y, out_sprite_size, out_sprite_size };
    int xIndex = n % sprite_count;
    int yIndex = n / sprite_count;
    SDL_Rect clip = { xIndex * sprite_size, yIndex * sprite_size, sprite_size, sprite_size};
    SDL_RenderCopy( gRenderer, s->texture, &clip, &renderQuad );
    // printf("Rendering sprite xidx: %d, yidx: %d, at x: %d, y: %d\n", xIndex, yIndex, x, y);
    // printf("Clipped at x: %d, y: %d, w: %d, h: %d\n", clip.x, clip.y, clip.w, clip.h);
}
int _lua_print() {
    size_t textLen = 0;
    const char* text = luaL_checklstring(L, 1, &textLen);
    const int x = luaL_checkinteger(L, 2);
    const int y = luaL_checkinteger(L, 3);
    const int paletteIdx = luaL_checkinteger(L, 4);
    const int* newColor = palette[paletteIdx];

    SDL_SetTextureColorMod(fontsheet->texture, newColor[0], newColor[1], newColor[2]);

    for (int i = 0; i<textLen; i++) {
	renderSprite(fontsheet, text[i], x + i * 4, y);
    }
    // renderSprite(font, letter_idx, x + letter_count, y);
}

int _lua_pal() {
    int origIdx = luaL_checkinteger(L, 1);
    int newIdx = luaL_checkinteger(L, 2);
    const int* origColor = palette[origIdx];
    const int* newColor = palette[newIdx];

    // FIXME: need to replace _origColor_ not just multiply "white" with the new color
    SDL_SetTextureColorMod(spritesheet->texture, newColor[0], newColor[1], newColor[2]);
    return 1;
}
int _lua_cls() {
    SDL_SetRenderDrawColor( gRenderer, 0x00, 0x00, 0x00, 0x00 );
    SDL_RenderClear( gRenderer );
    return 1;
}
int _lua_spr() {
    // TODO: optional w/h/flip_x/flip_y
    int n = luaL_checkinteger(L, 1);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    renderSprite(spritesheet, n, x, y);
    return 1; // 1 = success
}
int _lua_rectfill() {
    int x0 = luaL_checkinteger(L, 1);
    int y0 = luaL_checkinteger(L, 2);
    int x1 = luaL_checkinteger(L, 3);
    int y1 = luaL_checkinteger(L, 4);
    int col = luaL_optinteger(L, 5, -1);

    // FIXME: default color should come from draw-state
    int paletteIdx = 14; // pink
    if ( col != -1 ) {
	paletteIdx = col;
    }
    const int* newColor = palette[paletteIdx];
    SDL_Rect rect = {.x = x0, .y = y0, .w = x1, .h = y1 };
    SDL_SetRenderDrawColor(gRenderer, newColor[0], newColor[1], newColor[2], 255);
    SDL_RenderFillRect(gRenderer, &rect);
    return 1;
}
int _lua_circfill() {
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int r = luaL_checkinteger(L, 3);
    int col = luaL_optinteger(L, 4, -1);

    // FIXME: default color should come from draw-state
    int paletteIdx = 0; // pink
    if ( col != -1 ) {
	paletteIdx = col;
    }
    const int* newColor = palette[paletteIdx];
    SDL_SetRenderDrawColor(gRenderer, newColor[0], newColor[1], newColor[2], 255);
    DrawCircle(gRenderer, x, y, r);
    return 1;
}

int _lua_btn() {
    int idx = luaL_checkinteger(L, 1);
    lua_pushboolean(L, buttons[idx]);
    return 1;
}

bool init()
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
    //Initialize PNG loading
    int imgFlags = IMG_INIT_PNG;
    if( !( IMG_Init( imgFlags ) & imgFlags ) )
    {
	printf( "SDL_image could not initialize! SDL_image Error: %s\n", IMG_GetError() );
	return false;
    }

    return true;
}

Spritesheet* loadTexture(char* path)
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
    Spritesheet* s = malloc(sizeof(struct Spritesheet));
    s->texture = newTexture;
    s->width = loaded->w;
    s->height = loaded->h;

    SDL_FreeSurface(loaded);
    return s;
}
void sdl_close()
{
    SDL_DestroyRenderer( gRenderer);
    SDL_DestroyWindow( gWindow );
    gWindow = NULL;
    gRenderer = NULL;

    //Quit SDL subsystems
    IMG_Quit();
    SDL_Quit();
}

void registerLuaFunctions() {
    lua_pushcfunction(L, _lua_spr);
    lua_setglobal(L, "spr");
    lua_pushcfunction(L, _lua_cls);
    lua_setglobal(L, "cls");
    lua_pushcfunction(L, _lua_pal);
    lua_setglobal(L, "pal");
    lua_pushcfunction(L, _lua_print);
    lua_setglobal(L, "print");
    lua_pushcfunction(L, _lua_rectfill);
    lua_setglobal(L, "rectfill");
    lua_pushcfunction(L, _lua_circfill);
    lua_setglobal(L, "circfill");
    lua_pushcfunction(L, _lua_btn);
    lua_setglobal(L, "btn");
}

int main( int argc, char* args[] )
{
    if (argc == 1) {
	printf("Usage: %s <file.lua>\n", args[0]);
	return 1;
    }
    //Start up SDL and create window
    if( !init() )
    {
	printf( "Failed to initialize SDL!\n" );
	return 1;
    }

    L = init_lua(args[1]);
    if ( L == NULL ) {
	printf( "Failed to initialize LUA!\n" );
	return 1;
    }

    fontsheet = loadTexture("pico-8_font_022.png");
    spritesheet = loadTexture("hello_p8_gfx.png");
    if (spritesheet == NULL)
    {
	printf( "Failed to load hello world!\n" );
	return 1;
    }

    registerLuaFunctions();

    SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );
    SDL_RenderClear( gRenderer );

    bool quit = false;
    SDL_Event e;

    while (!quit) {
	while( SDL_PollEvent( &e ) != 0 )
	{
	    //User requests quit
	    if( e.type == SDL_QUIT )
	    {
		quit = true;
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
	_to_lua_call("_update");
	_to_lua_call("_draw");
	SDL_RenderPresent(gRenderer);
	SDL_UpdateWindowSurface( gWindow );
	SDL_Delay( 33 );
    }


    lua_close(L);

    SDL_DestroyTexture(spritesheet->texture);
    sdl_close();
}

void _to_lua_call(char* fn) {
    lua_getglobal(L, fn);
    if (lua_isfunction(L, -1)) {
	if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
	    lua_pop(L, lua_gettop(L));
	} else {
	    puts(lua_tostring(L, lua_gettop(L)));
	}
    } else {
	printf("%s: not a function\n", fn);
    }

}
lua_State* init_lua(char* script) {
    lua_State *state = luaL_newstate();
    luaL_openlibs(state);

    if (luaL_dofile(state, script) == LUA_OK) {
	lua_pop(state, lua_gettop(state));
	return state;
    }
    puts(lua_tostring(state, lua_gettop(state)));
    lua_close(state);
    return NULL;
}

void DrawCircle(SDL_Renderer * renderer, int32_t centreX, int32_t centreY, int32_t radius)
{
    const int32_t diameter = (radius * 2);

    int32_t x = (radius - 1);
    int32_t y = 0;
    int32_t tx = 1;
    int32_t ty = 1;
    int32_t error = (tx - diameter);

    while (x >= y)
    {
	//  Each of the following renders an octant of the circle
	SDL_RenderDrawPoint(renderer, centreX + x, centreY - y);
	SDL_RenderDrawPoint(renderer, centreX + x, centreY + y);
	SDL_RenderDrawPoint(renderer, centreX - x, centreY - y);
	SDL_RenderDrawPoint(renderer, centreX - x, centreY + y);
	SDL_RenderDrawPoint(renderer, centreX + y, centreY - x);
	SDL_RenderDrawPoint(renderer, centreX + y, centreY + x);
	SDL_RenderDrawPoint(renderer, centreX - y, centreY - x);
	SDL_RenderDrawPoint(renderer, centreX - y, centreY + x);

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

