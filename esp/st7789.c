#include <string.h>
#include <math.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include <driver/spi_master.h>
#include <driver/gpio.h>
#include "esp_log.h"

#include "st7789.h"

#define TAG "ST7789"
#define	_DEBUG_ 0

#ifdef CONFIG_IDF_TARGET_ESP32
#define LCD_HOST HSPI_HOST
#elif defined CONFIG_IDF_TARGET_ESP32S2
#define LCD_HOST SPI2_HOST
#elif defined CONFIG_IDF_TARGET_ESP32S3
#define LCD_HOST SPI2_HOST
#elif defined CONFIG_IDF_TARGET_ESP32C3
#define LCD_HOST SPI2_HOST
#endif

//static const int SPI_Frequency = SPI_MASTER_FREQ_20M;
//static const int SPI_Frequency = SPI_MASTER_FREQ_26M;
static const int SPI_Frequency = SPI_MASTER_FREQ_40M;
// can't get more than 40 on a breadboard
//static const int SPI_Frequency = SPI_MASTER_FREQ_80M;


void spi_master_init(TFT_t * dev, gpio_num_t GPIO_MOSI, gpio_num_t GPIO_SCLK, gpio_num_t GPIO_CS, gpio_num_t GPIO_DC, gpio_num_t GPIO_RESET, gpio_num_t GPIO_BL)
{
    esp_err_t ret;

    ESP_LOGI(TAG, "GPIO_CS=%d",GPIO_CS);
    if ( GPIO_CS >= 0 ) {
        //gpio_pad_select_gpio( GPIO_CS );
        gpio_reset_pin( GPIO_CS );
        gpio_set_direction( GPIO_CS, GPIO_MODE_OUTPUT );
        gpio_set_level( GPIO_CS, 0 );
    }

    ESP_LOGI(TAG, "GPIO_DC=%d",GPIO_DC);
    //gpio_pad_select_gpio( GPIO_DC );
    gpio_reset_pin( GPIO_DC );
    gpio_set_direction( GPIO_DC, GPIO_MODE_OUTPUT );
    gpio_set_level( GPIO_DC, 0 );

    ESP_LOGI(TAG, "GPIO_RESET=%d",GPIO_RESET);
    if ( GPIO_RESET >= 0 ) {
        //gpio_pad_select_gpio( GPIO_RESET );
        gpio_reset_pin( GPIO_RESET );
        gpio_set_direction( GPIO_RESET, GPIO_MODE_OUTPUT );
        gpio_set_level( GPIO_RESET, 1 );
        delayMS(50);
        gpio_set_level( GPIO_RESET, 0 );
        delayMS(150);
        gpio_set_level( GPIO_RESET, 1 );
        delayMS(150);
    }

    ESP_LOGI(TAG, "GPIO_BL=%d",GPIO_BL);
    if ( GPIO_BL >= 0 ) {
        //gpio_pad_select_gpio(GPIO_BL);
        gpio_reset_pin(GPIO_BL);
        gpio_set_direction( GPIO_BL, GPIO_MODE_OUTPUT );
        gpio_set_level( GPIO_BL, 0 );
    }

    ESP_LOGI(TAG, "GPIO_MOSI=%d",GPIO_MOSI);
    ESP_LOGI(TAG, "GPIO_SCLK=%d",GPIO_SCLK);
    spi_bus_config_t buscfg = {
        .mosi_io_num = GPIO_MOSI,
        .miso_io_num = -1,
        .sclk_io_num = GPIO_SCLK,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = CONFIG_WIDTH*CONFIG_HEIGHT*2,
        .flags = 0
    };

    ret = spi_bus_initialize( LCD_HOST, &buscfg, SPI_DMA_CH_AUTO );
    ESP_LOGD(TAG, "spi_bus_initialize=%d",ret);
    assert(ret==ESP_OK);

    spi_device_interface_config_t devcfg;
    memset(&devcfg, 0, sizeof(devcfg));
    devcfg.clock_speed_hz = SPI_Frequency;
    devcfg.queue_size = 1;
    devcfg.mode = 2;
    devcfg.flags = SPI_DEVICE_NO_DUMMY;

    if ( GPIO_CS >= 0 ) {
        devcfg.spics_io_num = GPIO_CS;
    } else {
        devcfg.spics_io_num = -1;
    }

    spi_device_handle_t handle;
    ret = spi_bus_add_device( LCD_HOST, &devcfg, &handle);
    ESP_LOGD(TAG, "spi_bus_add_device=%d",ret);
    assert(ret==ESP_OK);
    dev->_dc = GPIO_DC;
    dev->_bl = GPIO_BL;
    dev->_SPIHandle = handle;
}


inline bool spi_master_write_byte(spi_device_handle_t SPIHandle, const uint8_t* Data, size_t DataLength)
{
    spi_transaction_t SPITransaction;
    esp_err_t ret;

    memset( &SPITransaction, 0, sizeof( spi_transaction_t ) );
    SPITransaction.length = DataLength * 8;
    SPITransaction.tx_buffer = Data;
    //ret = spi_device_transmit( SPIHandle, &SPITransaction );
    ret = spi_device_polling_transmit( SPIHandle, &SPITransaction );
    assert(ret==ESP_OK); 

    return true;
}

bool spi_master_write_command(TFT_t * dev, uint8_t cmd)
{
    static uint8_t Byte = 0;
    Byte = cmd;
    gpio_set_level( dev->_dc, SPI_Command_Mode );
    return spi_master_write_byte( dev->_SPIHandle, &Byte, 1 );
}

