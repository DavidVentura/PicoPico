#include <string.h>
#include <math.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include <driver/spi_master.h>
#include <driver/gpio.h>
#include "esp_log.h"

#include "ili9340.h"

#define TAG "ILI9340"
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

//static const int GPIO_MOSI = 23;
//static const int GPIO_SCLK = 18;

static const int SPI_Command_Mode = 0;
static const int SPI_Data_Mode = 1;
//static const int TFT_Frequency = SPI_MASTER_FREQ_20M;
////static const int TFT_Frequency = SPI_MASTER_FREQ_26M;
static const int TFT_Frequency = SPI_MASTER_FREQ_40M;
////static const int TFT_Frequency = SPI_MASTER_FREQ_80M;

void spi_master_init(TFT_t * dev, gpio_num_t GPIO_MOSI, gpio_num_t GPIO_SCLK, gpio_num_t TFT_CS, gpio_num_t GPIO_DC, gpio_num_t GPIO_RESET, gpio_num_t GPIO_BL)
{
	esp_err_t ret;

	ESP_LOGI(TAG, "TFT_CS=%d",TFT_CS);
	//gpio_pad_select_gpio( TFT_CS );
	gpio_reset_pin( TFT_CS );
	gpio_set_direction( TFT_CS, GPIO_MODE_OUTPUT );
	//gpio_set_level( TFT_CS, 0 );
	gpio_set_level((gpio_num_t)TFT_CS, 1 ); // TODO this is invented from st7789

	ESP_LOGI(TAG, "GPIO_DC=%d",GPIO_DC);
	//gpio_pad_select_gpio( GPIO_DC );
	gpio_reset_pin( GPIO_DC );
	gpio_set_direction( GPIO_DC, GPIO_MODE_OUTPUT );
	gpio_set_level((gpio_num_t) GPIO_DC, 0 );

	ESP_LOGI(TAG, "GPIO_RESET=%d",GPIO_RESET);
	if ( GPIO_RESET >= 0 ) {
		//gpio_pad_select_gpio( GPIO_RESET );
		gpio_reset_pin( GPIO_RESET );
		gpio_set_direction( GPIO_RESET, GPIO_MODE_OUTPUT );
		gpio_set_level( (gpio_num_t)GPIO_RESET, 1 );
		vTaskDelay( pdMS_TO_TICKS( 50 ) );
		gpio_set_level((gpio_num_t) GPIO_RESET, 0 );
		vTaskDelay( pdMS_TO_TICKS( 150 ) );
		gpio_set_level( (gpio_num_t)GPIO_RESET, 1 );
		vTaskDelay( pdMS_TO_TICKS( 150 ) );
	}

	ESP_LOGI(TAG, "GPIO_BL=%d",GPIO_BL);
	if ( GPIO_BL >= 0 ) {
		//gpio_pad_select_gpio( GPIO_BL );
		gpio_reset_pin( GPIO_BL );
		gpio_set_direction( GPIO_BL, GPIO_MODE_OUTPUT );
		gpio_set_level((gpio_num_t) GPIO_BL, 0 );
	}

	ESP_LOGI(TAG, "GPIO_MOSI=%d",GPIO_MOSI);
	ESP_LOGI(TAG, "GPIO_CLK=%d",GPIO_SCLK);
	spi_bus_config_t buscfg = {
		.mosi_io_num = GPIO_MOSI,
		.miso_io_num = -1,
		.sclk_io_num = GPIO_SCLK,
		.quadwp_io_num = -1,
		.quadhd_io_num = -1,
        .max_transfer_sz = CONFIG_WIDTH*CONFIG_HEIGHT*2,
        .flags = 0
	};

	ret = spi_bus_initialize(LCD_HOST, &buscfg, SPI_DMA_CH_AUTO );
	ESP_LOGD(TAG, "spi_bus_initialize=%d",ret);
	assert(ret==ESP_OK);

	spi_device_interface_config_t tft_devcfg;
    memset(&tft_devcfg, 0, sizeof(tft_devcfg));
    tft_devcfg.clock_speed_hz = TFT_Frequency;
    tft_devcfg.spics_io_num = TFT_CS;
    tft_devcfg.queue_size = 1;
    tft_devcfg.mode = 0; // tried mode in 2, black screen
    tft_devcfg.flags = SPI_DEVICE_NO_DUMMY;

    spi_device_handle_t tft_handle;
	ret = spi_bus_add_device( LCD_HOST, &tft_devcfg, &tft_handle);
	ESP_LOGD(TAG, "spi_bus_add_device=%d",ret);
	assert(ret==ESP_OK);
	dev->_dc = GPIO_DC;
	dev->_bl = GPIO_BL;
	dev->_TFT_Handle = tft_handle;

}


