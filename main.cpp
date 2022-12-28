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


int16_t drawMenu() {
    bool quit = handle_input();
    uint8_t highlighted = 0;
    uint8_t cartCount = sizeof(carts)/sizeof(GameCart);
    bool old_down = false;
    bool old_up = false;
    delay(10);
    while(!quit) {
        for(uint8_t i=0; i<cartCount; i++) {
            _print(carts[i].name, carts[i].name_len, 10, 10+i*7, highlighted == i ? 9 : 7);
        }

        if (buttons[3]) { // DOWN
            if (!old_down) {
                old_down = true;
                highlighted = (highlighted + 1) % cartCount;
                printf("Down\n");
            }
        } else {
            old_down = false;
        }

        if (buttons[2]) { // UP
            if (!old_up) {
                old_up = true;
                highlighted = highlighted == 0 ? cartCount - 1 : highlighted - 1;
                printf("up\n");
            }
        } else {
            old_up = false;
        }

        if (buttons[4] || buttons[5]) {
            return highlighted;
        }

        gfx_flip();
        quit = handle_input();
        delay(30);
    }
    return -1;
}

int main( int argc, char* args[] )
{
    bool quit = false;

    uint32_t bootup_time = now();
    if( !init_video() )
    {
        printf( "Failed to initialize video!\n" );
        return 1;
    }
    uint32_t init_done = now();
    printf("initializing video took %dms\n", init_done-bootup_time);

    if( !init_audio() )
    {
        printf( "Failed to initialize audio!\n" );
        return 1;
    }

    engine_init();
    init_done = now();
    printf("initializing engine took %dms\n", init_done-bootup_time);
    bootup_time = now();
    printf("Parsing font \n");
    rawSpriteParser(&fontsheet, artifacts_font_lua);
    printf("Parsing HUD \n");
    rawSpriteParser(&hud_sprites, artifacts_hud_p8);

    init_done = now();
    printf("initializing took %dms\n", init_done-bootup_time);


    _draw_hud_sprite(&hud_sprites, 0, 0, 18*13, 0);
    //_draw_hud_sprite(&hud_sprites, 1, 0, 18*1, 0);
    //_draw_hud_sprite(&hud_sprites, 2, 0, 18*2, 0);
    //_draw_hud_sprite(&hud_sprites, 3, 0, 18*3, 0);
    //_draw_hud_sprite(&hud_sprites, 0, 1, 18*4, 0);
    //_draw_hud_sprite(&hud_sprites, 1, 1, 18*5, 0);
    //_draw_hud_sprite(&hud_sprites, 2, 1, 18*6, 0);
    _draw_hud_sprite(&hud_sprites, 3, 1, 18*12, 0);

    _draw_hud_sprite(&fontsheet, 01, 3, 110, 3);
    _draw_hud_sprite(&fontsheet, 03, 3, 118, 3);
    _draw_hud_sprite(&fontsheet, 10, 3, 126, 3); // :, 6 wide, centered at 128 (which is 2x, so 64)
    _draw_hud_sprite(&fontsheet, 03, 3, 134, 3);
    _draw_hud_sprite(&fontsheet, 07, 3, 142, 3);
    int16_t game = drawMenu();
    if (game < 0) {
        video_close();
        return 1;
    }
    gfx_cls(original_palette[0]);
    memset(buttons, 0, sizeof(buttons));
    delay(10);

    bootup_time = now();
    printf("Parsing cart %s\n", carts[game].name);
    cartParser(&carts[game]);


    printf("init lua \n");
    bool lua_ok = init_lua(cart.code, carts[game].code_len);
    free(cart.code);
    printf("init done \n");
    if ( !lua_ok ) {
        printf( "Failed to initialize LUA!\n" );
	return 1;
        while (!quit) {
            quit = handle_input();
            delay(100);
        }
        return 1;
    }
    init_done = now();
    printf("Parsing took %dms\n", init_done-bootup_time);

    // call _init first, in case _update / _draw are defined then
    if (_lua_fn_exists("_init")) _to_lua_call("_init");

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
        if (frame_count % 300) {
            draw_hud();
        }
    }

    lua_close(L);
    video_close();
}
