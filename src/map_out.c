#include "pico8.h"
TValue_t y = T_NULL;
TValue_t x = T_NULL;
void __preinit();
void _draw();
void _update();

void _update() {

  if (_bool(CALL((btn), 1, ((TValue_t[1]){TNUM16(0)})))) {
    _set(&x, _sub(x, TNUM16(1))); // unknown type
  }

  if (_bool(CALL((btn), 1, ((TValue_t[1]){TNUM16(1)})))) {
    _set(&x, _add(x, TNUM16(1))); // unknown type
  }

  if (_bool(CALL((btn), 1, ((TValue_t[1]){TNUM16(2)})))) {
    _set(&y, _sub(y, TNUM16(1))); // unknown type
  }

  if (_bool(CALL((btn), 1, ((TValue_t[1]){TNUM16(3)})))) {
    _set(&y, _add(y, TNUM16(1))); // unknown type
  }

  if (_bool(CALL((btn), 1, ((TValue_t[1]){TNUM16(5)})))) {
    _set(&y, _add(y, TNUM16(1))); // unknown type
  }

  if (_bool(CALL((btn), 1, ((TValue_t[1]){TNUM16(4)})))) {
    _set(&x, _add(x, TNUM16(1))); // unknown type
  }
}

void _draw() {
  CALL((cls), 0, NULL);
  CALL((map), 6, ((TValue_t[6]){TNUM16(0), TNUM16(0), TNUM16(0), TNUM16(0), TNUM16(16), TNUM16(8)}));
  CALL((map), 6, ((TValue_t[6]){TNUM16(0), TNUM16(0), TNUM16(0), TNUM16(64), TNUM16(16), TNUM16(8)}));
  CALL((spr), 3, ((TValue_t[3]){TNUM16(2), x, y}));
}

void __init() {
}
void __preinit() {
  _set(&x, TNUM16(64));
  _set(&y, TNUM16(64));
}
