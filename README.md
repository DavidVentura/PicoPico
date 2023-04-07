# Pico Pico

Project to attempt to create hardware for the [Pico-8](https://www.lexaloffle.com/pico-8.php).

I'd like to eventually get full game running on a ~[Raspberry Pi Pico](https://www.raspberrypi.com/documentation/microcontrollers/raspberry-pi-pico.html)~ [ESP32](https://www.adafruit.com/product/3979)

Be aware, the code will be terrible, this is a project to learn:

* C
* SDL
* Embedded
* CMake
* Lua
    * And how to adapt / modify languages
* JIT-ting ??


This project uses [z8lua](https://github.com/DavidVentura/z8lua) to implement Pico8's Lua dialect; I've whacked the original repo to make it build 
with the Pico as a target, it was all implicit casting, which I hopefully got right.

This project also gets some "inspiration" from [tac08](https://github.com/0xcafed00d/tac08/tree/master/src) - ideas for things I don't know how to solve, and the "firmware.lua" file 
for basic implementations.

## Demo

### In emulator (SDL backed)

https://user-images.githubusercontent.com/3650670/209883786-df8e24eb-6469-4147-87f5-97d2407c08f9.mp4


### Celeste in ESP32

https://user-images.githubusercontent.com/3650670/168416377-bf238d62-6be6-4b70-a04c-2d60ab57a269.mp4

### In Raspberry pi Pico (port abandoned, not enough RAM)

https://user-images.githubusercontent.com/3650670/166146124-06b8b223-27b1-47ac-931f-67ba8b523d9e.mp4

## Hardware

### BOM

* 1x THT Power switch [TME](https://www.tme.eu/nl/en/details/os102011ma1qn1/slide-switches/c-k/) [PDF](https://www.tme.eu/Document/b47a7178f6dd5c46f052ff087f56764e/OS_series_DTE.pdf)
* 8x SMD button [TME](https://www.tme.eu/nl/en/details/evqq2202w/microswitches-tact/panasonic/) [PDF](https://www.tme.eu/Document/7162409d248aba412c7389d402f46025/EVQQ2series.pdf)
* 1x 10k horixontal potentiometer [TME](https://www.tme.eu/nl/en/details/r0141-2-10k/single-turn-tht-trimmers/sr-passives/) [PDF](https://www.tme.eu/Document/48eb4fb11c5e0c9b1cd467745dfbcb98/R0141-2.pdf)
* 8x SMD 10k resistor
* MAX98357 I2S audio amplifier [ALI](https://www.aliexpress.com/item/1005004280540810.html?spm=a2g0o.order_list.order_list_main.11.5b1c18020Z9uMr)
* ESP32 "Wrover" with 4MB PSRAM [Amazon](https://www.amazon.de/gp/product/B07RWHK65X/ref=ppx_yo_dt_b_asin_title_o08_s00?ie=UTF8&psc=1)
* 1.77" SPI ST7735 128x160 Display (128x128 used for game, 16px for UI, 16px padding) [ALI](https://www.aliexpress.com/item/1005003797803015.html?spm=a2g0o.order_list.order_list_main.23.5b1c18020Z9uMr)

# Goals

1. ✅ Make `hello_world` work without regressions )).
    * ~All letters are white~ (lazy palette evaluation was missing a palette indirection (screen vs draw))
1. ✅ Make `rockets` fully playable (without music // complete SFX).
    * ~Points go up too fast~ (`time()` was returning millis)
1. ✅ Create some basic automated testing.
    * Tests are at `tests/`, they run one (or a few) frames and get output.
    * Need to integrate better into the project; exclusive `ifdef` for header selection
1. Make `celeste` fully playable (without music // complete SFX)
    * ~Clouds suddenly appear~ (bad rectfill types, took uint instead of int)
    * Sometimes 2 celestes appear?? mostly on level crossings
1. Make `valdi` fully playable (without music // complete SFX)
    * ~Renders offset when looking to the left~ (wasn't calculating the sprite width accordingly in `spr()`)
    * `fillp` not implemented (background)
    * ~Super slow after a few resets?~ (`gfx_line` was missing a bounds check, overwriting the delay between frames)
1. Make `awake` fully playable (without music // complete SFX)
    * Colors are super glitched, level2 is also glitched


# Basic analysis / feasibility:

Memory requirements:

* Spritesheet, at 128x128 in size = 16KB 
    * Can move to flash
* Fontsheet, at 128x128 in size = 16KB
    * Can move to flash
* Map, at 64x128 = 8 KB
    * Can move to flash
* Flags, at 2x128 = 256B
    * Can move to flash
* Sound effects, 64x84 = 5376B (~5KB)
    * Can move to flash
* Music patterns, 64x6 = 384B
    * Can move to flash
* Front buffer 128x128/2 = 8KB (x/y position -> palette)
* Back buffer 128x128x2 = 32KB (x/y position -> color, at 16bpp)
* HUD buffer 16x128x2 = 4KB
    * Can squeeze to 8x64x2 = 1KB, or even 7 sprites (896b)
* Dedicated "Game memory" = 32KB

Totals ~130KB (of which 76KB for screen buffers and game memory have to stay).

And **most importantly** 2MB for game RAM (Lua memory). This varies based on each game, but on the PICO the 264KB ran out pretty fast. There's [this thing](https://github.com/yocto-8/yocto-8/blob/main/doc/extmem.md) to use _very slow, very cursed_ external RAM. _Some_ games 

# Performance

In RPI Pico:

Running `hello_world.lua`:

* Normal: 13ms / frame; of which:
    * Lua: ~9ms / frame
    * Copying backbuffer to screen (`uint8_t`): ~4ms / frame

* Display on 2nd core: 7.5ms / frame; of which:
    * Lua: ~7ms / frame
    * ~Copying backbuffer to screen~ happens "for free" in the other core

* Multicore + overclock to 260MHz: 3.5ms/frame

In ESP32:

Celeste takes about 9ms / frame (rendering happens on the second core), including SFX

# TODO

Immediate:

* ~Get basic rendering on the Pico~
    * ~split backends properly~
* ~Read code from p8 file instead of having split files~
* ~Implement map~
* ~Implement camera~
* ~Lua dialect~ (using z8lua)
* ~Unify the build systems (Make for pc / CMake for pico)~
* ~Pre-encode the palette colors as a RGB565 `uint16_t`; makes no sense to shift them on _every pixel write_~
* ~SFX~
* ~Measure and output the correct number of samples out of the audio buffer, currently it's a (badly) guessed number.~
* ~Get reasonable audio quality out of SFX~
* Deal with warnings when building for ESP
    * ~Figure out why they don't show up when building with SDL backend~
* ~Move hardcoded pin for ESP32 to sdkconfig~
    * Extract current values for docs WIP
* Implement more complete SFX
* Generate board captures automatically
* ~Add support for short-hand print ('?"x"' == print("x"))~
* Implement fillp https://pico-8.fandom.com/wiki/Fillp
* Lua error: bad argument #1 to 'split' (string expected, got nil)
* Lua error: bad argument #1 to 'btn' (number expected, got nil)
    * z8lua considers literal circle (🅾️) to be `nil` but not ❎

Later:

* ~Clock rate on SPI?~ set to 62.5MHz; not sure if it can go higher
* Implement flash
    * cartdata command could use it
    * carts could be stored in flash instead of static data
* Investigate pushing pixels to display via DMA
    * worth it? the second core is idle anyway
* Music
* Look at optimizing lua bytecode for "fast function calls", for "standard library"
* Use headers instead of stupid ifdefs
* Enable `-Wconversion`
* Console-based UI game
    * [Virtual keyboard](https://www.lexaloffle.com/bbs/?tid=41855) [(original, no lowercase)](https://www.lexaloffle.com/bbs/?tid=4076)
    * Wifi menu
    * Cart explorer?

# Other stuff

Resources are parsed from plaintext into a header by the `to_c.py` script, this also covers converting source code to byte-code. 
Having byte-code compiled in a pre-processing stage makes parsing faster (112ms -> 18ms for a large cart), uses less memory (bytecode 
stays in flash, not necessary to load to RAM) and enables future bytecode-level optimization

## Sound

I yoinked [zepto8's synth](https://github.com/samhocevar/zepto8/blob/master/src/synth.cpp) and converted it to `fix32`; an example SFX went 
from ~25ms to ~2ms on the ESP32.

# API Support

## Graphics

|    Function   | Supported |                     Notes |
|---------------|-----------|---------------------------|
|camera         |✅         |                           |
|circ           |✅         |                           |
|circfill       |✅         |                           |
|oval           |✅         |                           |
|ovalfill       |✅         |                           |
|clip           |✅         |                           |
|cls            |✅         |                           |
|color          |✅         |                           |
|cursor         |❌         |                           |
|fget           |✅         |                           |
|fillp          |❌         |                           |
|fset           |❌         |                           |
|line           |✅         |                           |
|pal            |⚠️          |Only "draw palette" is implemented|
|palt           |✅         |                           |
|pget           |✅         |                           |
|print          |⚠️          |Does not automatically scroll|
|pset           |✅         |                           |
|rect           |✅         |                           |
|rectfill       |✅         |                           |
|sget           |✅         |                           |
|spr            |✅         |                           |
|sset           |✅         |                           |
|sspr           |⚠️          |                           |
|tline          |❌         |                           |

## Tables

All implemented (z8lua)

## Input

`btn` implemented

## Sound

|    Function   | Supported |                     Notes |
|---------------|-----------|---------------------------|
|sfx            |⚠️          | Offset is not implemented |
|music          |❌         |                           |

## Map

All implemented

## Memory

Not implemented

## Math

All implemented (z8lua)

## Cartridge data

|    Function   | Supported |                     Notes |
|---------------|-----------|---------------------------|
|cartdata       |⚠️          | Not persistent            |
|dget           |⚠️          | Not persistent            |
|dset           |⚠️          | Not persistent            |
|cstore         |❌         |                           |
|reload         |❌         |                           |
cartdata/dget/dset are _technically_ implemented, there's no persistence layer though.

cstore/reload are not implemented.

## Coroutines

Implemented by aliasing (z8lua)

## Strings 

Implemented (z8lua)

## Values and objects

Implemented (z8lua)

# Hardware

Build something like the [PicoSystem](https://shop.pimoroni.com/products/picosystem?variant=32369546985555) ?

# Development setup

```bash
sudo apt install cmake g++ libsdl2-dev
git submodule update --init
mkdir pc_pico && cd pc_pico
cmake -DBACKEND=PC ..
```

# Development on RP2040 (without a second Pico running OpenOCD)

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

# Tests

There's a CMake backend (TEST) that you can use with `cmake -DBACKEND=TEST`; in that backend, the command `make test` will run some tests.

Some of the tests are for the internal APIs, and are written in C. Generally though, most tests should be written as p8 cartridges and placed in `tests/regression/*.p8`.

Internal API tests usually compare the output with some expected, known-good frontbuffer values (a "screenshot").
Whenever these need to change, the specific test can be re-run with the environment variable `OVERWRITE_TEST_BUF` set to any value.
This will overwrite `tests/data/buf_*.bin`. To look at these buffers, you can use the command `bin_to_png`.

```
> make test
Running tests...
Test project /Users/tati/git/PicoPico/tests_build
    Start 1: test_hello_world
1/5 Test #1: test_hello_world .................   Passed    0.03 sec
    Start 2: test_hud
2/5 Test #2: test_hud .........................   Passed    0.03 sec
    Start 3: test_menu
3/5 Test #3: test_menu ........................   Passed    0.03 sec
    Start 4: test_primitives
4/5 Test #4: test_primitives ..................   Passed    0.03 sec
    Start 5: test_regression
5/5 Test #5: test_regression ..................   Passed    0.03 sec

100% tests passed, 0 tests failed out of 5

Total Test time (real) =   0.16 sec
```

```
> ./test_regression
Testing regression_api_p8
  test_map_no_args                        [ OK]
  test_print_p8scii_color                 [ OK]

Testing regression_asan_p8
  test_sspr_same_size_is_maintained       [ OK]
  test_circ_top_left_edge                 [ OK]

Testing regression_other_p8
  test_nothing                            [ OK]
```

# Useful links

* [Easy intro to Embedding lua](https://lucasklassmann.com/blog/2019-02-02-how-to-embeddeding-lua-in-c/#example-of-error-handling)
* [Lua 5.2 Manual](https://www.lua.org/manual/5.2/manual.html)
* [Storing data in flash](https://kevinboone.me/picoflash.html?i=1)
* [Udev rule to copy build automatically](https://forums.raspberrypi.com/viewtopic.php?t=333160)
* [Getting started on basic Pico8 Gamedev](https://lukemerrett.com/getting-started-with-pico-8/)
* [GameTiger, another Pico-based console](https://github.com/codetiger/GameTiger-Console)
* [Espressif docs](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/linux-macos-setup.html)
* [Importing custom 3D models into kicad](https://happyrobotlabs.com/posts/tutorials/tutorial-3d-kicad-parts-using-openscad-and-wings3d/)
