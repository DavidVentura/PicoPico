#include <string.h>
#include "pico/stdlib.h"
#include "st7735_80x160/my_lcd.h"
#include "hardware/pwm.h"
#include "pico/bootrom.h"
#include "pico/multicore.h"


#define READY_TO_RENDER_FLAG 123
#define A_BUTTON_GPIO 15
#define B_BUTTON_GPIO 17
#define UP_BUTTON_GPIO 2
#define DOWN_BUTTON_GPIO 18
#define LEFT_BUTTON_GPIO 16
#define RIGHT_BUTTON_GPIO 20
#define MASK_GPIO (1 << A_BUTTON_GPIO) | (1<<B_BUTTON_GPIO) | (1<<UP_BUTTON_GPIO) | (1<<DOWN_BUTTON_GPIO) | (1<<LEFT_BUTTON_GPIO) | (1<<RIGHT_BUTTON_GPIO)

static uint8_t frontbuffer[SCREEN_WIDTH*SCREEN_HEIGHT*2];
static uint8_t backbuffer[SCREEN_WIDTH*SCREEN_HEIGHT*2];

void put_buffer();

uint16_t get_pixel(uint8_t x, uint8_t y) {
	// FIXME: this is incredibly broken
	return frontbuffer[x+y*SCREEN_WIDTH];
}

void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color){
}
void gfx_line(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, const uint8_t* color) {
	for(uint16_t x=x0; x<x1-x0; x++)
		for(uint16_t y=y0; y<y1-y0; y++)
			put_pixel(x, y, color);
}

// callers have to ensure this is not called with x > SCREEN_WIDTH or y > SCREEN_HEIGHT
static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p){
    if (y >= SCREEN_HEIGHT) {
            return;
    }
    const uint16_t color = ((p[0] >> 3) << 11) | ((p[1] >> 2) << 5) | (p[2] >> 3);
    // frontbuffer[(y*160+x)  ] = color;
    frontbuffer[2*(y*SCREEN_WIDTH+x)  ] = color >> 8;
    frontbuffer[2*(y*SCREEN_WIDTH+x)+1] = color & 0xF;
}
void video_close(){
}

void gfx_flip() {
    memcpy(backbuffer, frontbuffer, sizeof(frontbuffer));
    multicore_fifo_push_blocking(READY_TO_RENDER_FLAG);
}

void delay(uint16_t ms) {
    sleep_ms(ms);
}

void gfx_cls(uint8_t* color) {
    for(uint8_t x=0; x<SCREEN_WIDTH; x++)
        for(uint8_t y=0; y<SCREEN_HEIGHT; y++){
	    put_pixel(x, y, color);
    }
    // FIXME: put back to memset when front/backbuffers are uint16_t
    // but that needs SPI code to work with write16
    // memset(frontbuffer, val, sizeof(frontbuffer));
}

void gfx_rect(uint16_t x0, uint16_t y0, uint16_t w, uint16_t h, const uint8_t* color) {
    for(uint16_t x=x0; x<=x0+w; x++)
    for(uint16_t y=y0; y<=y0+w; y++){
	    if (x==x0 || x == (x0+w) || y==y0 || y == y0+w)
	    put_pixel(x, y, color);
    }
}

void gfx_rectfill(uint16_t x, uint16_t y, uint16_t w, uint16_t h, const uint8_t* color) {
}

void init_gpio() {
    stdio_init_all();

    while (uart_is_readable(uart0)) {
        uart_getc(uart0);
    }
    // Overclock from 130MHz to 266MHz
    // set_sys_clock_khz(266000, true);

    gpio_init_mask(MASK_GPIO);
    gpio_pull_up(A_BUTTON_GPIO);
    gpio_pull_up(B_BUTTON_GPIO);
    gpio_pull_up(UP_BUTTON_GPIO);
    gpio_pull_up(DOWN_BUTTON_GPIO);
    gpio_pull_up(LEFT_BUTTON_GPIO);
    gpio_pull_up(RIGHT_BUTTON_GPIO);

    // BackLight PWM (125MHz / 65536 / 4 = 476.84 Hz)
    gpio_set_function(PIN_LCD_BLK, GPIO_FUNC_PWM);
    uint slice_num = pwm_gpio_to_slice_num(PICO_DEFAULT_LED_PIN);
    pwm_config config = pwm_get_default_config();
    pwm_config_set_clkdiv(&config, 4.f);
    pwm_init(slice_num, &config, true);
    int bl_val = 255;
    // Square bl_val to make brightness appear more linear
    pwm_set_gpio_level(PIN_LCD_BLK, bl_val * bl_val);

    LCD_Init();
    LCD_SetRotation(3);
    LCD_Clear(RED);
}
bool init_video() {
    init_gpio();
    multicore_launch_core1(put_buffer);

    printf("\n");
    printf("========================\n");
    printf("== pico_st7735_80x160 ==\n");
    printf("========================\n");
    return true;
}

bool handle_input() {
    int c = getchar_timeout_us(0);
    switch (c) {
	case 'r':
	    reset_usb_boot(0, 0);
	    break;
    }

    buttons[0] = !gpio_get(LEFT_BUTTON_GPIO);
    buttons[1] = !gpio_get(RIGHT_BUTTON_GPIO);
    buttons[2] = !gpio_get(UP_BUTTON_GPIO);
    buttons[3] = !gpio_get(DOWN_BUTTON_GPIO);
    buttons[4] = !gpio_get(A_BUTTON_GPIO);
    buttons[5] = !gpio_get(B_BUTTON_GPIO);
    return false;
}

uint64_t now(){
    return to_ms_since_boot(get_absolute_time());
}

void put_buffer()
{
    while (true) {
	//TODO: investigate how to do DMA?
	multicore_fifo_pop_blocking();
	// uint64_t frame_start_time = now();
	u16 x,y;
	u16 h = LCD_H();
	u16 w = LCD_W();
	LCD_Address_Set(0,0,w-1,h-1);
	OLED_DC_Set();
	OLED_CS_Clr();
	spi_write_blocking(SPI_INST, backbuffer, sizeof(backbuffer));
	OLED_CS_Set();
	// uint64_t frame_end_time = now();
	// int delta = (frame_end_time - frame_start_time);
	// printf("Copying to SPI took: %d\n", delta);
    }
}
