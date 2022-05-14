#include "freertos/queue.h"
//#include "st7789.c"
#include "ili9340.c"
#include "esp_attr.h"
#include "driver/i2s.h"
#include "driver/adc.h"
#include "driver/dac.h"
#include "data.h"
#include "engine.c"


static const i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX | I2S_MODE_DAC_BUILT_IN),
    .sample_rate = SAMPLE_RATE,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT, /* the DAC module will only take the 8bits from MSB */
    //.bits_per_sample = I2S_BITS_PER_SAMPLE_8BIT, /* the DAC module will only take the 8bits from MSB */
    .channel_format = I2S_CHANNEL_FMT_ONLY_RIGHT,
    .communication_format = I2S_COMM_FORMAT_STAND_MSB,
    .intr_alloc_flags = 0, // default interrupt priority
    .dma_desc_num = 6,
    .dma_frame_num = 1024,
    .use_apll = false // > 16MHz
};

static uint8_t backbuffer[CONFIG_WIDTH*CONFIG_HEIGHT*2];
static QueueHandle_t q;
static QueueHandle_t i2s_event_queue;
uint8_t FLAG = 1;
// static uint16_t backbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

//GPIO34-39 can only be set as input mode and do not have software-enabled pullup or pulldown functions.
const gpio_num_t GPIO_LEFT  = (gpio_num_t)13;
const gpio_num_t GPIO_RIGHT = (gpio_num_t)12;
const gpio_num_t GPIO_UP    = (gpio_num_t)27;
const gpio_num_t GPIO_A     = (gpio_num_t)32;
const gpio_num_t GPIO_B     = (gpio_num_t)33;

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
void i2sTask(void*) {
    uint8_t cnt = 0;
    while (true) {
        i2s_event_t event;
        // Wait indefinitely for a new message in the queue
        if (xQueueReceive(i2s_event_queue, &event, portMAX_DELAY) == pdTRUE) {
            if (event.type == I2S_EVENT_TX_DONE) {
                if(++cnt == 7) {
                    i2s_zero_dma_buffer(I2S_NUM_0);
                    cnt=0;
                }
            }
        }
    }
}


bool init_audio() {
    dac_output_enable(DAC_CHANNEL_1);
    dac_output_voltage(DAC_CHANNEL_1, 50);

    i2s_driver_install(I2S_NUM_0, &i2s_config, 4, &i2s_event_queue);   //install and start i2s driver
    i2s_zero_dma_buffer(I2S_NUM_0);
    i2s_set_pin(I2S_NUM_0, NULL); //for internal DAC, this will enable both of the internal channels
    i2s_set_dac_mode(I2S_DAC_CHANNEL_RIGHT_EN); // gpio 25
    xTaskCreate(i2sTask, "I2Sout", 4096, NULL, 1, NULL);


    return true;
}
bool init_video() {
    spi_master_init(&dev, (gpio_num_t)CONFIG_MOSI_GPIO, (gpio_num_t)CONFIG_SCLK_GPIO, (gpio_num_t)CONFIG_CS_GPIO, (gpio_num_t)CONFIG_DC_GPIO, (gpio_num_t)CONFIG_RESET_GPIO, (gpio_num_t)CONFIG_BL_GPIO);
    lcdInit(&dev, 0x7735, CONFIG_WIDTH, CONFIG_HEIGHT, 0, 0);

    gpio_config_t c = {
        .pin_bit_mask = (1ULL << GPIO_LEFT) | (1ULL << GPIO_RIGHT) | (1ULL << GPIO_A) | (1ULL << GPIO_B) | (1ULL << GPIO_UP),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_ENABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&c);

    return true;
}

bool handle_input() {
    int up = gpio_get_level(GPIO_UP);
    int left = gpio_get_level(GPIO_LEFT);
    int right = gpio_get_level(GPIO_RIGHT);
    int a = gpio_get_level(GPIO_A);
    int b = gpio_get_level(GPIO_B);
    // printf("left %d, right %d, a %d\n", left, right, a);
    buttons[0] = left == 1;
    buttons[1] = right == 1;
    buttons[2] = up == 1;
    buttons[4] = a == 1;
    buttons[5] = b == 1;

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
    //return (esp_timer_get_time()) & 0xFFFFFFFF;
}

void play_sfx_buffer(){
    uint32_t bytesOut;
    i2s_write(I2S_NUM_0, audiobuf, 6*1024, &bytesOut, 100);
    printf("%d Bytes written\n", bytesOut);
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
