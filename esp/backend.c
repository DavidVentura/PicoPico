#include "freertos/queue.h"
//#include "st7789.c"
#include "ili9340.c"
#include "esp_attr.h"
#include "driver/i2s.h"
#include "driver/adc.h"
#include "data.h"
#include "engine.c"
#include "esp_timer.h"
#include "esp_wifi.h"
#include <time.h>

static const i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
    .sample_rate = SAMPLE_RATE>>1,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT, /* the DAC module will only take the 8bits from MSB */
    .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
    .communication_format = I2S_COMM_FORMAT_STAND_I2S,//(i2s_comm_format_t)(I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB),
    .intr_alloc_flags = 0, // default interrupt priority
    .dma_buf_count = SAMPLES_PER_BUFFER, // always want >1; having only one means interruptions in audio
    // changed on the newer sdk version
    //.dma_desc_num = SAMPLES_PER_BUFFER, // always want >1; having only one means interruptions in audio
    //.dma_frame_num = SAMPLES_PER_DURATION, // length at most = 1024
    .dma_buf_len = SAMPLES_PER_DURATION, // length at most = 1024
    .use_apll = false, // > 16MHz
    .tx_desc_auto_clear = false,
};
static const i2s_pin_config_t i2s_pin_config = {
    .bck_io_num = 27, // BCLK "Bit clock line"
    .ws_io_num = 26, // LRC also "LRCLK" or WS
    .data_out_num = 25, // DIN !! not SD (which is SHUTDOWN)
    .data_in_num = I2S_PIN_NO_CHANGE
};

static uint8_t backbuffer[CONFIG_WIDTH*CONFIG_HEIGHT*2];
static QueueHandle_t q;
static QueueHandle_t i2s_event_queue;
uint8_t FLAG = 1;
uint32_t bytesTX = 0;
// static uint16_t backbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

//GPIO34-39 can only be set as input mode and do not have software-enabled pullup or pulldown functions.
const gpio_num_t GPIO_LEFT  = (gpio_num_t)13;
const gpio_num_t GPIO_RIGHT = (gpio_num_t)12;
const gpio_num_t GPIO_UP    = (gpio_num_t)34;
const gpio_num_t GPIO_A     = (gpio_num_t)32;
const gpio_num_t GPIO_B     = (gpio_num_t)33;
uint8_t buttons_prev[6] =  {0, 0, 0, 0, 0, 0};

//static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p);
void put_buffer();

void video_close(){
}

void gfx_flip() {
    // memcpy(backbuffer, frontbuffer, sizeof(frontbuffer));
    // Flip endianness
    // put_buffer();

    for(uint8_t y=0; y<SCREEN_HEIGHT; y++)
        for(uint8_t x=0; x<SCREEN_WIDTH; x++) {
            palidx_t p = get_pixel(x, y);
	    color_t c = palette[p];
            backbuffer[y*SCREEN_WIDTH*2+x*2  ] = (c >> 8);
            backbuffer[y*SCREEN_WIDTH*2+x*2+1] = c & 0xFF;
        }
    xQueueSendToBack(q, (void*)&FLAG, (TickType_t) 0);
}

void delay(uint16_t ms) {
    TickType_t ticks = ms / portTICK_PERIOD_MS;
    vTaskDelay(ticks ? ticks : 1);
}
void i2sTask(void*) {
    uint16_t samples = SAMPLES_PER_DURATION * SAMPLES_PER_BUFFER;
    uint32_t bytesOut;
    while (true) {
        i2s_event_t event;
        // Wait indefinitely for a new message in the queue
        if (xQueueReceive(i2s_event_queue, &event, portMAX_DELAY) == pdTRUE) {
            if (event.type == I2S_EVENT_TX_DONE) {
                memset(audiobuf, 0, sizeof(audiobuf));

                for(uint8_t i=0; i<4; i++)
                    fill_buffer(audiobuf, &channels[i], samples);

                i2s_write(I2S_NUM_0, audiobuf, sizeof(audiobuf), &bytesOut, 100);
            }
        }
    }
}


