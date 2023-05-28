#include "src/main.cpp"
#include "tests/test_utils.cpp"
#include <cassert>

bool handle_input() {
    static uint8_t queryCounter = 0;
    static uint8_t downCounter = 0;
    buttons_frame[3] = 0;
    if (downCounter == 0) {
	    // hold down for 1 frame
	    buttons_frame[3] = 1;
	    downCounter = 1;
    }
    return queryCounter++ == 5; // wants to quit
}

void test_menu() {
    drawMenu();
    assert(compare_buffer("../tests/data/menu.bin", frontbuffer, sizeof(frontbuffer)));
}

int main() {
    engine_init();
    test_menu();
    return 0;
}
