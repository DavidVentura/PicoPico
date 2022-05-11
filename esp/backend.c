#include "freertos/queue.h"
//#include "st7789.c"
#include "ili9340.c"
#include "esp_attr.h"
#include "driver/adc.h"
#include "data.h"
#include "engine.c"

static uint8_t backbuffer[CONFIG_WIDTH*CONFIG_HEIGHT*2];
static QueueHandle_t q;
uint8_t FLAG = 1;
// static uint16_t backbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

const gpio_num_t GPIO_LEFT  = (gpio_num_t)34;
const gpio_num_t GPIO_RIGHT = (gpio_num_t)35;
const gpio_num_t GPIO_A     = (gpio_num_t)32;

static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p);
void put_buffer();

void video_close(){
}

void gfx_flip() {
    // memcpy(backbuffer, frontbuffer, sizeof(frontbuffer));
    // Flip endianness
    // put_buffer();

    for(uint8_t y=0; y<SCREEN_HEIGHT; y++)
        for(uint8_t x=0; x<SCREEN_WIDTH; x++) {
            uint16_t p = frontbuffer[y*SCREEN_WIDTH+x];
            backbuffer[y*SCREEN_WIDTH*2+x*2  ] = (p >> 8);
            backbuffer[y*SCREEN_WIDTH*2+x*2+1] = p & 0xFF;
        }
    xQueueSendToBack(q, (void*)&FLAG, (TickType_t) 0);
}

void delay(uint16_t ms) {
    vTaskDelay(ms / portTICK_PERIOD_MS);
}

bool init_video() {
    spi_master_init(&dev, (gpio_num_t)CONFIG_MOSI_GPIO, (gpio_num_t)CONFIG_SCLK_GPIO, (gpio_num_t)CONFIG_CS_GPIO, (gpio_num_t)CONFIG_DC_GPIO, (gpio_num_t)CONFIG_RESET_GPIO, (gpio_num_t)CONFIG_BL_GPIO);
    lcdInit(&dev, 0x7735, CONFIG_WIDTH, CONFIG_HEIGHT, 0, 0);

    gpio_config_t c = {
        .pin_bit_mask = (1ULL << GPIO_LEFT) | (1ULL << GPIO_RIGHT) | (1ULL << GPIO_A),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_ENABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&c);

    return true;
}

bool handle_input() {
    int left = gpio_get_level(GPIO_LEFT);
    int right = gpio_get_level(GPIO_RIGHT);
    int a = gpio_get_level(GPIO_A);
    // printf("left %d, right %d, a %d\n", left, right, a);
    buttons[0] = left == 1;
    buttons[1] = right == 1;
    buttons[4] = a == 1;

    //int xraw = adc1_get_raw(ADC1_CHANNEL_4);
    //int yraw = adc1_get_raw(ADC1_CHANNEL_5);

    //printf("xraw %d, yraw %d\n", xraw, yraw);
    /*
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
    */
    // TODO
    return false;
}

uint32_t now(){
    return (esp_timer_get_time()/1000) & 0xFFFFFFFF;
}

void put_buffer(void *pvParameters)
{
    uint8_t buf[1];
    while (true) {
        xQueueReceive(q, &buf, portMAX_DELAY);

        uint64_t frame_start_time = now();

        send_buffer(&dev, backbuffer, sizeof(backbuffer));

        uint64_t frame_end_time = now();
        int delta = (frame_end_time - frame_start_time);

        //printf("Copying to SPI took: %d\n", delta);
    }
}
