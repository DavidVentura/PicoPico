#include <cassert>

bool compare_buffer(const char* in_file, uint8_t* buf, uint16_t buf_len, bool dump_values) {
    if (dump_values) {
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
            return false;
        }
    }
    free(golden_data);
    return true;
}

const char** iterate_globals(lua_State* _L, bool (filter)(lua_State*, const char*, int) ) {
	uint8_t found = 0;
	const char** global_funcs = (const char**)malloc(sizeof(char*) * 255);
	lua_pushglobaltable(L);       // Get global table
	lua_pushnil(L);               // put a nil key on stack
	while (lua_next(L,-2) != 0) { // key(-1) is replaced by the next key(-1) in table(-2)
		const char* name = lua_tostring(L,-2);  // Get key(-2) name
		if (filter(L, name, -1)) {
			global_funcs[found] = name;
			found++;
		}
		lua_pop(L,1);               // remove value(-1), now key on top at(-1)
		if (found == 254) {
				assert(0); // can't handle it
		}
	}
	lua_pop(L,1);                 // remove global table(-1)
	global_funcs[found] = 0;
	return global_funcs;
}