bool init_platform() {
    /*
    esp_bluedroid_disable();
    esp_bluedroid_deinit();
    esp_bt_controller_disable();
    esp_bt_controller_deinit();
    */
    return true;
}
bool init_audio() {

    i2s_driver_install(I2S_NUM_0, &i2s_config, 4, &i2s_event_queue);   //install and start i2s driver
    i2s_zero_dma_buffer(I2S_NUM_0);

    i2s_set_pin(I2S_NUM_0, &i2s_pin_config); //for internal DAC, this will enable both of the internal channels

    i2s_zero_dma_buffer(I2S_NUM_0);
    xTaskCreatePinnedToCore(i2sTask, "I2Sout", 4096, NULL, 1 /* prio */, NULL, 1 /* core id */);

    return true;
}

void draw_hud() {
    set_window_hud(&dev, SCREEN_WIDTH, HUD_HEIGHT);
    send_buffer(&dev, hud_buffer, sizeof(hud_buffer));
    set_window(&dev);
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

    buttons_prev[0] = buttons[0];
    buttons_prev[1] = buttons[1];
    buttons_prev[2] = buttons[2];
    buttons_prev[3] = buttons[3];
    buttons_prev[4] = buttons[4];
    buttons_prev[5] = buttons[5];

    buttons[0] = left == 1;
    buttons[1] = right == 1;
    buttons[2] = up == 1;
    buttons[3] = 0; // FIXME no down connected
    buttons[4] = a == 1;
    buttons[5] = b == 1;

    buttons_frame[0] = (buttons[0] == 1) && (buttons_prev[0] == 0);
    buttons_frame[1] = (buttons[1] == 1) && (buttons_prev[1] == 0);
    buttons_frame[2] = (buttons[2] == 1) && (buttons_prev[2] == 0);
    buttons_frame[3] = (0)               && (buttons_prev[3] == 0); // FIXME no down connected
    buttons_frame[4] = (buttons[4] == 1) && (buttons_prev[4] == 0);
    buttons_frame[5] = (buttons[5] == 1) && (buttons_prev[5] == 0);

    // TODO
    return false;
}

uint32_t now(){
    return (esp_timer_get_time()/1000) & 0xFFFFFFFF;
    //return (esp_timer_get_time()) & 0xFFFFFFFF;
}

void put_buffer(void *pvParameters)
{
    uint8_t buf[1];
    while (true) {
        xQueueReceive(q, &buf, portMAX_DELAY);

        // uint64_t frame_start_time = now();

        send_buffer(&dev, backbuffer, sizeof(backbuffer));

        // uint64_t frame_end_time = now();
        // int delta = (frame_end_time - frame_start_time);

        //printf("Copying to SPI took: %d\n", delta);
    }
}

uint8_t current_hour() {
    // 0-24h
    time_t rawtime;
    struct tm* timeinfo;

    time(&rawtime);
    timeinfo = localtime ( &rawtime );
    return timeinfo->tm_hour;
}
uint8_t current_minute() {
    // 0-60m
    time_t rawtime;
    struct tm* timeinfo;

    time(&rawtime);
    timeinfo = localtime ( &rawtime );
    return timeinfo->tm_min;
}
uint8_t wifi_strength() {
    // arbitrary 0-3 scale (limited sprites)
    // 0 = off, 1=low, 2=med, 3 = high
    wifi_ap_record_t ap;
    esp_err_t result = esp_wifi_sta_get_ap_info(&ap);
    if (result == ESP_ERR_WIFI_NOT_CONNECT || result == ESP_ERR_WIFI_CONN) {
        printf("ded wifi\n");
        return 0;
    }
    printf("rssi %d\n", ap.rssi);
    if (ap.rssi == 0) return 0; // probably bug, too good signal
    // ap.rssi is -127..0
    if (ap.rssi > -10) return 3;
    if (ap.rssi > -30) return 2;
    return 1;
}
uint8_t battery_left() {
    // arbitrary 0-3 scale
    // 0 = almost empty, 3 = full
    return 3;
}
