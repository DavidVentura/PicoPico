#include "main.cpp"
#define DUMP_VALUES 0

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}

void test_menu() {
    drawMenu();
#if DUMP_VALUES
    FILE *fw = fopen("../tests/data/hud.bin", "wb");
    fwrite(hud_buffer, sizeof(uint8_t), sizeof(hud_buffer), fw);
    fclose(fw);
#endif
    fflush(stdout);

    FILE *f = fopen("../tests/data/hud.bin", "rb");
    fseek(f, 0, SEEK_END);
    uint16_t bytes_read = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t* _golden_hud = (uint8_t*)malloc(bytes_read);
    fread(_golden_hud, sizeof(uint8_t), bytes_read, f);
    fclose(f);

    assert(sizeof(hud_buffer) == bytes_read);

    for(uint16_t i=0; i<bytes_read; i++) {
        assert(hud_buffer[i] == _golden_hud[i]);
    }
    free(_golden_hud);
}

int main() {
    engine_init();
    test_menu();
    return 0;
}
