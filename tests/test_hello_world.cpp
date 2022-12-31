#include "main.cpp"
#include "tests/test_utils.cpp"
#include <cassert>

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_hello_world() {
    uint8_t hello_world = 255;
    uint8_t cart_count = sizeof(carts)/sizeof(GameCart);
    //const char cartname[] = "map_p8";
    const char cartname[] = "hello_world_lua";
    for(uint8_t i=0; i<cart_count; i++) {
        if(strncmp(carts[i].name, cartname, MIN(carts[i].name_len, sizeof(cartname))) == 0) {
            hello_world = i;
            break;
        }
    }
    assert(hello_world != 255);
    cartParser(&carts[hello_world]);
    bool lua_ok = init_lua(carts[hello_world].code, carts[hello_world].code_len);
    assert(lua_ok);
    // _to_lua_call("_update");
    printf("draw\n");
    fflush(stdout);
    if (_lua_fn_exists("_init")) _to_lua_call("_init");
    if (_lua_fn_exists("_update")) _to_lua_call("_update");
    if (_lua_fn_exists("_draw")) _to_lua_call("_draw");
    flip();
    assert(compare_buffer("../tests/data/hello_world.bin", frontbuffer, sizeof(frontbuffer), true));
    lua_close(L);
}

int main() {
    engine_init();
    test_hello_world();
    return 0;
}
