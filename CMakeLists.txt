cmake_minimum_required(VERSION 3.13)

# initialize the SDK based on PICO_SDK_PATH
# note: this must happen before project()
include(pico_sdk_import.cmake)

project(my_project)
file (GLOB lua_src CONFIGURE_DEPENDS "/home/david/Downloads/lua-5.2.4/src/*.c")
file (GLOB st_src CONFIGURE_DEPENDS "/home/david/git/pico_st7735_80x160/st7735_80x160/*")

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
pico_enable_stdio_usb(hello_pico 1)
pico_enable_stdio_uart(hello_pico 0)

# Add pico_stdlib library which aggregates commonly used features
target_link_libraries(hello_pico
    hardware_uart
    hardware_pwm
    hardware_clocks
    hardware_spi

    pico_stdlib
    #    st7735_80x160
)
target_include_directories(hello_pico PUBLIC
    /home/david/Downloads/lua-5.2.4/src/
    ../pico_st7735_80x160)

# create map/bin/hex/uf2 file in addition to ELF.
pico_add_extra_outputs(hello_pico)
