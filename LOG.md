# Journal

Partly live-ramblings and partly back-filled from git log

### Wed Apr 27

I saw some news about Raspberry Pico and Pico8 on the same day and got the idea to implement Pico8-on-Pico.

First thoughts:

* Should run _some_ games without modifying the carts
* Should run on PC for easier debugging of "console" logic

To run on PC, I looked around a bit and decided to go with SDL; started following [Lazy Foo's tutorials](https://lazyfoo.net/tutorials/SDL/index.php)

Got a first basic screen with textures loading on SDL, and some colored pixels rendering on the Pico. This verison used CMake for the Pico (straight off the tutorial) and Make for PC

### Sat Apr 30

"Hello world" demo was running **really** slow, mostly because it was sending 1 byte at a time; replace ST7735 call to instead send the entire buffer directly.

Added timing on frames to "benchmark" some approaches a bit (ms resolution).

### Sun May 1

Got really annoyed at the dev cycle; to get a build onto the pico I had to:
* unplug the pico
* press bootsel while re-plugging the pico
* mount the pico
* drag & drop the new files

All of this.. to see my code crash slightly farther down the line; so I added into the input polling function, a mechanism to reset into usb mode when pressing "r" over usb-uart.. at least I could skip the "unplug, press, replug" part.  
Afterwards I also added a udev script (committed to the repo) that automatically mounts & copies the latest build over. This means that pressing "r" over UART will end up with a new build in the pico in ~8s. Need to look at OpenOCD.

Pushing a screenful of pixels takes about ~12ms with the current settings; so with logic taking ~9ms on "Hello world" demo, there's a hard limit of ~40FPS.
This sucks; games more complicated than "hello world" will spend more time on their game logic, dropping FPS down further.

Moved rendering to second core. This was _so easy_, maybe 4 lines of code; and it improved FPS dramatically (obviously -- now the rendering doesn't take time from the game cycle).
However.. the screen flashed like a maniac, having games call `cls()` while the buffer is being pushed to the screen will cause this )).

Split the screen buffer into front/backbuffer so the game can muck with the front buffer all it wants, and the copy of front->back buffers happens only on `flip()`.

Inlined `put_pixel` for an easy ~0.5ms faster frame

### Mon May 2

Add a "stdlib" to lua -- implementing pico8 special builtins

Get PC target building on CMake.

### Tue May 3


