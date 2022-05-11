cmake_minimum_required(VERSION 3.13)

if(NOT DEFINED BACKEND)
	message(FATAL_ERROR "You must define the variable BACKEND (to either PICO, ESP32 or PC)" )
endif()

if(BACKEND STREQUAL "PICO")
include(pico_sdk_import.cmake)
elseif(BACKEND STREQUAL "ESP32")
set(EXTRA_COMPONENT_DIRS "esp")
set(COMPONENTS "esp")
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
endif()

project(my_project C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

#add_subdirectory(lua)
add_compile_options(
	#	-Werror
	#-g3
        -Wno-unused-variable
)

add_custom_command(
	OUTPUT static_game_data.h
	COMMAND python3 to_c.py > ${CMAKE_SOURCE_DIR}/static_game_data.h
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	#	DEPENDS stdlib/stdlib.lua artifacts/font.lua examples/*
	)

if(BACKEND STREQUAL "PICO")
	# initialize the Raspberry Pi Pico SDK
	file (GLOB st_src CONFIGURE_DEPENDS "/home/david/git/pico_st7735_80x160/st7735_80x160/*")
	pico_sdk_init()
	
	add_executable(hello_pico
	    main.cpp
	    static_game_data.h
	    ${lua_src}
	    ${st_src}
	)
	
	target_compile_options(hello_pico PRIVATE -DSCREEN_HEIGHT=80 -DSCREEN_WIDTH=160)
	#add_dependencies(hello_pico static_game_data.h)
	#UART
	## pico_enable_stdio_usb(hello_pico 1)
	#pico_enable_stdio_uart(hello_pico 1)
	
	#USB
	pico_enable_stdio_usb(hello_pico 1)
	pico_enable_stdio_uart(hello_pico 0)
	
	target_link_libraries(hello_pico
		# hardware_uart
	    hardware_pwm
	    hardware_clocks
	    hardware_spi
	
	    my_lua_lib
	    pico_stdlib
	    pico_multicore
	)
	
	target_include_directories(hello_pico PUBLIC
	    ../pico_st7735_80x160
	    lua
	    )
	
	# create map/bin/hex/uf2 file in addition to ELF.
	pico_add_extra_outputs(hello_pico)

elseif(BACKEND STREQUAL "PC")
	add_executable(pc_pico
	    static_game_data.h
	    main.cpp
	    ${lua_src}
	)
	add_subdirectory(SDL)
	add_subdirectory(lua)
	
	# Add pico_stdlib library which aggregates commonly used features
	target_link_libraries(pc_pico
	    my_lua_lib
	    SDL2::SDL2
	    SDL2::SDL2main
	)
	
	target_include_directories(pc_pico PUBLIC
	    lua
	    SDL
	    )
	
    target_compile_options(pc_pico PRIVATE -DSDL_BACKEND=1 -DLUA_USE_LINUX=1 -DW_SCREEN_HEIGHT=512 -DW_SCREEN_WIDTH=512 -DSCREEN_WIDTH=128 -DSCREEN_HEIGHT=128)
    add_compile_options(
            -g3
            )

elseif(BACKEND STREQUAL "ESP32")
endif()