bool spi_master_write_data_byte(TFT_t * dev, uint8_t data)
{
    static uint8_t Byte = 0;
    Byte = data;
    gpio_set_level( dev->_dc, SPI_Data_Mode );
    return spi_master_write_byte( dev->_SPIHandle, &Byte, 1 );
}


bool spi_master_write_data_word(TFT_t * dev, uint16_t data)
{
    static uint8_t Byte[2];
    Byte[0] = (data >> 8) & 0xFF;
    Byte[1] = data & 0xFF;
    gpio_set_level( dev->_dc, SPI_Data_Mode );
    return spi_master_write_byte( dev->_SPIHandle, Byte, 2);
}

bool spi_master_write_addr(TFT_t * dev, uint16_t addr1, uint16_t addr2)
{
    static uint8_t Byte[4];
    Byte[0] = (addr1 >> 8) & 0xFF;
    Byte[1] = addr1 & 0xFF;
    Byte[2] = (addr2 >> 8) & 0xFF;
    Byte[3] = addr2 & 0xFF;
    gpio_set_level( dev->_dc, SPI_Data_Mode );
    return spi_master_write_byte( dev->_SPIHandle, Byte, 4);
}

bool spi_master_write_color(TFT_t * dev, uint16_t color, uint16_t size)
{
    static uint8_t Byte[1024];
    int index = 0;
    for(int i=0;i<size;i++) {
        Byte[index++] = (color >> 8) & 0xFF;
        Byte[index++] = color & 0xFF;
    }
    gpio_set_level( dev->_dc, SPI_Data_Mode );
    return spi_master_write_byte( dev->_SPIHandle, Byte, size*2);
}

// Add 202001
bool spi_master_write_colors(TFT_t * dev, uint16_t * colors, uint16_t size)
{
    static uint8_t Byte[1024];
    int index = 0;
    for(int i=0;i<size;i++) {
        Byte[index++] = (colors[i] >> 8) & 0xFF;
        Byte[index++] = colors[i] & 0xFF;
    }
    gpio_set_level( dev->_dc, SPI_Data_Mode );
    return spi_master_write_byte( dev->_SPIHandle, Byte, size*2);
}

void delayMS(int ms) {
    int _ms = ms + (portTICK_PERIOD_MS - 1);
    TickType_t xTicksToDelay = _ms / portTICK_PERIOD_MS;
    vTaskDelay(xTicksToDelay);
}


void lcdInit(TFT_t * dev, int width, int height, int offsetx, int offsety)
{
    spi_master_write_command(dev, 0x01);	//Software Reset
    delayMS(10);

    spi_master_write_command(dev, 0x11);	//Sleep Out
    delayMS(10);

    spi_master_write_command(dev, 0x3A);	//Interface Pixel Format
    spi_master_write_data_byte(dev, 0x55);
    delayMS(10);

    spi_master_write_command(dev, 0x36);	//Memory Data Access Control
    spi_master_write_data_byte(dev, 0x00);

    spi_master_write_command(dev, 0x21);	//Display Inversion On
    delayMS(10);

    spi_master_write_command(dev, 0x13);	//Normal Display Mode On
    delayMS(10);


    spi_master_write_command(dev, 0x29);	//Display ON
    delayMS(5);

    spi_master_write_command(dev, ST7789_MADCTL);
    spi_master_write_data_byte(dev, ST7789_MADCTL_MX | ST7789_MADCTL_MV | ST7789_MADCTL_RGB);

    blankFullDisplay(dev);

    // reset back to normal
    spi_master_write_command(dev, 0x2A);	//Column Address Set
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 56);
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 56+CONFIG_WIDTH-1);

    spi_master_write_command(dev, 0x2B);	//Row Address Set
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 56);
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 56+CONFIG_HEIGHT-1);

}

void blankFullDisplay(TFT_t * dev) {
    spi_master_write_command(dev, 0x2A);	//Column Address Set
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 239);

    spi_master_write_command(dev, 0x2B);	//Row Address Set
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 0x00);
    spi_master_write_data_byte(dev, 239);


    uint8_t buffer[240*2];
    memset(buffer, 0, sizeof(buffer));
    gpio_set_level(dev->_dc, SPI_Command_Mode);
    spi_master_write_command(dev, 0x2C);	//	Memory Write
    gpio_set_level(dev->_dc, SPI_Data_Mode);
    for(uint8_t y=0; y<240; y++) {
        spi_master_write_byte(dev->_SPIHandle, buffer, sizeof(buffer));
    }
}

// Backlight OFF
void lcdBacklightOff(TFT_t * dev) {
    if(dev->_bl >= 0) {
        gpio_set_level( dev->_bl, 0 );
    }
}

// Backlight ON
void lcdBacklightOn(TFT_t * dev) {
    if(dev->_bl >= 0) {
        gpio_set_level( dev->_bl, 1 );
    }
}

// Display Inversion Off
void lcdInversionOff(TFT_t * dev) {
    spi_master_write_command(dev, 0x20);	//Display Inversion Off
}

// Display Inversion On
void lcdInversionOn(TFT_t * dev) {
    spi_master_write_command(dev, 0x21);	//Display Inversion On
}

void send_buffer(TFT_t* dev, uint8_t *buffer, uint16_t bufferLen) {
    spi_device_acquire_bus(dev->_SPIHandle, portMAX_DELAY);

    gpio_set_level(dev->_dc, SPI_Command_Mode);
    spi_master_write_command(dev, 0x2C);	//	Memory Write

    gpio_set_level(dev->_dc, SPI_Data_Mode);
    spi_master_write_byte(dev->_SPIHandle, buffer, bufferLen);
    spi_device_release_bus(dev->_SPIHandle);
}
