set(srcs "hello_world_main.cpp" "st7789.c" "st7789.h" "../static_game_data.h")
idf_component_register(SRCS ${srcs}
        INCLUDE_DIRS "lua" ".."
        REQUIRES esp32 fatfs esp_hw_support log vfs)

add_subdirectory(lua)
target_link_libraries(${COMPONENT_LIB} PUBLIC my_lua_lib)
