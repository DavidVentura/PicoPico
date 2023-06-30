#include <stdio.h>
#include "cart_console_interface.h"

sdk_t __attribute__((section (".sdk_var_section"))) sdk;

int myplusone(uint8_t in) {
	return in + 1;
}

int main() {
	sdk.plus_one = myplusone;
	printf("sdk is at %p\n", &sdk);
	printf("sdk->cls is at %p\n", sdk.plus_one);
	int res = sdk.plus_one(99);
	printf("Got back %d\n", res);
	return 0;
}
