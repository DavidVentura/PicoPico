#include <string.h>
#include "pico/stdlib.h"
#include "st7735_80x160/my_lcd.h"
#include "hardware/pwm.h"
#include "pico/bootrom.h"

static uint8_t backbuffer[160*80*2]; // TODO: fixme, LCD size

void put_buffer();

void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color){
}
void put_pixel(uint8_t x, uint8_t y, const uint8_t* p){
    // TODO: fixme, lcd size
    const uint16_t color = ((p[0] >> 3) << 11) | ((p[1] >> 2) << 5) | (p[2] >> 3);
    backbuffer[2*(y*160+x)  ] = color >> 8;
    backbuffer[2*(y*160+x)+1] = color & 0xF;
}
void video_close(){
}
void gfx_flip() {
    put_buffer();
}
void delay(uint8_t ms) {
    sleep_ms(ms);
}
void gfx_cls() {
    memset(backbuffer, 0, sizeof(backbuffer));
    // LCD_Clear(BLACK);
}
void gfx_rectfill(uint8_t x, uint8_t y, uint8_t w, uint8_t h, const uint8_t* color) {
}
void init_gpio() {
    stdio_init_all();

    // Set the GPIO pin mux to the UART - 0 is TX, 1 is RX
    //gpio_set_function(0, GPIO_FUNC_UART);
    //gpio_set_function(1, GPIO_FUNC_UART);
    while (uart_is_readable(uart0)) {
        uart_getc(uart0);
    }

    // LED

    // BackLight PWM (125MHz / 65536 / 4 = 476.84 Hz)
    gpio_set_function(PIN_LCD_BLK, GPIO_FUNC_PWM);
    uint slice_num = pwm_gpio_to_slice_num(PICO_DEFAULT_LED_PIN);
    pwm_config config = pwm_get_default_config();
    pwm_config_set_clkdiv(&config, 4.f);
    pwm_init(slice_num, &config, true);
    int bl_val = 196;
    // Square bl_val to make brightness appear more linear
    pwm_set_gpio_level(PIN_LCD_BLK, bl_val * bl_val);

    LCD_Init();
    LCD_SetRotation(3);
    LCD_Clear(RED);
}
bool init_video() {
    init_gpio();

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
    // should quit
    return false;
}

uint64_t now(){
    return to_ms_since_boot(get_absolute_time());
}

void put_buffer()
{
    //TODO: investigate how to do DMA?
    u16 x,y;
    u16 h = LCD_H();
    u16 w = LCD_W();
    LCD_Address_Set(0,0,w-1,h-1);
    OLED_DC_Set();
    OLED_CS_Clr();
    spi_write_blocking(SPI_INST, backbuffer, sizeof(backbuffer));
    OLED_CS_Set();
}