Integrate [z8lua](https://github.com/samhocevar/z8lua) into the build. It took me HOURS, as there was a lot of implicit casting that works on 64bit platforms, but not when targetting the pico.

Then spend many more hours debugging why the new Lua would work on PC and crash on Pico. Turns out `luaL_checkversion` returns errors, and the error was quite clear:

```
bad conversion number->int; must recompile Lua with proper settings
```

I'd forgotten some type casts -- I ended up changing the types for `LUA_INT32` and by extension `LUA_UNSIGNED` (this one is defined based on `LUA_INT32`). This made the interpreter work on the Pico.

This took many experiments; so after adding error handling on Lua init; I added some code to trigger "wait for re-flash" if Lua failed to init.

Another huge pain in the ass: I had a silly mistake in the `stdlib.lua` file.. and wasn't checking for errors when executing it. So the games could not access anything defined in it. Added error handling.

Still don't know how to use CMake, so added an `OPTION` to selectively build for Pico or PC. It 'works' but I need to clean the CMakeCache.txt file every time I switch.

Ran out of memory when loading "larger" games. My calculations must be off - I thought I had more space to spare. Start thinking about how to compress static data.

Remove hardcoded screen dimensions; this was the cause of ENDLESS bugs

### Wed May 4

Implement a simple RLE algorithm

|file			| initial size	| encoded	|
|-----------------------|---------------|---------------|
|artifacts/font.lua	| 16513		|4898		|
|examples/map.p8	| 3662		|807		|
|examples/btnp.p8	| 374		|375		|
|examples/movement.lua	| 287		|288		|
|examples/tennis.p8	| 21006		|3700		|
|examples/dice.p8	| 25610		|7924		|
|examples/hello\_world	| 4220		|1115		|
|total			| 68010 	|19107 (~0.3x)	|

Where you see size increase by 1 is because I always add a NULL byte at the end of the content, for easier parsing.

The algorithm is fairly simple, and strongly abuses one constraint in the input: every byte must be valid ASCII (ie: <128). This means that every byte in the input **must** have its highest bit unset.

With this in mind, the algorithm is:

* Read 1 byte
    * If highest bit is set: `count = next byte`
    * If highest bit is unset: `count = 1`
* Place the read char `count` times in output buffer
* Repeat

However! the code has to special-case the value where the repetition count is `10` (that is `\n`); as this would confuse the "read file based on newlines" algorithm. The "special" value `0xFF` is used in this case.


Realized that copying the backbuffer to screen takes 11.5ms because the SPI clock frequency is set to 30MHz. Setting it to 62.5MHz (number from `GameTiger` repo) makes the transfer take ~4ms.

# Thu May 5

I ran out of memory again, when trying to run "Rockets!". After a lot of poking around with the linker map, I realized that the static assets (cart data, font, stdlib) weren't declared as `const`! Making them `const` released ~50KB.  
I also looked for some easy memory and noticed I was allocating a static 32KB buffer for the code _text_ which is not used after Lua initializes the VM; so I made that dynamic memory and freed it after using it. Easy 32KB.
I'll probably release another 10KB later.

Struggling with the performance of `Rockets!`, seems that manually drawing rotated sprites, pixel by pixel, is _slow_. Not sure why, these ~400 calculations take ~30ms.

Will first look at converting the SPI transfers to 16bit wide (been pending for a bit..) and maybe after use the new 240x240 screen I got


# Sun May 8

Gave up on running on RP2040 after realizing there was _no way_ I could fit the promised Lua space for _game memory_ (2MB) anywhere.  
Went and got an ESP32 "WROOM32" which has 4MB (mega _bytes_) of SPIRAM (slow), but magic in the MMU makes it cache, so could be alright. Ordered one, and starting hacking on a spare ESP32 I had.

Getting the build and compiler going was a nightmare; couldn't get the magic CMake functions to include the Lua sources so it kept failing to link.

Eventually, got it going and had another nightmare: the display would randomly not turn on. Seems like it was a timing issue, as fiddling with the BLK randomly on reboot would get it going.  
When the new WROOM32 arrived, the issue mysteriously went away.

The docs on the ESP are nowhere as clear as the RP2040 docs; I kept having failures to do SPI transfers in bulk and had to chop them off in small bits. It was [right here](https://espressif-docs.readthedocs-hosted.com/projects/esp-idf/en/latest/api-reference/peripherals/spi_master.html#_CPPv4N16spi_bus_config_t15max_transfer_szE) in the docs though, that the default limit is _4094_ bytes. Still unsure why it wants to `malloc` its own chunk of memory per transaction, instead of letting me give it one (the backbuffer exists _for this reason_).

After this was "running" (a _lot_ of the build is hacked / chopped), I went back to the "rockets" example, as it kept having performance issues on the Pico, with ~20-30ms to draw each rotated sprite. In the ESP this is a bit faster but still very slow (~14ms).  
Biggest problem is that it does 400 inner loops _per frame, per sprite_ to draw the rotated sprites.  The only way I see something like this working is to JIT this _somehow_, but that seems _so_ hard.

Some silly performance notes:

The code for st7789, as written, would take ~500ms to render a full screen of solid color. Replacing that code with a single SPI call takes ~5-7ms. [This doc](https://austinmorlan.com/posts/embedded_game_programming_3/) helped me a bit on getting things going.

Calling `put_pixel` 50k times:

* At `-O2`: 2ms
* At `-Og`: 7ms
* At `-O0`: 10ms
* At `-Os`: 25ms

maybe `-Os` is ignoring the `inline` ?

Still can't get the SPI data transfer to be LSB to avoid having to flip endiannes on the front->backbuffer copy. Can probably do it anyway when writing to the FB..

[ESP32 SPIRAM speed](https://www.esp32.com/viewtopic.php?t=13356) ~20MB/s, more if hitting the cache.

# Mon May 9

Merged ESP32 branch (breaking other targets in the process). Gave up on trying to scale up the game to my 1.33" 240x240 display; bought a 160x128 1.44" display (will have to futz around with the other driver.. again).  
But the image at least should be a lot larger & clearer.

Mostly gave up when calculated that at 40MHz, I could do over (1-bit) SPI, at MOST 40FPS, if the core did nothing but transfer data.. yet I would need to dynamically stretch the image on every frame, as there's not enough space for a 240x240x2 
framebuffer in DRAM (can use PSRAM, but that's slower). Alternative is to find and use a 8-bit SPI display, but still, not great to have to resize the image on every frame.

Thinking about audio, but that sounds super complicated so will leave that in the background and keep reading.

Found [this report](https://nymphium.github.io/pdf/opeth_report.pdf) about lua bytecode optimization and really want to look into doing something like it. Particularly lowering the cost of a function call for the "standard library"

After a couple of minutes of executing the `celeste` level; the same corruption appears on the map (a couple of black pixels); not sure why yet.

Want to configure a joystick / buttons to actually _use_ the console, but the ADC always read either 0 or 4095 and the multimeter is broken ((
