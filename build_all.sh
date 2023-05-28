#!/bin/bash
set -eu
# does not build esp32
for target in PC RAWDRAW ANDROID THREEDS TEST; do
	mkdir -p build-$target
	(cd build-$target; cmake .. -DBACKEND=${target} && make -j)
done
