cmake_minimum_required(VERSION 3.13)

if(NOT DEFINED BACKEND)
	message(FATAL_ERROR "You must define the variable BACKEND (to either PICO, ESP32, PC or TEST)" )
endif()

if(BACKEND STREQUAL "PICO")
include(pico_sdk_import.cmake)
add_definitions(-DPICO_BACKEND)
elseif(BACKEND STREQUAL "ESP32")
add_definitions(-DESP_BACKEND)
set(EXTRA_COMPONENT_DIRS "esp")
set(COMPONENTS "esp")
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
elseif(BACKEND STREQUAL "PC")
add_definitions(-DSDL_BACKEND)
elseif(BACKEND STREQUAL "TEST")
add_definitions(-DTEST_BACKEND)
else()
message( SEND_ERROR "Invalid backend" )
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

file(GLOB ALL_RESOURCE_FILES CONFIGURE_DEPENDS stdlib/stdlib.lua artifacts/font.lua examples/* to_c.py)
add_custom_command(
	OUTPUT ${CMAKE_SOURCE_DIR}/static_game_data.h
	COMMAND python3 to_c.py --emit-stdlib examples/ > ${CMAKE_SOURCE_DIR}/static_game_data.h
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	DEPENDS ${ALL_RESOURCE_FILES}
	)

file(GLOB ALL_SOURCE_FILES CONFIGURE_DEPENDS *.c *.h esp/*.c esp/*.h)
add_custom_target(
	cppcheck
	COMMAND /usr/bin/cppcheck
        --enable=warning,performance,portability,information,missingInclude
	--language=c++
	${ALL_SOURCE_FILES}
)
if(BACKEND STREQUAL "PICO")
	# initialize the Raspberry Pi Pico SDK
	file (GLOB st_src CONFIGURE_DEPENDS CONFIGURE_DEPENDS "/home/david/git/pico_st7735_80x160/st7735_80x160/*")
	pico_sdk_init()
	
	add_executable(hello_pico
	    entrypoint.cpp
	    static_game_data.h
	    ${lua_src}
	    ${st_src}
	)
	
        target_compile_options(hello_pico PRIVATE -DSCREEN_HEIGHT=80 -DSCREEN_WIDTH=160 -DHUD_HEIGHT=12)
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
		entrypoint.cpp
		${lua_src}
		)
	add_subdirectory(SDL_mixer)
	add_subdirectory(SDL)
	add_subdirectory(lua)

	# Add pico_stdlib library which aggregates commonly used features
	target_link_libraries(pc_pico
		my_lua_lib
		SDL2::SDL2
		SDL2::SDL2main
		SDL2_mixer
		)

	target_include_directories(pc_pico PUBLIC
		lua
		SDL
		SDL_mixer
		)

	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pg -fsingle-precision-constant -Wall -Wshadow -Wundef -fsanitize=address")
	SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pg")
	SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -pg")
        target_compile_options(pc_pico PRIVATE -DSDL_BACKEND=1 -DLUA_USE_LINUX=1 -DW_SCREEN_HEIGHT=512 -DW_SCREEN_WIDTH=512 -DSCREEN_WIDTH=128 -DSCREEN_HEIGHT=128 -DHUD_HEIGHT=12)
	add_compile_options(
		-g3
		-fsingle-precision-constant
		)

	if(APPLE)
		add_custom_command(TARGET pc_pico POST_BUILD COMMAND codesign -s - ./pc_pico)
	endif()


elseif(BACKEND STREQUAL "ESP32")
	# some day i'll figure out how to merge the 2 projects
elseif(BACKEND STREQUAL "TEST")
	add_custom_target(
		bin_to_png
		COMMAND python3 buf_to_png.py --in-file data/hud.bin --out-file data/hud.png --width 128 --height 12
		COMMAND python3 buf_to_png.py --in-file data/menu.bin --out-file data/menu.png --width 128 --height 128 --palette
		COMMAND python3 buf_to_png.py --in-file data/hello_world.bin --out-file data/hello_world.png --width 128 --height 128 --palette
		COMMAND python3 buf_to_png.py --in-file data/test_basic_gfx.bin --out-file data/test_basic_gfx.png --width 128 --height 128 --palette
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/tests/
	)
	add_custom_target(
		tests_webserver
		COMMAND python3 -m http.server
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/tests/data
	)

	file(GLOB ALL_REGRESSION_FILES CONFIGURE_DEPENDS tests/regression/*.p8 to_c.py)
	add_custom_command(
		OUTPUT ${CMAKE_SOURCE_DIR}/tests/regression_static_game_data.h
		COMMAND python3 to_c.py --cart-prefix regression tests/regression > ${CMAKE_SOURCE_DIR}/tests/regression_static_game_data.h
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		DEPENDS ${ALL_REGRESSION_FILES}
	)
	add_custom_command(
		OUTPUT ${CMAKE_SOURCE_DIR}/tests/test_static_game_data.h
		COMMAND python3 to_c.py --cart-prefix t_ tests/carts > ${CMAKE_SOURCE_DIR}/tests/test_static_game_data.h
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		DEPENDS ${ALL_REGRESSION_FILES}
	)
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pg -fsingle-precision-constant -Wall -Wshadow -Wundef -fsanitize=address")
	SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pg")
	SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -pg")
	SET(test_compile_options -TEST_BACKEND=1 -DLUA_USE_LINUX=1 -DSCREEN_WIDTH=128 -DSCREEN_HEIGHT=128 -DHUD_HEIGHT=12)

	enable_testing()
	add_subdirectory(lua)

	file(GLOB TEST_SOURCES
		tests/test_hud.cpp
		tests/test_menu.cpp
		tests/test_hello_world.cpp
		tests/test_primitives.cpp
		)
	
	foreach(testfile ${TEST_SOURCES})
		get_filename_component(EXECUTABLE_NAME ${testfile} NAME_WE)

		add_executable(${EXECUTABLE_NAME} static_game_data.h tests/test_static_game_data.h ${testfile} ${lua_src})
		target_link_libraries(${EXECUTABLE_NAME} my_lua_lib)
		add_test(NAME ${EXECUTABLE_NAME} COMMAND ${EXECUTABLE_NAME})
		target_compile_options(${EXECUTABLE_NAME} PRIVATE ${test_compile_options})
		if(APPLE)
			add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD COMMAND codesign -s - ${EXECUTABLE_NAME})
		endif()
	endforeach(testfile ${TEST_SOURCES})

	# test regression
	add_executable(test_regression static_game_data.h tests/regression_static_game_data.h tests/test_lua_regression.cpp ${lua_src})
	target_link_libraries(test_regression my_lua_lib)
	add_test(NAME test_regression COMMAND test_regression)
	target_compile_options(test_regression PRIVATE ${test_compile_options})

	include_directories(${CMAKE_CURRENT_SOURCE_DIR} lua)

	add_compile_options(
		-g3
		-fsingle-precision-constant
		)

endif()
