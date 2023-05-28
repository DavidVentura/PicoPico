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
elseif(BACKEND STREQUAL "RAWDRAW")
add_definitions(-DRAWDRAW_BACKEND)
elseif(BACKEND STREQUAL "ANDROID")
add_definitions(-DANDROID_BACKEND)
add_definitions(-DRAWDRAW_BACKEND)
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

elseif(BACKEND STREQUAL "ANDROID")
	set(APPNAME "cnfgtest")
	# setting vars before `add_subdirectory` is important
	# TODO generic vars
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffunction-sections -Os -fdata-sections -Wall -fvisibility=hidden -std=c++11")
	# missing -llua, automatic?

	add_library("${APPNAME}" SHARED
		static_game_data.h
		entrypoint.cpp
		rawdrawandroid/android_native_app_glue.c
		${lua_src}
		)


	SET(ANDROIDVERSION "30")
	SET(ANDROIDTARGET "${ANDROIDVERSION}")
	set(LABEL "${APPNAME}")
	set(ANDROIDSDK "/home/david/AndroidCrap")
	set(NDK "${ANDROIDSDK}/ndk/21.3.6528147")

	SET(OS_NAME "linux-x86_64")
	set(PACKAGENAME "org.yourorg.${APPNAME}")
	SET(CXX_ARM64 "${NDK}/toolchains/llvm/prebuilt/${OS_NAME}/bin/aarch64-linux-android${ANDROIDVERSION}-clang++")
	SET(CC_ARM64 "${NDK}/toolchains/llvm/prebuilt/${OS_NAME}/bin/aarch64-linux-android${ANDROIDVERSION}-clang")
	SET(BUILD_TOOLS "${ANDROIDSDK}/build-tools/30.0.2")
	SET(AAPT "${BUILD_TOOLS}/aapt")
	SET(ADB "${ANDROIDSDK}/platform-tools/adb")
	SET(KEYSTOREFILE "${CMAKE_CURRENT_SOURCE_DIR}/rawdrawandroid/my-release-key.keystore")
	SET(STOREPASS "password")
	SET(ALIASNAME "standkey")
	SET(DNAME "CN=example.com, OU=ID, O=Example, L=Doe, S=John, C=GB")
	SET(APKFILE "${APPNAME}.apk")
	#SET(CC_ARM32 "${NDK}/toolchains/llvm/prebuilt/${OS_NAME}/bin/armv7a-linux-androideabi${ANDROIDVERSION}-clang")
	#SET(CC_x86 "${NDK}/toolchains/llvm/prebuilt/${OS_NAME}/bin/i686-linux-android${ANDROIDVERSION}-clang")
	#SET(CC_x86_64 "${NDK}/toolchains/llvm/prebuilt/${OS_NAME}/bin/x86_64-linux-android${ANDROIDVERSION}-clang")

	set(CMAKE_C_COMPILER "${CC_ARM64}")
	set(CMAKE_CXX_COMPILER "${CXX_ARM64}")


	add_subdirectory(lua)

	# Add pico_stdlib library which aggregates commonly used features
	target_link_libraries("${APPNAME}"
		my_lua_lib
		-Wl,--gc-sections -Wl,-Map=output.map
		-s
		-static-libstdc++
		-lm -lGLESv3 -lEGL -landroid -llog 
		-shared -uANativeActivity_onCreate
		)

	target_include_directories("${APPNAME}" PUBLIC
		lua
		rawdrawandroid
		rawdrawandroid/rawdraw
		#${NDK}/sysroot/usr/include/
		${NDK}/toolchains/llvm/prebuilt/${OS_NAME}/sysroot/usr/include
		)

	target_compile_options("${APPNAME}" PRIVATE -DRAWDRAW_BACKEND=1 -DANDROID_BACKEND=1 -DSCREEN_WIDTH=128 -DSCREEN_HEIGHT=128 -DHUD_HEIGHT=12 -DAPPNAME="cnfgtest" -DANDROIDVERSION=${ANDROIDVERSION} -DANDROID)

	add_custom_target(render_xml ALL
		COMMAND PACKAGENAME=${PACKAGENAME} ANDROIDVERSION=${ANDROIDVERSION} ANDROIDTARGET=${ANDROIDTARGET} APPNAME=${APPNAME} LABEL=${LABEL} envsubst '$$ANDROIDTARGET $$ANDROIDVERSION $$APPNAME $$PACKAGENAME $$LABEL' < "${CMAKE_CURRENT_SOURCE_DIR}/rawdrawandroid/AndroidManifest.xml.template" > AndroidManifest.xml
		)

	add_custom_command(
		OUTPUT "${KEYSTOREFILE}"
		COMMAND keytool -genkey -v -keystore ${KEYSTOREFILE} -alias ${ALIASNAME} -keyalg RSA -keysize 2048 -validity 10000 -storepass ${STOREPASS} -keypass ${STOREPASS} -dname ${DNAME}
		)
	add_custom_target(makeapk ALL
		BYPRODUCTS "${APKFILE}"
		BYPRODUCTS "${APKFILE}.idsig"
		BYPRODUCTS "activity_name"
		DEPENDS "${KEYSTOREFILE}"
		COMMAND mkdir -p makecapk/assets makecapk/lib/arm64-v8a/
		COMMAND cp "${CMAKE_CURRENT_BINARY_DIR}/lib${APPNAME}.so" makecapk/lib/arm64-v8a/
		COMMAND cp -r "${CMAKE_CURRENT_SOURCE_DIR}/rawdrawandroid/Sources/assets/*" makecapk/assets
		COMMAND rm -rf temp.apk
		COMMAND ${AAPT} package -f -F temp.apk -I ${ANDROIDSDK}/platforms/android-${ANDROIDVERSION}/android.jar -M AndroidManifest.xml -S "${CMAKE_CURRENT_SOURCE_DIR}/rawdrawandroid/Sources/res" -A makecapk/assets -v --target-sdk-version ${ANDROIDTARGET}
		COMMAND unzip -o temp.apk -d makecapk
		COMMAND rm -rf makecapk.apk
		COMMAND cd makecapk && zip -D5r ../makecapk.apk . && zip -D0r ../makecapk.apk ./resources.arsc ./AndroidManifest.xml
		COMMAND rm -rf ${APKFILE}
		COMMAND ${BUILD_TOOLS}/zipalign -v 4 makecapk.apk ${APKFILE}
		# #Using the apksigner in this way is only required on Android 30+
		COMMAND ${BUILD_TOOLS}/apksigner sign --key-pass pass:${STOREPASS} --ks-pass pass:${STOREPASS} --ks ${KEYSTOREFILE} ${APKFILE}
		COMMAND ${AAPT} dump badging ${APKFILE} | grep "launchable-activity" | cut -f 2 -d"'" >activity_name
		)
	add_dependencies(makeapk "${APPNAME}")

	add_custom_target(run
		DEPENDS ${APKFILE}
		COMMAND ${ADB} install -r ${APKFILE}
		COMMAND ${ADB} shell am start -n ${PACKAGENAME}/android.app.NativeActivity
		# TODO: android.app.NativeActivity is actually $(cat activity_name)
	)
	add_dependencies(run makeapk)

