#include "fix32.h"
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdbool.h>
#include "engine.c"
#if defined(SDL_BACKEND)
#include "sdl_backend.c"
#elif defined(PICO_BACKEND)
#include "pico_backend.c"
#elif defined(ESP_BACKEND)
//#include "esp/backend.c"
#endif


int main( int argc, char* args[] )
{
    bool quit = false;

    bootup_time = now();
    if( !init_video() )
    {
        printf( "Failed to initialize video!\n" );
        return 1;
    }

    if( !init_audio() )
    {
        printf( "Failed to initialize audio!\n" );
        return 1;
    }

    engine_init();

    printf("Parsing cart \n");
    // cartParser(examples_map_p8);
    // cartParser(examples_hello_world_lua);
    // cartParser(examples_dice_p8);
    // cartParser(examples_tennis_p8);
    // cartParser(examples_rockets_p8);
    cartParser(examples_celeste_p8);
    // cartParser(examples_benchmark_p8);

    printf("Parsing font \n");
    fontParser(artifacts_font_lua);

    printf("init lua \n");
    bool lua_ok = init_lua(cart.code);
    free(cart.code);
    printf("init done \n");
    if ( !lua_ok ) {
        printf( "Failed to initialize LUA!\n" );
        while (!quit) {
            quit = handle_input();
            delay(100);
        }
        return 1;
    }
    uint32_t init_done = now();
    printf("Parsing and initializing took %dms\n", init_done-bootup_time);

    bool call_update = _lua_fn_exists("_update");
    bool call_draw = _lua_fn_exists("_draw");

    quit = false;
    uint32_t frame_start_time;
    uint32_t update_start_time;
    uint32_t draw_start_time;

    uint32_t frame_end_time;
    uint32_t update_end_time;
    uint32_t draw_end_time;

    const uint8_t target_fps = 30;
    const uint8_t ms_delay = 1000 / target_fps;
    bool skip_next_render = false;

    uint16_t frame_count = 0;
    if (_lua_fn_exists("_init")) _to_lua_call("_init");
    while (!quit) {
        frame_start_time = now();
        gfx_flip();
        quit = handle_input();
        update_start_time = now();
        if (call_update) _to_lua_call("_update");
        update_end_time = now();

        draw_start_time = now();
        if (call_draw && !skip_next_render) _to_lua_call("_draw");
        draw_end_time = now();

        if (draw_end_time - draw_start_time > ms_delay)
            skip_next_render = true;
        else
            skip_next_render = false;

        frame_end_time = now();
        int delta = ms_delay - (frame_end_time - frame_start_time);
        if(delta > 0) delay(delta);

        // lua_gc(L, LUA_GCSTEP, 0);

        // printf("FE %d, FS %d, UE %d, US %d, DE %d, DS %d\n",frame_end_time, frame_start_time, update_end_time, update_start_time, draw_end_time, draw_start_time);
        // printf("Frame: %03d [U: %d, D: %03d], Remaining: %d\n", frame_end_time - frame_start_time, update_end_time - update_start_time, draw_end_time - draw_start_time, delta);
        frame_count++;
    }

    lua_close(L);
    video_close();
}
