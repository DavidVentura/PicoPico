#include "src/main.cpp"
#include "tests/test_utils.cpp"
#include <cassert>

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_hello_world() {
    uint8_t cart_idx = cart_index("hello_world_p8");
    assert(cart_idx != 255);
    cartParser(&carts[cart_idx]);
    bool lua_ok = init_lua(carts[cart_idx].code, carts[cart_idx].code_len);
    assert(lua_ok);
    if (_lua_fn_exists("_init")) _to_lua_call("_init");
    if (_lua_fn_exists("_update")) _to_lua_call("_update");
    if (_lua_fn_exists("_draw")) _to_lua_call("_draw");
    flip();
    assert(compare_buffer("../tests/data/hello_world.bin", frontbuffer, sizeof(frontbuffer)));
    lua_close(L);
}

int main() {
    engine_init();
    test_hello_world();
    return 0;
}