elseif(BACKEND STREQUAL "RAWDRAW")
	add_executable(rawdraw_pico
		static_game_data.h
		entrypoint.cpp
		${lua_src}
		)
	add_subdirectory(lua)

	# Add pico_stdlib library which aggregates commonly used features
	target_link_libraries(rawdraw_pico
		my_lua_lib
		)

	target_include_directories(rawdraw_pico PUBLIC
		lua
		rawdraw
		)

	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pg -fsingle-precision-constant -Wall -Wshadow -Wundef -fsanitize=address")
	SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pg -lX11 -lpthread -lXinerama -lXext -lGL -g -lm -ldl")
	SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -pg ")
	target_compile_options(rawdraw_pico PRIVATE -DRAWDRAW_BACKEND=1 -DLUA_USE_LINUX=1 -DW_SCREEN_HEIGHT=512 -DW_SCREEN_WIDTH=512 -DSCREEN_WIDTH=128 -DSCREEN_HEIGHT=128 -DHUD_HEIGHT=12)
	add_compile_options(
		-g3
		-fsingle-precision-constant
		)
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
	SET(test_compile_options -DTEST_BACKEND=1 -DLUA_USE_LINUX=1 -DSCREEN_WIDTH=128 -DSCREEN_HEIGHT=128 -DHUD_HEIGHT=12)
	#  -DRAWDRAW_BACKEND=1 -DANDROID_BACKEND=1

	enable_testing()
	add_subdirectory(lua rawdraw)

	file(GLOB TEST_SOURCES
		tests/test_hud.cpp
		tests/test_menu.cpp
		tests/test_hello_world.cpp
		tests/test_primitives.cpp
		tests/rawdraw_backend_test.cpp
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

	include_directories(${CMAKE_CURRENT_SOURCE_DIR} lua 
		#$(NDK)/sysroot/usr/include $(NDK)/toolchains/llvm/prebuilt/$(OS_NAME)/sysroot/usr/include
		#/home/david/AndroidCrap/ndk/21.3.6528147/sysroot/usr/include/
		#/home/david/git/rawdrawandroid
		#/home/david/git/rawdrawandroid/rawdraw
		)

	add_compile_options(
		-g3
		-fsingle-precision-constant
		)

endif()
