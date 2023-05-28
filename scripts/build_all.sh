#!/bin/bash
set -eu
# No dependencies for: ESP32 PC, RAWDRAW, ANDROID 
for target in RAWDRAW THREEDS ANDROID TEST; do
	docker run --user $(id -u):$(id -g) -v "$PWD:/src" davidv27/picopico-builder:0.0.5 /bin/bash -c "set -x; rm -rf build-$target; mkdir -p build-$target; cd build-$target; cmake .. -DANDROIDSDK=/android_sdk -DBACKEND=$target && make -j"
done
