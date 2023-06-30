#include <stdint.h>
typedef int (*plus_oner_t)(uint8_t);
typedef struct sdk_s {
	plus_oner_t plus_one;
} sdk_t;

