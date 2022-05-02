cmake_minimum_required(VERSION 3.13)

# initialize the SDK based on PICO_SDK_PATH
# note: this must happen before project()
include(pico_sdk_import.cmake)

project(my_project C CXX ASM)

add_library(lualib SHARED
/home/david/git/lua/lapi.cpp
/home/david/git/lua/lcode.cpp
/home/david/git/lua/ldebug.cpp
/home/david/git/lua/ldo.cpp
/home/david/git/lua/ldump.cpp
/home/david/git/lua/lfunc.cpp
/home/david/git/lua/lgc.cpp
/home/david/git/lua/llex.cpp
/home/david/git/lua/lmem.cpp
/home/david/git/lua/lobject.cpp
/home/david/git/lua/lopcodes.cpp
/home/david/git/lua/lparser.cpp
/home/david/git/lua/lstate.cpp
/home/david/git/lua/lstring.cpp
/home/david/git/lua/ltable.cpp
/home/david/git/lua/ltm.cpp
/home/david/git/lua/lundump.cpp
/home/david/git/lua/lvm.cpp
/home/david/git/lua/lzio.cpp
/home/david/git/lua/lctype.cpp
/home/david/git/lua/lauxlib.cpp
	)

file (GLOB st_src CONFIGURE_DEPENDS "/home/david/git/pico_st7735_80x160/st7735_80x160/*")

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

add_compile_options(
	-Werror
)

# rest of your project
add_executable(hello_pico
    main.c
    ${lua_src}
    ${st_src}
)

#UART
## pico_enable_stdio_usb(hello_pico 1)
#pico_enable_stdio_uart(hello_pico 1)

#USB
pico_enable_stdio_usb(hello_pico 1)
pico_enable_stdio_uart(hello_pico 0)

# Add pico_stdlib library which aggregates commonly used features
target_link_libraries(hello_pico
	# hardware_uart
    hardware_pwm
    hardware_clocks
    hardware_spi

    pico_stdlib
    pico_multicore
    lualib
)

target_include_directories(hello_pico PUBLIC
    /home/david/git/lua
    ../pico_st7735_80x160
    )

# create map/bin/hex/uf2 file in addition to ELF.
pico_add_extra_outputs(hello_pico)
