#include "hardware/clocks.h"
#include "pico/stdlib.h"
#include "st7789.h"

#define SPI_INST    spi0
#define PIN_CS      -1
#define PIN_DC      16
#define PIN_MISO    -1
#define PIN_SCL     18
#define PIN_SDA     19
#define PIN_RESET   20
#define PIN_LCD_BLK 21
#define SPI_CLK_FREQ    (62.5 * MHZ)


void send_buffer(uint8_t command, uint len, uint8_t *data) {
    if (PIN_CS != -1) {
        gpio_put(PIN_CS, 0);
    }

    gpio_put(PIN_DC, 0);
    spi_write_blocking(SPI_INST, &command, 1);

    if (data) {
        gpio_put(PIN_DC, 1);
        spi_write_blocking(SPI_INST, data, len);
    }

    if (PIN_CS != -1) {
        gpio_put(PIN_CS, 1);
    }
}

void send_byte(uint8_t command, uint8_t data) {
    send_buffer(command, 1, &data);
}

void send_command(uint8_t command) {
    send_buffer(command, 0, nullptr);
}

void sleep_mode(bool value) {
    if (value) {
        send_command(ST7789_SLPIN);
    } else {
        send_command(ST7789_SLPOUT);
    }
}

void set_invert_mode(bool invert) {
    if (invert) {
        send_command(ST7789_INVON);
    } else {
        send_command(ST7789_INVOFF);
    }
}

void set_color_mode(uint8_t mode) {
    send_byte(ST7789_COLMOD, mode);
}

void hard_reset() {
    gpio_put(PIN_RESET, 1);
    sleep_ms(50);
    gpio_put(PIN_RESET, 0);
    sleep_ms(50);
    gpio_put(PIN_RESET, 1);
    sleep_ms(150);
}

void soft_reset() {
    send_command(ST7789_SWRESET);
    sleep_ms(150);
}


void lcd_init_pins() {
    gpio_set_function(PIN_DC, GPIO_FUNC_SIO); // Same as "gpio_init(PIN_DC);
    gpio_set_dir(PIN_DC, GPIO_OUT);

    if (PIN_RESET != -1) {
        gpio_set_function(PIN_RESET, GPIO_FUNC_SIO); // gpio_init(PIN_RESET);
        gpio_set_dir(PIN_RESET, GPIO_OUT);
    }

    if (PIN_CS != -1) {
        gpio_set_function(PIN_CS, GPIO_FUNC_SIO);
        gpio_set_dir(PIN_CS, GPIO_OUT);
    }

    spi_init(SPI_INST, SPI_CLK_FREQ);
    gpio_set_function(PIN_SCL, GPIO_FUNC_SPI);
    gpio_set_function(PIN_SDA, GPIO_FUNC_SPI);

    if(PIN_MISO != -1) {
        gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
    }

    // Pimoroni's pico use CS, with the default config. The cheap screen doesn't have CS and needs to require setting
    // polarity to 1.
    if (PIN_CS == -1) {
        spi_set_format(SPI_INST, 8, SPI_CPOL_1, SPI_CPHA_0, SPI_MSB_FIRST);
    }
}

void lcd_init() {
    lcd_init_pins();

    if (PIN_RESET != -1) {
        hard_reset();
    }
    soft_reset();
    sleep_mode(false);
    sleep_ms(50);

    //if(SCREEN_WIDTH == 240 && SCREEN_HEIGHT == 240) {
    //if(SCREEN_WIDTH == 128 && SCREEN_HEIGHT == 128) {
    //send_byte(ST7789_MADCTL,0x04);  // row/column addressing order - rgb pixel order
    send_byte(ST7789_MADCTL,0x04);  // row/column addressing order - rgb pixel order
    send_byte(ST7789_TEON, 0x00);  // enable frame sync signal if used
    //}

    /*
       if(SCREEN_WIDTH == 240 && SCREEN_HEIGHT == 135) {
       send_byte(ST7789_MADCTL,0x70);
       }
       */

    set_color_mode(COLOR_MODE_16BIT);
    //set_color_mode(COLOR_MODE_65K);

    set_invert_mode(true);
    sleep_ms(10);

    send_command(ST7789_NORON);
    sleep_ms(10);

    send_command(ST7789_DISPON);
    // setup correct addressing window
    if(false) {
        send_buffer(ST7789_CASET, 4, new uint8_t[4]{0x00, 0x00, 0x00, 239});  // 0 .. 239 columns
        send_buffer(ST7789_RASET, 4, new uint8_t[4]{0x00, 0x00, 0x00, 239});  // 0 .. 239 rows
    } else {

        /*
           uint8_t zero = 0;
           for(uint8_t y=0; y<240; y++)
           for(uint8_t x=0; x<240; x++) {
           send_buffer(ST7789_RAMWR, 1, &zero);
           }
           */
        // 240 px wide; 128 px = screen
        // 112 leftover, = 56 to center

        send_buffer(ST7789_CASET, 4, new uint8_t[4]{0x00, 56, 0x00, 56+SCREEN_WIDTH-1});  // 0 .. 239 columns
        send_buffer(ST7789_RASET, 4, new uint8_t[4]{0x00, 56, 0x00, 56+SCREEN_HEIGHT-1});  // 0 .. 239 rows
    }
    /*
       if(SCREEN_WIDTH == 240 && SCREEN_HEIGHT == 135) {
       send_buffer(ST7789_RASET, 4, new uint8_t[4]{0x00, 0x35, 0x00, 0xbb}); // 53 .. 187 (135 rows)
       send_buffer(ST7789_CASET, 4, new uint8_t[4]{0x00, 0x28, 0x01, 0x17}); // 40 .. 279 (240 columns)
       }
       */
    // Rotation 0
    uint8_t madctl = ST7789_MADCTL_MX | ST7789_MADCTL_MY | ST7789_MADCTL_RGB;
    // Rotation 1
    madctl = ST7789_MADCTL_MY | ST7789_MADCTL_MV | ST7789_MADCTL_RGB;
    // Rotation 2
    madctl = ST7789_MADCTL_RGB;
    // Rotation 3
    madctl = ST7789_MADCTL_MX | ST7789_MADCTL_MV | ST7789_MADCTL_RGB;
    send_byte(ST7789_MADCTL, madctl);
    // send_byte(0xC0 | (1<<3));
    //send_byte(0x70 | (1<<3));
    //send_byte(0xA0 | (1<<3));
}