bool spi_master_write_byte(spi_device_handle_t SPIHandle, const uint8_t* Data, size_t DataLength)
{
	spi_transaction_t SPITransaction;
	esp_err_t ret;

    memset( &SPITransaction, 0, sizeof( spi_transaction_t ) );
    SPITransaction.length = DataLength * 8;
    SPITransaction.tx_buffer = Data;
#if 0
    ret = spi_device_transmit( SPIHandle, &SPITransaction );
#else
    ret = spi_device_polling_transmit( SPIHandle, &SPITransaction );
#endif
    assert(ret==ESP_OK); 

	return true;
}

bool spi_master_write_comm_byte(TFT_t * dev, uint8_t cmd)
{
	static uint8_t Byte = 0;
	Byte = cmd;
	gpio_set_level((gpio_num_t) dev->_dc, SPI_Command_Mode );
	return spi_master_write_byte( dev->_TFT_Handle, &Byte, 1 );
}

bool spi_master_write_comm_word(TFT_t * dev, uint16_t cmd)
{
	static uint8_t Byte[2];
	Byte[0] = (cmd >> 8) & 0xFF;
	Byte[1] = cmd & 0xFF;
	gpio_set_level( (gpio_num_t)dev->_dc, SPI_Command_Mode );
	return spi_master_write_byte( dev->_TFT_Handle, Byte, 2 );
}


bool spi_master_write_data_byte(TFT_t * dev, uint8_t data)
{
	static uint8_t Byte = 0;
	Byte = data;
	gpio_set_level((gpio_num_t) dev->_dc, SPI_Data_Mode );
	return spi_master_write_byte( dev->_TFT_Handle, &Byte, 1 );
}


bool spi_master_write_data_word(TFT_t * dev, uint16_t data)
{
	static uint8_t Byte[2];
	Byte[0] = (data >> 8) & 0xFF;
	Byte[1] = data & 0xFF;
	gpio_set_level((gpio_num_t) dev->_dc, SPI_Data_Mode );
	return spi_master_write_byte( dev->_TFT_Handle, Byte, 2);
}


void delayMS(int ms) {
	int _ms = ms + (portTICK_PERIOD_MS - 1);
	TickType_t xTicksToDelay = _ms / portTICK_PERIOD_MS;
	// ESP_LOGD(TAG, "ms=%d _ms=%d portTICK_PERIOD_MS=%d xTicksToDelay=%d",ms,_ms,portTICK_PERIOD_MS,xTicksToDelay);
	vTaskDelay(xTicksToDelay);
}


void lcdWriteRegisterByte(TFT_t * dev, uint8_t addr, uint16_t data)
{
	spi_master_write_comm_byte(dev, addr);
	spi_master_write_data_word(dev, data);
}


