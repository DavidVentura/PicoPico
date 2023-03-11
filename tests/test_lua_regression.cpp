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

int test_regression() {
	bool lua_ok = init_lua(cart_tests_regression_regression_tests_p8.code, cart_tests_regression_regression_tests_p8.code_len);
	assert(lua_ok);
	const char** globals = iterate_globals(L, is_test_func);

	uint16_t i = 0;
	uint8_t err = 0;
	uint16_t failed_tests = 0;
	while(globals[i] != 0) {
		printf("Testing: %s..\t", globals[i]);
		fflush(stdout);
		err = _to_lua_call(globals[i]);
		if (err) {
			failed_tests++;
			printf("BAD\n");
		} else {
			printf("OK\n");
		}
		i++;
	}
	free(globals);
	lua_close(L);
	return failed_tests;
}

int main() {
	uint16_t failed_count = test_regression();
	if (failed_count > 0) {
		printf("%d tests failed\n", failed_count);
		return 1;
	}
	return 0;
}
