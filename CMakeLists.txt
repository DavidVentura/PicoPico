cmake_minimum_required(VERSION 3.13)

project(my_project C CXX ASM)
if(NOT DEFINED BACKEND)
	message(FATAL_ERROR "You must define the variable BACKEND (to either PICO, ESP32, PC, RAWDRAW, ANDROID, THREEDS or TEST)" )
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
elseif(BACKEND STREQUAL "THREEDS")
add_definitions(-DTHREEDS_BACKEND)
elseif(BACKEND STREQUAL "TEST")
add_definitions(-DTEST_BACKEND)
else()
message( SEND_ERROR "Invalid backend" )
endif()

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# TODO: how do i compile _a_ luac for meta-build
add_subdirectory(local_lua)
add_compile_options(
	#	-Werror
	#-g3
        -Wno-unused-variable
)

SET(luac ${CMAKE_CURRENT_BINARY_DIR}/local_lua/luac)
file(GLOB ALL_RESOURCE_FILES CONFIGURE_DEPENDS stdlib/stdlib.lua artifacts/font.lua carts/* scripts/to_c.py)
add_custom_command(
	OUTPUT ${CMAKE_SOURCE_DIR}/src/generated/static_game_data.h
	COMMAND python3 scripts/to_c.py --emit-stdlib --luac ${luac} carts/ > ${CMAKE_SOURCE_DIR}/src/generated/static_game_data.h
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

if(BACKEND STREQUAL "PC")
	add_executable(pc_pico
		src/generated/static_game_data.h
		src/entrypoint.cpp
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
		${CMAKE_CURRENT_SOURCE_DIR}
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

elseif(BACKEND STREQUAL "THREEDS")
	set(CMAKE_C_COMPILER "/opt/devkitpro/devkitARM/bin/arm-none-eabi-g++")
	set(CMAKE_CXX_COMPILER "/opt/devkitpro/devkitARM/bin/arm-none-eabi-g++")

	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O2 -mword-relocations -ffunction-sections -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft")
	SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
	SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -specs=3dsx.specs")

	SET(APPNAME "3ds_pico")

	link_directories(
		/opt/devkitpro/libctru/lib
		)

	add_executable("${APPNAME}"
		src/generated/static_game_data.h
		src/entrypoint.cpp
		)
	add_subdirectory(lua)

	target_link_libraries("${APPNAME}"
		my_lua_lib
		citro2d
		citro3d
		ctru
		m
		)

	target_include_directories("${APPNAME}" PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}
		/opt/devkitpro/libctru/include)
	target_compile_options("${APPNAME}" PRIVATE -DSCREEN_WIDTH=128 -DSCREEN_HEIGHT=128 -DHUD_HEIGHT=12 -D__3DS__)
	add_custom_target(generate_cart ALL
		BYPRODUCTS "${APPNAME}.3dsx"
		# ${CMAKE_SOURCE_DIR}/artifacts/3ds_icon.png
		# in GH actions, getting:
		# Could not decode PNG: /__w/PicoPico/PicoPico/artifacts/3ds_icon.png
		COMMAND /opt/devkitpro/tools/bin/smdhtool --create "${APPNAME}" "'Very_alpha'" "'David'" "/opt/devkitpro/libctru/default_icon.png" "${APPNANE}.smdh"
		COMMAND /opt/devkitpro/tools/bin/3dsxtool "${APPNAME}" "${APPNAME}.3dsx" --smdh=${APPNANE}.smdh #--romfs=/home/david/Downloads/a/romfs
		COMMAND rm -f "${APPNANE}.smdh"
		)
	add_dependencies(generate_cart "${APPNAME}")

elseif(BACKEND STREQUAL "ANDROID")
	set(APPNAME "cnfgtest")
	# setting vars before `add_subdirectory` is important
	# TODO generic vars
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffunction-sections -Os -fdata-sections -Wall -fvisibility=hidden -std=c++11")
	# missing -llua, automatic?

	add_library("${APPNAME}" SHARED
		src/generated/static_game_data.h
		src/entrypoint.cpp
		rawdrawandroid/android_native_app_glue.c
		)


	SET(ANDROIDVERSION "30")
	SET(ANDROIDTARGET "${ANDROIDVERSION}")
	set(LABEL "${APPNAME}")
	if(NOT DEFINED ANDROIDSDK)
		set(ANDROIDSDK "/home/david/AndroidCrap")
	endif()
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
		${CMAKE_CURRENT_SOURCE_DIR}
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

	# are you supposed to have a full shell script in here
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
		COMMAND ${BUILD_TOOLS}/zipalign -p -v 4 makecapk.apk ${APKFILE}
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
		src/generated/static_game_data.h
		src/entrypoint.cpp
		)
	add_subdirectory(lua)

	# Add pico_stdlib library which aggregates commonly used features
	target_link_libraries(rawdraw_pico
		my_lua_lib
		)

	target_include_directories(rawdraw_pico PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}
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

	file(GLOB ALL_REGRESSION_FILES CONFIGURE_DEPENDS tests/regression/*.p8 scripts/to_c.py)
	add_custom_command(
		OUTPUT ${CMAKE_SOURCE_DIR}/tests/regression_static_game_data.h
		COMMAND python3 scripts/to_c.py --luac ${luac} --cart-prefix regression tests/regression > ${CMAKE_SOURCE_DIR}/tests/regression_static_game_data.h
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		DEPENDS ${ALL_REGRESSION_FILES}
	)
	add_custom_command(
		OUTPUT ${CMAKE_SOURCE_DIR}/tests/test_static_game_data.h
		COMMAND python3 scripts/to_c.py --luac ${luac} --cart-prefix t_ tests/carts > ${CMAKE_SOURCE_DIR}/tests/test_static_game_data.h
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

		add_executable(${EXECUTABLE_NAME} src/generated/static_game_data.h tests/test_static_game_data.h ${testfile})
		target_link_libraries(${EXECUTABLE_NAME} my_lua_lib)
		add_test(NAME ${EXECUTABLE_NAME} COMMAND ${EXECUTABLE_NAME})
		target_compile_options(${EXECUTABLE_NAME} PRIVATE ${test_compile_options})
		target_include_directories(${EXECUTABLE_NAME} PUBLIC
			${CMAKE_CURRENT_SOURCE_DIR}
		)
		if(APPLE)
			add_custom_command(TARGET ${EXECUTABLE_NAME} POST_BUILD COMMAND codesign -s - ${EXECUTABLE_NAME})
		endif()
	endforeach(testfile ${TEST_SOURCES})

	# test regression
	add_executable(test_regression src/generated/static_game_data.h tests/regression_static_game_data.h tests/test_lua_regression.cpp)
	target_link_libraries(test_regression my_lua_lib)
	add_test(NAME test_regression COMMAND test_regression)
	target_compile_options(test_regression PRIVATE ${test_compile_options})

	include_directories(${CMAKE_CURRENT_SOURCE_DIR} lua 
		)

	add_compile_options(
		-g3
		-fsingle-precision-constant
		)
endif()
