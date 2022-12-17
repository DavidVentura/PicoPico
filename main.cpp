#include "fix32.h"
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdbool.h>
#include "engine.c"
#include "asd.cpp"
#if defined(SDL_BACKEND)
#include "sdl_backend.c"
#elif defined(PICO_BACKEND)
#include "pico_backend.c"
#elif defined(ESP_BACKEND)
//#include "esp/backend.c"
#endif

#define AOT
#undef AOT

#pragma GCC push_options
#pragma GCC optimize ("O0")
int _noop(int arg) {
    return arg;
}
void bench_me() {
    uint32_t bstart = now();
    int res = 0;
    z8::fix32 n = 5;
    for (uint16_t i=0; i<32000; i++) {
        res = z8::fix32::sin(i);
    }
    printf("sin bench took %d; result is %d\n", now()-bstart, res);
}
#pragma GCC pop_options

int main( int argc, char* args[] )
{
    bool quit = false;

    bootup_time = now();
#if (defined(SDL_BACKEND) && true) || defined(ESP_BACKEND) || defined(PICO_BACKEND)
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
    printf("Video and audio initialized fine\n");
#endif

    engine_init();

    printf("Parsing cart \n");
    // cartParser(examples_map_p8);
    // cartParser(examples_hello_world_lua);
    // cartParser(examples_dice_p8);
    // cartParser(examples_tennis_p8);
    // cartParser(examples_rockets_p8);
    cartParser(examples_celeste_p8);
    // cartParser(examples_shelled_p8);
    // cartParser(examples_benchmark_p8);

    printf("Parsing font \n");
    fontParser(artifacts_font_lua);

#ifndef AAAAOT
    // FIXME: something here is necessary in esp
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
#endif

    uint32_t init_done = now();
    printf("Parsing and initializing took %dms\n", init_done-bootup_time);

    // call _init first, in case _update / _draw are defined then
#ifdef AOT
    printf("Initializing with AOT\n");
    uint32_t game_init = now();
    Game::__preinit();
    Game::_init();
    uint32_t game_init_end = now();
#else
    printf("Initializing with LUA\n");
    uint32_t game_init = now();
    if (_lua_fn_exists("_init")) _to_lua_call("_init");
    uint32_t game_init_end = now();
    bool call_update = _lua_fn_exists("_update");
    bool call_draw = _lua_fn_exists("_draw");
#endif
    printf("Executing game init took %dms\n", game_init_end-game_init);

    quit = false;
    uint32_t frame_start_time;
    uint32_t update_start_time;
    uint32_t draw_start_time;

    uint32_t frame_end_time;
    uint32_t update_end_time;
    uint32_t draw_end_time;

    //const uint8_t target_fps = 30;
    const uint8_t target_fps = 30;
    const uint8_t ms_delay = 1000 / target_fps;
    bool skip_next_render = false;

    uint16_t frame_count = 0;
#ifdef AOT
    printf("Size of int is %d\n", sizeof(int));
    printf("Size of sizetest is %d\n", sizeof(SizeTest));
    printf("Size of Union is %d\n", sizeof(Union));
    printf("Size of FWrapper is %d\n", sizeof(FWrapper));
    printf("Size of TValue is %d\n", sizeof(TValue));
#endif

    while (!quit) {
        frame_start_time = now();
        gfx_flip();
        quit = handle_input();
        update_start_time = now();
#ifdef AOT
        Game::_update();
#else
        if (call_update) _to_lua_call("_update");
#endif

        update_end_time = now();

        draw_start_time = now();
#ifdef AOT
        if (!skip_next_render) Game::_draw();
#else
        if (call_draw && !skip_next_render) _to_lua_call("_draw");
#endif
        draw_end_time = now();

        if (draw_end_time - draw_start_time > ms_delay)
            skip_next_render = true;
        else
            skip_next_render = false;

        frame_end_time = now();
        int delta = ms_delay - (frame_end_time - frame_start_time);

        delay(MAX(1, delta));
        // TODO: disable watchdog ? losing 3-6% of cpu time for heavy games..

        // lua_gc(L, LUA_GCSTEP, 0);

        // printf("FE %d, FS %d, UE %d, US %d, DE %d, DS %d\n",frame_end_time, frame_start_time, update_end_time, update_start_time, draw_end_time, draw_start_time);
#if defined(SDL_BACKEND) || defined(ESP_BACKEND) || defined(PICO_BACKEND)
        if(frame_count == 100) {
            printf("Frame: %03d [U: %03d, D: %03d], Remaining: %03d\n", frame_end_time - frame_start_time, update_end_time - update_start_time, draw_end_time - draw_start_time, delta);
            frame_count = 0;
            //printf("Table has %d\n", std::get<SpecialTable*>(Game::balls.data)->fields.size());
        }
#endif
        frame_count++;
    }

    lua_close(L);
    video_close();
}
