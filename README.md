# Pico Pico

Project to attempt to create hardware for the [Pico-8](https://www.lexaloffle.com/pico-8.php).

I'd like to eventually get a very basic game running on a [Raspberry Pi Pico](https://www.raspberrypi.com/documentation/microcontrollers/raspberry-pi-pico.html)

Be aware, the code will be terrible, this is a project to learn:

* C
* SDL
* Embedded
* CMake
* Lua
    * And how to adapt / modify languages

## Demo

In emulator (SDL backed)

![Hello world](artifacts/hello_world.gif?raw=1)

In Raspberry pi Pico


https://user-images.githubusercontent.com/3650670/166146124-06b8b223-27b1-47ac-931f-67ba8b523d9e.mp4



# Basic analysis / feasibility:

Memory requirements:

* Spritesheet, at 128x128 in size = 16KB 
* Fontsheet, at 128x128 in size = 16KB
* Map, at 32x128 = 4 KB
* Flags, at 2x128 = 256B
* Sound effects, 64x84 = 5376B (~5KB)
    * Sound itself should come from flash
* Music patterns, 64x6 = 384B
    * Music itself should come from flash
* Display buffer (optional, if double-buffered), ~128x128 = 16KB~, 160x80x2=25KB
    * 160x80 = the only screen I have available, otherwise it'd be slightly larger
    * x2 => each pixel needs "2 bytes" (currently, set for RGB565), it _might_ be possible, depending on driver to use 1.5bpp (12 bits) 
* Game memory = 64KB
    * Lua = ???KB
    * how to measure?

~145KB, should have plenty of space for things going wrong. However, the biggest unknown is lua overhead.  
Both Spritesheet (16KB), Fontsheet (16KB) and Map (4KB) can be squeezed to half, as they need a nibble per pixel, instead of a byte.  
Not sure how much CPU it'd take to have every single render to the backbuffer expand the pixels back bytes.

# Current performance

Running `hello_world.lua`:

* Normal: 23ms / frame; of which:
    * Lua: ~9ms / frame
    * Copying backbuffer to screen (`uint8_t`): ~12ms / frame

* Display on 2nd core: 10.5ms / frame; of which:
    * Lua: ~9ms / frame
    * ~Copying backbuffer to screen~ happens "for free" in the other core

* Multicore + overclock to 260MHz: 5ms/frame

# TODO

Immediate:

* ~Get basic rendering on the Pico~
    * ~split backends properly~
* ~Read code from p8 file instead of having split files~
* ~Implement map~
* Implement camera
* Lua dialect
    * how to modify lua?
* Unify the build systems (Make for pc / CMake for pico)

Later:

* Investigate pushing pixels to display via DMA

# Hardware

Build something like the [PicoSystem](https://shop.pimoroni.com/products/picosystem?variant=32369546985555) ?

# Development (without a second Pico running OpenOCD)

Add this block to a udev rule (adjust the paths to point to this repo)
```
SUBSYSTEM=="block", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003", ACTION=="add", SYMLINK+="rp2040upl%n"
SUBSYSTEM=="block", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003", ACTION=="add", RUN+="/home/david/git/luatest/udev_build.sh rp2040upl%n"
```

Then having an open minicom shell 
```
sudo minicom -b 115200 -D /dev/ttyACM1
```

you can press `r` on it to reboot into mass-storage mode; which will trigger the udev rules after a second or so.

# Useful links

* [Easy intro to Embedding lua](https://lucasklassmann.com/blog/2019-02-02-how-to-embeddeding-lua-in-c/#example-of-error-handling)
* [Lua 5.2 Manual](https://www.lua.org/manual/5.2/manual.html)
* [Storing data in flash](https://kevinboone.me/picoflash.html?i=1)
* [Udev rule to copy build automatically](https://forums.raspberrypi.com/viewtopic.php?t=333160)
* [Getting started on basic Pico8 Gamedev](https://lukemerrett.com/getting-started-with-pico-8/)
