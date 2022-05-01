#!/bin/bash
set -eu
cd /home/david/git/luatest/build
mount /dev/$1 /mnt/pico
cp hello_pico.uf2 /mnt/pico