void lcdInit(TFT_t * dev, uint16_t model, int width, int height, int offsetx, int offsety)
{
    dev->_model = model;
	if (dev->_model == 0x9340 || dev->_model == 0x9341 || dev->_model == 0x7735) {
		if (dev->_model == 0x9340)
			ESP_LOGI(TAG,"Your TFT is ILI9340");
		if (dev->_model == 0x9341)
			ESP_LOGI(TAG,"Your TFT is ILI9341");
		if (dev->_model == 0x7735)
			ESP_LOGI(TAG,"Your TFT is ST7735");
		ESP_LOGI(TAG,"Screen width:%d",width);
		ESP_LOGI(TAG,"Screen height:%d",height);
		spi_master_write_comm_byte(dev, 0xC0);	//Power Control 1
		spi_master_write_data_byte(dev, 0x23);

		spi_master_write_comm_byte(dev, 0xC1);	//Power Control 2
		spi_master_write_data_byte(dev, 0x10);
	
		spi_master_write_comm_byte(dev, 0xC5);	//VCOM Control 1
		spi_master_write_data_byte(dev, 0x3E);
		spi_master_write_data_byte(dev, 0x28);
	
		spi_master_write_comm_byte(dev, 0xC7);	//VCOM Control 2
		spi_master_write_data_byte(dev, 0x86);

		spi_master_write_comm_byte(dev, 0x36);	//Memory Access Control
        // change from 0x08 to 0x00

        //spi_master_write_data_byte(dev, 0x00 | 0x40 | 0x20) ; // | 0x40 | 0x20);	//Right top start, BGR color filter panel
		spi_master_write_data_byte(dev, 0x00) ; // | 0x40 | 0x20);	//Right top start, BGR color filter panel
		//spi_master_write_data_byte(dev, 0x00);//Right top start, RGB color filter panel
        // 0x40 0x20 are rotate 2x?

		spi_master_write_comm_byte(dev, 0x3A);	//Pixel Format Set
		spi_master_write_data_byte(dev, 0x55);	//65K color: 16-bit/pixel

		spi_master_write_comm_byte(dev, 0x20);	//Display Inversion OFF

		spi_master_write_comm_byte(dev, 0xB1);	//Frame Rate Control
		spi_master_write_data_byte(dev, 0x00);
		spi_master_write_data_byte(dev, 0x18);

		spi_master_write_comm_byte(dev, 0xB6);	//Display Function Control
		spi_master_write_data_byte(dev, 0x08);
		spi_master_write_data_byte(dev, 0xA2);	// REV:1 GS:0 SS:0 SM:0
		spi_master_write_data_byte(dev, 0x27);
		spi_master_write_data_byte(dev, 0x00);

		//spi_master_write_comm_byte(dev, 0x26);	//Gamma Set
		//spi_master_write_data_byte(dev, 0x01);

        // {0x02, 0x1C, 0x07, 0x12, 0x37, 0x32, 0x29, 0x2D, 0x29, 0x25, 0x2B, 0x39, 0x00, 0x01, 0x03, 0x10 }},
		spi_master_write_comm_byte(dev, 0xE0);	//Positive Gamma Correction
		spi_master_write_data_byte(dev, 0x02);
		spi_master_write_data_byte(dev, 0x1C);
		spi_master_write_data_byte(dev, 0x07);
		spi_master_write_data_byte(dev, 0x12);
		spi_master_write_data_byte(dev, 0x37);
		spi_master_write_data_byte(dev, 0x32);
		spi_master_write_data_byte(dev, 0x29);
		spi_master_write_data_byte(dev, 0x2D);
		spi_master_write_data_byte(dev, 0x29);
		spi_master_write_data_byte(dev, 0x25);
		spi_master_write_data_byte(dev, 0x2B);
		spi_master_write_data_byte(dev, 0x39);
		spi_master_write_data_byte(dev, 0x00);
		spi_master_write_data_byte(dev, 0x01);
		spi_master_write_data_byte(dev, 0x03);
		spi_master_write_data_byte(dev, 0x10);
		//spi_master_write_data_byte(dev, 0x0F);
		//spi_master_write_data_byte(dev, 0x31);
		//spi_master_write_data_byte(dev, 0x2B);
		//spi_master_write_data_byte(dev, 0x0C);
		//spi_master_write_data_byte(dev, 0x0E);
		//spi_master_write_data_byte(dev, 0x08);
		//spi_master_write_data_byte(dev, 0x4E);
		//spi_master_write_data_byte(dev, 0xF1);
		//spi_master_write_data_byte(dev, 0x37);
		//spi_master_write_data_byte(dev, 0x07);
		//spi_master_write_data_byte(dev, 0x10);
		//spi_master_write_data_byte(dev, 0x03);
		//spi_master_write_data_byte(dev, 0x0E);
		//spi_master_write_data_byte(dev, 0x09);
		//spi_master_write_data_byte(dev, 0x00);

        // {0x03, 0x1d, 0x07, 0x06, 0x2E, 0x2C, 0x29, 0x2D, 0x2E, 0x2E, 0x37, 0x3F, 0x00, 0x00, 0x02, 0x10 }},
		spi_master_write_comm_byte(dev, 0xE1);	//Negative Gamma Correction
		spi_master_write_data_byte(dev, 0x03);
		spi_master_write_data_byte(dev, 0x1D);
		spi_master_write_data_byte(dev, 0x07);
		spi_master_write_data_byte(dev, 0x06);
		spi_master_write_data_byte(dev, 0x2E);
		spi_master_write_data_byte(dev, 0x2C);
		spi_master_write_data_byte(dev, 0x29);
		spi_master_write_data_byte(dev, 0x2D);
		spi_master_write_data_byte(dev, 0x2E);
		spi_master_write_data_byte(dev, 0x2E);
		spi_master_write_data_byte(dev, 0x37);
		spi_master_write_data_byte(dev, 0x3F);
		spi_master_write_data_byte(dev, 0x00);
		spi_master_write_data_byte(dev, 0x00);
		spi_master_write_data_byte(dev, 0x02);
		spi_master_write_data_byte(dev, 0x10);

		//spi_master_write_data_byte(dev, 0x00);
		//spi_master_write_data_byte(dev, 0x0E);
		//spi_master_write_data_byte(dev, 0x14);
		//spi_master_write_data_byte(dev, 0x03);
		//spi_master_write_data_byte(dev, 0x11);
		//spi_master_write_data_byte(dev, 0x07);
		//spi_master_write_data_byte(dev, 0x31);
		//spi_master_write_data_byte(dev, 0xC1);
		//spi_master_write_data_byte(dev, 0x48);
		//spi_master_write_data_byte(dev, 0x08);
		//spi_master_write_data_byte(dev, 0x0F);
		//spi_master_write_data_byte(dev, 0x0C);
		//spi_master_write_data_byte(dev, 0x31);
		//spi_master_write_data_byte(dev, 0x36);
		//spi_master_write_data_byte(dev, 0x0F);

		spi_master_write_comm_byte(dev, 0x11);	//Sleep Out
		delayMS(120);

		spi_master_write_comm_byte(dev, 0x29);	//Display ON
	}


	if(dev->_bl >= 0) {
		gpio_set_level((gpio_num_t) dev->_bl, 1);
	}

    printf("setting largert window\n");
    // https://stackoverflow.com/a/45622027
    // display is actually 132 x 132

    // blank entire window
    spi_master_write_comm_byte(dev, 0x2A);	// set column(x) address
    spi_master_write_data_word(dev, 0);
    //spi_master_write_data_word(dev, 160);
    spi_master_write_data_word(dev, 128);

    spi_master_write_comm_byte(dev, 0x2B);	// set Page(y) address
    spi_master_write_data_word(dev, 0);
    spi_master_write_data_word(dev, 160);
    //spi_master_write_data_word(dev, 128);


    uint8_t buffer[160*2];
    memset(buffer, 0x0, sizeof(buffer));
    gpio_set_level(dev->_dc, SPI_Command_Mode);
    spi_master_write_comm_byte(dev, 0x2C);	//	Memory Write
    gpio_set_level(dev->_dc, SPI_Data_Mode);
    for(uint8_t y=0; y<128; y++) {
        spi_master_write_byte(dev->_TFT_Handle, buffer, sizeof(buffer));
    }

}

