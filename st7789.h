#include "hardware/spi.h"

// ST7789 Commands
const uint8_t ST7789_SWRESET = 0x01;
const uint8_t ST7789_SLPIN = 0x10;
const uint8_t ST7789_SLPOUT = 0x11;
const uint8_t ST7789_NORON = 0x13;
const uint8_t ST7789_INVOFF = 0x20;
const uint8_t ST7789_INVON = 0x21;
const uint8_t ST7789_DISPON = 0x29;
const uint8_t ST7789_CASET = 0x2A;
const uint8_t ST7789_RASET = 0x2B;
const uint8_t ST7789_RAMWR = 0x2C;
const uint8_t ST7789_RAMRD = 0x2E;
const uint8_t ST7789_TEON = 0x35;
const uint8_t ST7789_MADCTL = 0x36;
const uint8_t ST7789_COLMOD = 0x3A;


// Color Modes
const uint8_t COLOR_MODE_65K = 0x50;
const uint8_t COLOR_MODE_262K = 0x60;
const uint8_t COLOR_MODE_12BIT = 0x03;
const uint8_t COLOR_MODE_16BIT = 0x05;
const uint8_t COLOR_MODE_18BIT = 0x06;
const uint8_t COLOR_MODE_16M = 0x07;

// Display Rendering controls?
const uint8_t ST7789_MADCTL_MY = 0x80;
const uint8_t ST7789_MADCTL_MX = 0x40;
const uint8_t ST7789_MADCTL_MV = 0x20;
const uint8_t ST7789_MADCTL_ML = 0x10;
const uint8_t ST7789_MADCTL_BGR = 0x08;
const uint8_t ST7789_MADCTL_MH = 0x04;
const uint8_t ST7789_MADCTL_RGB = 0x00;

/**
 * A driver for ST7789 screens. Supports both boards that feature the CS pin and boards that don't.
class St7789 {
private:
    spi_inst *spi;
    uint8_t width;
    uint8_t height;
    int8_t pin_reset;
    int8_t pin_dc;
    int8_t pin_sck;
    int8_t pin_mosi;
    int8_t pin_cs;
    int8_t pin_miso;
    uint16_t *frame_buffer;
    uint32_t spi_baudrate = 64 * 1024 * 1024;
    void send_command(uint8_t command, uint len, uint8_t *data);
    void send_command(uint8_t command, uint8_t data);
    void send_command(uint8_t command);
    void init_pins();
    void hard_reset();
    void soft_reset();
    void sleep_mode(bool value);
    void set_invert_mode(bool invert);
    void set_color_mode(uint8_t mode);
public:
    /**
     * Creates an instance of the St7789 driver.
     *
     * @param width screen width.
     * @param height screen height.
     * @param frame_buffer an uint16_t buffer with size width * height.
     * @param spi the SPI device to use.
     * @param pin_dc the Data Control (DC) pin.
     * @param pin_reset the Reset (RES) pin. Use -1 for boards that don't have a reset pin.
     * @param pin_sck the Clock (SCK / SCL) pin.
     * @param pin_mosi the data (MOSI / SDA) pin.
     * @param pin_cs the CS pin. Use -1 for boards that don't have a reset pin.
     * @param pin_miso the MISO pin. Unused by the code. Can be set to -1.
     *
    St7789(
            uint8_t width,
            uint8_t height,
            uint16_t *frame_buffer,
            spi_inst *spi,
            int8_t pin_dc,
            int8_t pin_reset,
            int8_t pin_sck,
            int8_t pin_mosi,
            int8_t pin_cs = -1,
            int8_t pin_miso = -1);

    /**
     * Initializes the pins and the screen.
     *
    void init();

    /**
     * Updates the screen with the content in the buffer.
     *
    void update();

    /**
     * Creates an instance of the St7789 driver using the default values for the Pimoroni Pico Display.
     * @param buffer an uint16_t buffer with size of 240 * 135.
     * @return an instance of the St7789 driver.
     *
    static St7789 pimoroni_display(uint16_t *buffer) {
        return St7789(
                240,
                135,
                buffer,
                spi0,
                16,
                -1,
                18,
                19,
                17,
                -1);
    }
};
 */
