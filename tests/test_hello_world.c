#include <assert.h>
#include <stdint.h>
#include "src/pico8.h"
#include "src/main.c"
#include "tests/test_utils.c"

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_hello_world() {
    uint8_t cart_idx = cart_index("hello_world_p8");
    assert(cart_idx != 255);
    cartParser(carts[cart_idx]);
   // bool lua_ok = init_lua(carts[cart_idx].code, carts[cart_idx].code_len);
   // assert(lua_ok);
    carts[cart_idx]->_preinit_fn();
    if (carts[cart_idx]->_init_fn)   carts[cart_idx]->_init_fn();
    if (carts[cart_idx]->_update_fn) carts[cart_idx]->_update_fn();
    if (carts[cart_idx]->_draw_fn)   carts[cart_idx]->_draw_fn();
    flip();
    assert(compare_buffer("../tests/data/hello_world.bin", frontbuffer, sizeof(frontbuffer)));
}

int main() {
    engine_init();
    test_hello_world();
    return 0;
}