void set_window_sprite(TFT_t* dev, uint8_t index) {
    // set regular window
    printf("setting window\n");
    spi_master_write_comm_byte(dev, 0x2A);	// set column(x) address
    //spi_master_write_data_word(dev, 16);
    //spi_master_write_data_word(dev, 16+127);
    spi_master_write_data_word(dev, index*8+index);
    spi_master_write_data_word(dev, (index+1)*8+index-1);

    spi_master_write_comm_byte(dev, 0x2B);	// set Page(y) address
    spi_master_write_data_word(dev, 4);
    spi_master_write_data_word(dev, 12);
}

void set_window(TFT_t* dev) {
    // set regular window
    printf("setting window\n");
    spi_master_write_comm_byte(dev, 0x2A);	// set column(x) address
    //spi_master_write_data_word(dev, 16);
    //spi_master_write_data_word(dev, 16+127);
    spi_master_write_data_word(dev, 0);
    spi_master_write_data_word(dev, 127);

    spi_master_write_comm_byte(dev, 0x2B);	// set Page(y) address
    spi_master_write_data_word(dev, 16);
    spi_master_write_data_word(dev, 32+127);
}

// Display OFF
void lcdDisplayOff(TFT_t * dev) {
	if (dev->_model == 0x9340 || dev->_model == 0x9341 || dev->_model == 0x7735 || dev->_model == 0x7796) {
		spi_master_write_comm_byte(dev, 0x28);
	} // endif 0x9340/0x9341/0x7735/0x7796

	if (dev->_model == 0x9225 || dev->_model == 0x9226) {
		lcdWriteRegisterByte(dev, 0x07, 0x1014);
	} // endif 0x9225/0x9226

}
 
