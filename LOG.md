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
