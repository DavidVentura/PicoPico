#include "pico/stdlib.h"
#include "st7789.c"
#include "hardware/pwm.h"
#include "pico/bootrom.h"
#include "pico/multicore.h"
#include "hardware/adc.h"


#define READY_TO_RENDER_FLAG 123
#define A_BUTTON_GPIO 15
#define B_BUTTON_GPIO 17
#define UP_BUTTON_GPIO 2
#define DOWN_BUTTON_GPIO 18
#define LEFT_BUTTON_GPIO 16
#define RIGHT_BUTTON_GPIO 20
#define X_AXIS_GPIO 26
#define Y_AXIS_GPIO 27
#define X_AXIS_ADC 0
#define Y_AXIS_ADC 1
#define MASK_GPIO (1 << A_BUTTON_GPIO) | (1<<B_BUTTON_GPIO) | (1<<UP_BUTTON_GPIO) | (1<<DOWN_BUTTON_GPIO) | (1<<LEFT_BUTTON_GPIO) | (1<<RIGHT_BUTTON_GPIO)

static uint16_t backbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

void put_buffer();

void video_close(){
}

void gfx_flip() {
    // memcpy(backbuffer, frontbuffer, sizeof(frontbuffer));
    // Flip endianness
    for(uint8_t y=0; y<SCREEN_HEIGHT; y++)
        for(uint8_t x=0; x<SCREEN_WIDTH; x++) {
            uint16_t p = frontbuffer[y*SCREEN_WIDTH+x];
            backbuffer[y*SCREEN_WIDTH+x] = (p >> 8) | (p << 8);
        }
        

    // memcpy(backbuffer, frontbuffer, sizeof(frontbuffer));
    multicore_fifo_push_blocking(READY_TO_RENDER_FLAG);
}

void delay(uint16_t ms) {
    sleep_ms(ms);
}

void init_gpio() {
    stdio_init_all();
    adc_init();
    adc_gpio_init(X_AXIS_GPIO);
    adc_gpio_init(Y_AXIS_GPIO);

    while (uart_is_readable(uart0)) {
        uart_getc(uart0);
    }
    // Overclock from 130MHz to 266MHz
    // set_sys_clock_khz(300000, true);
    set_sys_clock_khz(266000, true);

    //gpio_init_mask(MASK_GPIO);
    gpio_init(A_BUTTON_GPIO);
    gpio_init(B_BUTTON_GPIO);
    gpio_pull_up(A_BUTTON_GPIO);
    gpio_pull_up(B_BUTTON_GPIO);
    //gpio_pull_up(UP_BUTTON_GPIO);
    //gpio_pull_up(DOWN_BUTTON_GPIO);
    //gpio_pull_up(LEFT_BUTTON_GPIO);
    //gpio_pull_up(RIGHT_BUTTON_GPIO);

    // BackLight PWM (125MHz / 65536 / 4 = 476.84 Hz)
    //gpio_set_function(PIN_LCD_BLK, GPIO_FUNC_PWM);
    uint slice_num = pwm_gpio_to_slice_num(PICO_DEFAULT_LED_PIN);
    pwm_config config = pwm_get_default_config();
    pwm_config_set_clkdiv(&config, 4.f);
    pwm_init(slice_num, &config, true);
    int bl_val = 255;
    // Square bl_val to make brightness appear more linear
    //pwm_set_gpio_level(PIN_LCD_BLK, bl_val * bl_val);

    lcd_init();
    //LCD_SetRotation(3);
    //LCD_Clear(RED);
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

    adc_select_input(X_AXIS_ADC);
    uint16_t xval = adc_read();

    adc_select_input(Y_AXIS_ADC);
    uint16_t yval = adc_read();

    // printf("X: %d, Y: %d\n", xval, yval);
    // range is 0-4k
    buttons[0] = (xval < 500);
    buttons[1] = (xval > 3500);
    buttons[2] = (yval < 500);
    buttons[3] = (yval > 3500);
    buttons[4] = !gpio_get(A_BUTTON_GPIO);
    buttons[5] = !gpio_get(B_BUTTON_GPIO);
    return false;
}

uint32_t now(){
    return to_ms_since_boot(get_absolute_time());
}

void put_buffer()
{
    while (true) {
        //TODO: investigate how to do DMA?
        multicore_fifo_pop_blocking();

        uint64_t frame_start_time = now();

        send_buffer(ST7789_RAMWR, sizeof(backbuffer), (uint8_t *) backbuffer);
        uint64_t frame_end_time = now();
        int delta = (frame_end_time - frame_start_time);

        // printf("Copying to SPI took: %d\n", delta);
    }
}

bool init_audio() {
    return true;
}