// Display ON
void lcdDisplayOn(TFT_t * dev) {
	if (dev->_model == 0x9340 || dev->_model == 0x9341 || dev->_model == 0x7735 || dev->_model == 0x7796) {
		spi_master_write_comm_byte(dev, 0x29);
	} // endif 0x9340/0x9341/0x7735/0x7796

	if (dev->_model == 0x9225 || dev->_model == 0x9226) {
		lcdWriteRegisterByte(dev, 0x07, 0x1017);
	} // endif 0x9225/0x9226

}

// Display Inversion OFF
void lcdInversionOff(TFT_t * dev) {
	if (dev->_model == 0x9340 || dev->_model == 0x9341 || dev->_model == 0x7735 || dev->_model == 0x7796) {
		spi_master_write_comm_byte(dev, 0x20);
	} // endif 0x9340/0x9341/0x7735/0x7796

	if (dev->_model == 0x9225 || dev->_model == 0x9226) {
		lcdWriteRegisterByte(dev, 0x07, 0x1017);
	} // endif 0x9225/0x9226
}

// Display Inversion ON
void lcdInversionOn(TFT_t * dev) {
	if (dev->_model == 0x9340 || dev->_model == 0x9341 || dev->_model == 0x7735 || dev->_model == 0x7796) {
		spi_master_write_comm_byte(dev, 0x21);
	} // endif 0x9340/0x9341/0x7735/0x7796

	if (dev->_model == 0x9225 || dev->_model == 0x9226) {
		lcdWriteRegisterByte(dev, 0x07, 0x1013);
	} // endif 0x9225/0x9226
}

// Change Memory Access Control
void lcdBGRFilter(TFT_t * dev) {
	if (dev->_model == 0x9340 || dev->_model == 0x9341 || dev->_model == 0x7735 || dev->_model == 0x7796) {
		spi_master_write_comm_byte(dev, 0x36);	//Memory Access Control
		spi_master_write_data_byte(dev, 0x00);	//Right top start, RGB color filter panel
	} // endif 0x9340/0x9341/0x7735/0x7796

	if (dev->_model == 0x9225 || dev->_model == 0x9226) {
		lcdWriteRegisterByte(dev, 0x03, 0x0030); // set GRAM write direction and BGR=0.
	} // endif 0x9225/0x9226
}

// RGB565 conversion
// RGB565 is R(5)+G(6)+B(5)=16bit color format.
// Bit image "RRRRRGGGGGGBBBBB"
uint16_t rgb565_conv(uint16_t r,uint16_t g,uint16_t b) {
	return (((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3));
}

// Backlight OFF
void lcdBacklightOff(TFT_t * dev) {
	if(dev->_bl >= 0) {
		gpio_set_level((gpio_num_t) dev->_bl, 0 );
	}
}

// Backlight ON
void lcdBacklightOn(TFT_t * dev) {
	if(dev->_bl >= 0) {
		gpio_set_level((gpio_num_t) dev->_bl, 1 );
	}
}

void send_buffer(TFT_t* dev, uint8_t *buffer, uint16_t bufferLen) {
    spi_device_acquire_bus(dev->_TFT_Handle, portMAX_DELAY);

    gpio_set_level((gpio_num_t)dev->_dc, SPI_Command_Mode);
    spi_master_write_comm_byte(dev, 0x2C);	//	Memory Write

    gpio_set_level((gpio_num_t)dev->_dc, SPI_Data_Mode);
    spi_master_write_byte(dev->_TFT_Handle, buffer, bufferLen);
    spi_device_release_bus(dev->_TFT_Handle);
}

void draw_sprite(TFT_t* dev, uint8_t *buffer, uint16_t bufferLen, uint8_t sprite_index) {
    set_window_sprite(dev, sprite_index);
    send_buffer(dev, buffer, bufferLen);
    set_window(dev);
}
