#include "src/main.c"
#include "tests/test_utils.c"
#include "tests/test_static_game_data.h"
#include <assert.h>

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_basic_gfx() {
	assert(false);
    cartParser(&cart_test_basic_gfx_p8);
    //bool lua_ok = init_lua(cart_test_basic_gfx_p8.code, cart_test_basic_gfx_p8.code_len);
    //assert(lua_ok);
    if (cart_test_basic_gfx_p8._init_fn != NULL) cart_test_basic_gfx_p8._init_fn();
    if (cart_test_basic_gfx_p8._update_fn != NULL) cart_test_basic_gfx_p8._update_fn();
    if (cart_test_basic_gfx_p8._draw_fn != NULL) cart_test_basic_gfx_p8._draw_fn();
    flip();
    assert(compare_buffer("../tests/data/test_basic_gfx.bin", frontbuffer, sizeof(frontbuffer)));
    //lua_close(L);
}

int main() {
    engine_init();
    test_basic_gfx();
    return 0;
}
