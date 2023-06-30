#include "src/main.c"
#include "tests/test_utils.c"
#include <assert.h>

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_menu() {
    drawMenu();
    assert(compare_buffer("../tests/data/hud.bin", hud_buffer, sizeof(hud_buffer)));
}

int main() {
    engine_init();
    test_menu();
    return 0;
}
