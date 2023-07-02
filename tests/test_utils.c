#include <assert.h>

bool compare_buffer(const char* in_file, uint8_t* buf, uint16_t buf_len) {
    if(getenv("OVERWRITE_TEST_BUF")){
        FILE *fw = fopen(in_file, "wb");
        fwrite(buf, sizeof(uint8_t), buf_len, fw);
        fclose(fw);
        printf("[WARN] Overriding values for %s\n", in_file);
    }

    FILE *f = fopen(in_file, "rb");
    fseek(f, 0, SEEK_END);
    uint16_t bytes_read = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t* golden_data = (uint8_t*)malloc(bytes_read);
    fread(golden_data, sizeof(uint8_t), bytes_read, f);
    fclose(f);

    fflush(stdout);
    assert(buf_len == bytes_read);

    for(uint16_t i=0; i<bytes_read; i++) {
        if(buf[i] != golden_data[i]) {
            printf("Set the env var OVERWRITE_TEST_BUF to overwrite\n");
            return false;
        }
    }
    free(golden_data);
    return true;
}

uint8_t cart_index(const char* cartname) {
    uint8_t cart_count = sizeof(carts)/sizeof(GameCart*);
    for(uint8_t i=0; i<cart_count; i++) {
		printf("%s\n", carts[i]->name);
        if(strncmp(carts[i]->name, cartname, MIN(carts[i]->name_len, sizeof(cartname))) == 0) {
            return i;
        }
    }
    return 255;
}
