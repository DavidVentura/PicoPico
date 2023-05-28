#include "src/main.cpp"
#include "tests/test_utils.cpp"
#include "tests/test_static_game_data.h"
#include <cassert>

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_basic_gfx() {
    cartParser(&cart_test_basic_gfx_p8);
    bool lua_ok = init_lua(cart_test_basic_gfx_p8.code, cart_test_basic_gfx_p8.code_len);
    assert(lua_ok);
    if (_lua_fn_exists("_init")) _to_lua_call("_init");
    if (_lua_fn_exists("_update")) _to_lua_call("_update");
    if (_lua_fn_exists("_draw")) _to_lua_call("_draw");
    flip();
    assert(compare_buffer("../tests/data/test_basic_gfx.bin", frontbuffer, sizeof(frontbuffer)));
    lua_close(L);
}

int main() {
    engine_init();
    test_basic_gfx();
    return 0;
}
