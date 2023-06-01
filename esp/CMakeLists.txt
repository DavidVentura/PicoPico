set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(srcs "hello_world_main.cpp" "st7789.c" "st7789.h" "../src/generated/static_game_data.h")
idf_component_register(SRCS ${srcs}
        INCLUDE_DIRS "lua" ".." "../src"
        REQUIRES esp_timer vfs driver esp_hw_support log spi_flash)

add_subdirectory(lua)
target_link_libraries(${COMPONENT_LIB} PUBLIC my_lua_lib)
