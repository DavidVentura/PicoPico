#include <cassert>

bool compare_buffer(const char* in_file, uint8_t* buf, uint16_t buf_len, bool dump_values) {
    if (dump_values) {
        FILE *fw = fopen(in_file, "w");
        fwrite(buf, sizeof(uint8_t), buf_len, fw);
        fclose(fw);
        printf("[WARN] Overriding values for %s\n", in_file);
    }

    FILE *f = fopen(in_file, "r");
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
            return false;
        }
    }
    free(golden_data);
    return true;
}
