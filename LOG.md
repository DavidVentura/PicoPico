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

Still can't get the SPI data transfer to be LSB to avoid having to flip endianness on the front->backbuffer copy. Can probably do it anyway when writing to the FB..

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

# Wed May 10

Fixed the build so that all platforms can build in one go, without having to comment out `#define`s; also moved most of the code that was duplicated (`gfx_*`) to be shared, managed to delete _a bunch_ of code.

Curious about performance implications of all the current bit shifting done to render (given that each color on the palette is a `uint8_t[3]`). Starting point; in celeste, the frames take:

```
Frame avg 16200µs
Frame avg 16159µs
Frame avg 16239µs
Frame avg 16243µs
Frame avg 16170µs
Frame avg 16144µs
Frame avg 16311µs
Frame avg 16240µs
```
(Average: 16213)

Moving average, over 100 frames.

And after changing the palette lookup per pixel:

```
Frame avg 13876µs
Frame avg 13849µs
Frame avg 13963µs
Frame avg 14121µs
Frame avg 13989µs
Frame avg 13923µs
Frame avg 13892µs
```
(Average: 13944)

16% faster!! that's a nice, easy win.

# 13 May

Got SFX working! Struggled to understand the basics of synths but [this video](https://www.youtube.com/watch?v=OSCzKOqtgcA) helped quite a bit.

Getting SDL going also took a while; combination of sample rates and endianness blasted my ears more than necessary.

When the emulator sounded OK, I ran it on the ESP32 without any output configured and saw that the simplest SFX took ~25ms to calculate (sure, the sound lasts like 400ms, but I don't want 10% of the CPU time to go to SFX!).

I know the ESP32 has an FPU, which means floating point calculations are not _terribly_ slow, but they are not as fast as integer arithmethic; so made some optimizations: turns out `fmodf(advance, 1.f)` takes _8_ extra milliseconds than  `advance - truncf(advance)` (over ~11 thousand calls).  This already brought ~25ms to ~17ms.  Moved quite some constants to be static and some calculations out from the inner loop, and the execution time dropped to ~4.5ms(!)

Still, the [Performance guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/performance/speed.html#improving-overall-speed) on ESP32 says

>  Even though ESP32 has a single precision hardware floating point unit, floating point calculations are always slower than integer calculations. If possible then use fixed point representations [...]

and I already am linking `fix32` for Lua.. so converted the synth to use fixed point and that made it at least twice as fast (down to ~2ms).

# 14 May

Rewrote the sounds pipeline -- it used to generate ALL the samples for an SFX on demand, and fill HUGE buffers with it.  
Now, based on a lot of reading (which is greatly summarized [here](https://atomic14.com/2021/04/20/esp32-i2s-dma-buf-len-buf-count.html)) I've changed the pipeline to only generate samples on demand (when the DMA buffers are empty) -- currently that is ~20ms worth of audio. This simplified the code a lot, and now it actually works without pops

# 17 May

Start looking at Lua performance overhead:

Benchmark code:
```lua
start = t()
for i=1,32000 do
      noop(i)
end
endt = t()
printh("32k x noop took ".. endt-start)
```
- 32.000 noop calls (takes 1 number and returns it) = 122ms

meaning, 1.000 calls = 3.8ms. **This caps the calls per frame at 8684 without doing any work**.

Per iteration; the bytecode looks like

```
5	[2]	GETTABUP 	4 0 -3	; _ENV "noop"
6	[2]	MOVE     	5 3
7	[2]	CALL     	4 2 1
```

Same code in C (with -O0) takes ~6ms:

```c
#pragma GCC push_options
#pragma GCC optimize ("O0")
int _noop(int arg) {
    return arg;
}
void bench_me() {
    uint32_t bstart = now();
    int res = 0;
    for (uint16_t i=0; i<32000; i++) {
        res = _noop(5);
    }
    printf("Benchmark took %d; result is %d\n", now()-bstart, res);
}
#pragma GCC pop_options
```

Approximately, 20x faster is the maximum we can get to.


# 18 May

On first pass of ["Fast C Calls"](https://github.com/DavidVentura/z8lua/commit/201aa808ca1e0b0529a6d9af0c80307fec263d92):

> 32k x noop took 94ms

1000 calls = 2.9ms; new code takes 77% of the time as the previous one;

the bytecode hasn't changed; so 

```
5	[2]	GETTABUP 	4 0 -3	; _ENV "noop"
6	[2]	MOVE     	5 3
7	[2]	CALL     	4 2 1
```

this way, `noop` is _still looked up for each call_; as the function tag is embedded in the function itself (which is stored in `_ENV`)

this is faster, yes, but not _really_ fast

Calling a function that does a _small_ amount of work:

```lua
start = t()
for i=1,32000 do
      fast_floor(i+0.5)
end
endt = t()
printh("32k x fast_floor took ".. endt-start)

start = t()
for i=1,32000 do
      flr(i+0.5)
end
endt = t()
printh("32k x flr took ".. endt-start)

```

> 32k x fast_floor took 99ms
> 32k x flr took 145ms

Not really sure about these results.. the fast call went up by 5ms (I assume, calculating how to floor the number), but the regular call doesn't take 5 ms more than the slow noop.. takes 23ms more.


I think the real improvement for this would be to add a new opcode (ie: FASTCALL) that'd embed the function ID in a byte or something. I only want to "accelerate" a handful of calls (<30) so capping at 255 is not a problem.

This all kinda started by looking again at `Rockets!` which used to take ~30ms to draw each sprite (it calculates rotation _every frame_)

With the "regular" `flr` calls, drawing 5 sprites consistently takes 71ms, and with the fast calls it consistently takes 65ms. It's a nice 9% win, but still _really_ far from hitting the <30ms mark to make the game playable.

This is the function that's so slow:

```lua
function spr_r(s,x,y,a,w,h)
	sw=(w or 1)*8
	sh=(h or 1)*8
	sx=(s%8)*8
	sy=flr(s/8)*8
	x0=flr(0.5*sw)
	y0=flr(0.5*sh)
	a=a/360
	sa=sin(a)
	ca=cos(a)
	for ix=sw*-1,sw+4 do
		for iy=sh*-1,sh+4 do
			dx=ix-x0
			dy=iy-y0
			xx=flr(dx*ca-dy*sa+x0)
			yy=flr(dx*sa+dy*ca+y0)
			if (xx>=0 and xx<sw and yy>=0 and yy<=sh-1) then
				pset(x+ix,y+iy,sget(sx+xx,sy+yy))
			end
		end
	end
end
```

`sw` and `sh` are always 8; so both loops go from -12 to 12 (=576 iterations for the inner loop). This is _per sprite_ and up to 5 sprites can be live at any point in time.

If you know about lua performance, you already know what the _biggest_ problem is here, but it is very obvious when looking at bytecode; this is the inner loop:

```
	50	[569]	GETTABUP 	14 0 -8	; _ENV "x0"
	51	[569]	SUB      	14 9 14
	52	[569]	SETTABUP 	0 -18 14	; _ENV "dx"
	53	[570]	GETTABUP 	14 0 -10	; _ENV "y0"
	54	[570]	SUB      	14 13 14
	55	[570]	SETTABUP 	0 -19 14	; _ENV "dy"
	56	[571]	GETTABUP 	14 0 -7	; _ENV "flr"
	57	[571]	GETTABUP 	15 0 -18	; _ENV "dx"
	58	[571]	GETTABUP 	16 0 -14	; _ENV "ca"
	59	[571]	MUL      	15 15 16
	60	[571]	GETTABUP 	16 0 -19	; _ENV "dy"
	61	[571]	GETTABUP 	17 0 -12	; _ENV "sa"
	62	[571]	MUL      	16 16 17
	63	[571]	SUB      	15 15 16
	64	[571]	GETTABUP 	16 0 -8	; _ENV "x0"
	65	[571]	ADD      	15 15 16
	66	[571]	CALL     	14 2 2
	67	[571]	SETTABUP 	0 -20 14	; _ENV "xx"
	68	[572]	GETTABUP 	14 0 -7	; _ENV "flr"
	69	[572]	GETTABUP 	15 0 -18	; _ENV "dx"
	70	[572]	GETTABUP 	16 0 -12	; _ENV "sa"
	71	[572]	MUL      	15 15 16
	72	[572]	GETTABUP 	16 0 -19	; _ENV "dy"
	73	[572]	GETTABUP 	17 0 -14	; _ENV "ca"
	74	[572]	MUL      	16 16 17
	75	[572]	ADD      	15 15 16
	76	[572]	GETTABUP 	16 0 -10	; _ENV "y0"
	77	[572]	ADD      	15 15 16
	78	[572]	CALL     	14 2 2
	79	[572]	SETTABUP 	0 -21 14	; _ENV "yy"
	80	[573]	GETTABUP 	14 0 -20	; _ENV "xx"
	81	[573]	LE       	0 -22 14	; 0.0 -
	82	[573]	JMP      	0 24	; to 107
	83	[573]	GETTABUP 	14 0 -20	; _ENV "xx"
	84	[573]	GETTABUP 	15 0 -1	; _ENV "sw"
	85	[573]	LT       	0 14 15
	86	[573]	JMP      	0 20	; to 107
	87	[573]	GETTABUP 	14 0 -21	; _ENV "yy"
	88	[573]	LE       	0 -22 14	; 0.0 -
	89	[573]	JMP      	0 17	; to 107
	90	[573]	GETTABUP 	14 0 -21	; _ENV "yy"
	91	[573]	GETTABUP 	15 0 -4	; _ENV "sh"
	92	[573]	SUB      	15 15 -2	; - 1.0
	93	[573]	LE       	0 14 15
	94	[573]	JMP      	0 12	; to 107
	95	[574]	GETTABUP 	14 0 -23	; _ENV "pset"
	96	[574]	ADD      	15 1 9
	97	[574]	ADD      	16 2 13
	98	[574]	GETTABUP 	17 0 -24	; _ENV "sget"
	99	[574]	GETTABUP 	18 0 -5	; _ENV "sx"
	100	[574]	GETTABUP 	19 0 -20	; _ENV "xx"
	101	[574]	ADD      	18 18 19
	102	[574]	GETTABUP 	19 0 -6	; _ENV "sy"
	103	[574]	GETTABUP 	20 0 -21	; _ENV "yy"
	104	[574]	ADD      	19 19 20
	105	[574]	CALL     	17 3 0
	106	[574]	CALL     	14 0 1
```

The issue here are all those `GETTABUP` (`get table upvalue`) which are looking up the _global variables_ in every call. Usually, the way to have this work faster is by declaring each variable `local` so they'll be in the function's registers. By changing all the variables to `local`, this is the generated bytecode

```
	36	[569]	SUB      	23 18 10
	37	[570]	SUB      	24 22 11
	38	[571]	GETTABUP 	25 0 -3	; _ENV "flr"
	39	[571]	MUL      	26 23 14
	40	[571]	MUL      	27 24 13
	41	[571]	SUB      	26 26 27
	42	[571]	ADD      	26 26 10
	43	[571]	CALL     	25 2 2
	44	[572]	GETTABUP 	26 0 -3	; _ENV "flr"
	45	[572]	MUL      	27 23 13
	46	[572]	MUL      	28 24 14
	47	[572]	ADD      	27 27 28
	48	[572]	ADD      	27 27 11
	49	[572]	CALL     	26 2 2
	50	[573]	LE       	0 -10 25	; 0.0 -
	51	[573]	JMP      	0 15	; to 67
	52	[573]	LT       	0 25 6
	53	[573]	JMP      	0 13	; to 67
	54	[573]	LE       	0 -10 26	; 0.0 -
	55	[573]	JMP      	0 11	; to 67
	56	[573]	SUB      	27 7 -1	; - 1.0
	57	[573]	LE       	0 26 27
	58	[573]	JMP      	0 8	; to 67
	59	[574]	GETTABUP 	27 0 -11	; _ENV "pset"
	60	[574]	ADD      	28 1 18
	61	[574]	ADD      	29 2 22
	62	[574]	GETTABUP 	30 0 -12	; _ENV "sget"
	63	[574]	ADD      	31 8 25
	64	[574]	ADD      	32 9 26
	65	[574]	CALL     	30 3 0
	66	[574]	CALL     	27 0 1
```


With this change, rendering 5 sprites goes from the ("optimized") 65ms/frame to **29ms/frame**. 21 extra lookups * 576 inner loops = 12096 calls.. which acording to my original benchmarking (if these were function calls) is ~45ms.

So, maybe optimizing opcodes for fastcalls is not the thing that will bring the biggest gains; maybe a bytecode optimizer would be better.

Performing some manual optimizations in the lua code (declaring a local copy of `pset` `sget` `flr` and lifting calculations outside the inner loop) brought the frame time to **23ms**; a 26% improvement; and _almost_ perfectly playable.

TODO: fastcall `sget` and `pset` to test the impact (12k calls each ?)


Interesting optimizations:

* Localizing global accesses (`sin` shouldn't be loaded from `_ENV`)
* Fast builting calls (`sin` should be called cheaply)
* [Loop hoisting](https://en.wikipedia.org/wiki/Loop-invariant_code_motion)


# 20 May

Still going on about performance; now on trig functions:


Baseline

> 32k x c sin floating took 548ms

Optimizing calls into the "regular fastcalls" (ie: still looking up via _ENV on every call)

> 32k x fast sin floating took 718ms
> 32k x slow sin floating took 735ms

This makes 32k calls, 20ms faster.. in practice this is not going to make a difference

Still struggling to figure out how to emit bytecode that's aware of the builtins


Optimizing `sin`:

Using [fixed point calculations](https://www.nullhardware.com/blog/fixed-point-sine-and-cosine-for-embedded-systems/) for `sin`:

> 32k x c sin fixed 	  took  50ms
> 32k x fast sin fixed 	  took 107ms
> 32k x slow sin fixed 	  took 135ms
> 32k x slow sin floating took 735ms

Now this is _a lot_ faster! ~7x faster `sin` / `cos` calls
