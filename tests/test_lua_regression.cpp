#include "main.cpp"
#include "tests/regression_static_game_data.h"
#include "tests/test_utils.cpp"
#include <cassert>

bool handle_input() {
	return false;
}

bool is_test_func(lua_State* _L, const char* name, int idx) {
	if (!lua_isfunction(_L, idx)) {
		return false;
	}
	return strncmp(name, "test_", strlen("test_")) == 0;
}

int test_regression(GameCart c) {
	cartParser(&c);
	bool lua_ok = init_lua(c.code, c.code_len);
	assert(lua_ok);
	const char** globals = iterate_globals(L, is_test_func);

	uint16_t i = 0;
	uint16_t failed_tests = 0;
	while(globals[i] != 0) {
			printf("  %-40s", globals[i]);
			fflush(stdout);

			lua_getglobal(L, globals[i]);
			uint8_t res_count = lua_gettop(L);
			if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
					printf("[ OK]\n");
			} else {
					const char* err = lua_tostring(L, res_count);
					failed_tests++;
					printf("[BAD]\n");
					printf("%s\n\n", err);
			}
			lua_pop(L, res_count);
			i++;
	}
	free(globals);
	lua_close(L);
	return failed_tests;
}

int main() {
	uint16_t total_failed_count = 0;
	for (uint16_t i = 0; i<sizeof(regressioncarts)/sizeof(GameCart); i++) {
		printf("\nTesting %s\n", regressioncarts[i].name);
		uint16_t failed_count = test_regression(regressioncarts[i]);
		total_failed_count += failed_count;
		if (failed_count > 0) {
			printf("%d tests failed\n", failed_count);
		}
	}
	if (total_failed_count > 0) {
		return 1;
	}
	return 0;
}
