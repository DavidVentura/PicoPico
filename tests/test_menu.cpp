#include "main.cpp"
#include "tests/test_utils.cpp"
#include <cassert>

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_hello_world() {
    drawMenu();
    assert(compare_buffer("../tests/data/menu.bin", frontbuffer, sizeof(frontbuffer), true));
}

int main() {
    engine_init();
    test_hello_world();
    return 0;
}
