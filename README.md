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

https://user-images.githubusercontent.com/3650670/166120990-542c5594-b4a6-487f-b3ae-f32040c0057b.mp4

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

* Normal: 22ms / frame; of which:
    * Lua: ~9ms / frame
    * Copying backbuffer to screen (`uint8_t`): ~12ms / frame

Immediate TODO:

* ~Get basic rendering on the Pico~
    * ~split backends properly~
* Lua dialect
    * how to modify lua?

TODO Later:

* Investigate pushing pixels to display via DMA
