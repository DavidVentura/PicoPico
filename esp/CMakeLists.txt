set(srcs "hello_world_main.c")
idf_component_register(SRCS ${srcs}
	       INCLUDE_DIRS "../lua" "."
	       REQUIRES esp32 fatfs esp_hw_support log vfs)
