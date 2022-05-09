#include "freertos/queue.h"
#include "st7789.c"
#include "esp_attr.h"

static DRAM_ATTR uint16_t frontbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];
static uint8_t backbuffer[CONFIG_WIDTH*CONFIG_HEIGHT*2];
static QueueHandle_t q;
uint8_t FLAG = 1;
// static uint16_t backbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p);
void put_buffer();

uint16_t get_pixel(uint8_t x, uint8_t y) {
	// FIXME: this is incredibly broken
	return frontbuffer[x+y*SCREEN_WIDTH];
}

void gfx_circlefill(int32_t x, int32_t y, int32_t radius, uint8_t* color){
    if(x < 0 || y < 0 || x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) return;
    for (int w = 0; w < radius * 2; w++)
    {
        int dx = radius - w; // horizontal offset
        if((x + dx) < 0) continue;
        if((x + dx) >= SCREEN_WIDTH) break;
        for (int h = 0; h < radius * 2; h++)
        {
            int dy = radius - h; // vertical offset
            if((y + dy) >= SCREEN_HEIGHT) break;
            if((y + dy) < 0) continue;
            if ((dx*dx + dy*dy) <= (radius * radius))
            {
                put_pixel(x + dx, y + dy, color);
            }
        }
    }
}
void gfx_circle(int32_t centreX, int32_t centreY, int32_t radius, uint8_t* color){
}
void gfx_line(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, const uint8_t* color) {
	for(uint16_t x=x0; x<x1-x0; x++)
		for(uint16_t y=y0; y<y1-y0; y++)
			put_pixel(x, y, color);
}

// callers have to ensure this is not called with x > SCREEN_WIDTH or y > SCREEN_HEIGHT
static inline void put_pixel(uint8_t x, uint8_t y, const uint8_t* p){
    const uint16_t color = ((p[0] >> 3) << 11) | ((p[1] >> 2) << 5) | (p[2] >> 3);
    frontbuffer[(y*SCREEN_WIDTH+x)  ] = color;

    //frontbuffer[2*(y*SCREEN_WIDTH+x)  ] = color >> 8;
    //frontbuffer[2*(y*SCREEN_WIDTH+x)+1] = color & 0xF;
}
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

void gfx_cls(uint8_t* p) {
    const uint16_t val = ((p[0] >> 3) << 11) | ((p[1] >> 2) << 5) | (p[2] >> 3);
    memset(frontbuffer, val, sizeof(frontbuffer));
}

void gfx_rect(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const uint8_t* color) {
    for(uint16_t y=y0; y<=y2; y++)
        for(uint8_t x=x0; x<=x2; x++)
            if ((y==y0) || (y==y2) || (x==x0) || (x==x2))
                put_pixel(x, y, color);
}

void gfx_rectfill(uint16_t x0, uint16_t y0, uint16_t x2, uint16_t y2, const uint8_t* color) {
    for(uint16_t y=y0; y<=y2; y++)
        for(uint16_t x=x0; x<=x2; x++)
            put_pixel(x, y, color);
}

bool init_video() {
    spi_master_init(&dev, (gpio_num_t)CONFIG_MOSI_GPIO, (gpio_num_t)CONFIG_SCLK_GPIO, (gpio_num_t)CONFIG_CS_GPIO, (gpio_num_t)CONFIG_DC_GPIO, (gpio_num_t)CONFIG_RESET_GPIO, (gpio_num_t)CONFIG_BL_GPIO);
    lcdInit(&dev, CONFIG_WIDTH, CONFIG_HEIGHT, CONFIG_OFFSETX, CONFIG_OFFSETY);


    // 32 x (ch4) 
    // 33 y (ch5)
    // 35 btn1 (digital)
    //adc1_config_width((adc_bits_width_t)ADC_WIDTH_BIT_DEFAULT);
    //adc1_config_channel_atten(ADC1_CHANNEL_4, ADC_ATTEN_DB_11);
    //adc1_config_channel_atten(ADC1_CHANNEL_5, ADC_ATTEN_DB_11);
    // docs say attenuation of 11 = 150-2450mV range

    return true;
}

bool handle_input() {
//    int xraw = adc1_get_raw(ADC1_CHANNEL_4);
//    int yraw = adc1_get_raw(ADC1_CHANNEL_5);
//
//    printf("xraw %d, yraw %d\n", xraw, yraw);
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
