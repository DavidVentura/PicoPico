#include "data.h"
#include <string.h>
#include <stdlib.h>

uint8_t parseChar(char c);

uint32_t readLine(uint8_t** text, uint8_t* line) {
    uint32_t count = 0;

    while(**text != '\0') {
	count++;
	*line++ = *(*text)++;
	if (**text == '\n') {
	    count++;
	    *line++ = *(*text)++;
	    break;
	}
    }
    line -= count;
    return count;
}

void decodeRLE(uint8_t* decbuf, uint8_t* rawbuf, uint16_t rawLen) {
	uint16_t decPos = 0;
	uint8_t count = 1;
	for(uint16_t i=0; i<rawLen; i++) {
		uint8_t chr = rawbuf[i] & 0x7F;
		bool multiple = (rawbuf[i] & 0x80) == 0x80;
		if(multiple == true) {
			i++;
			if (rawbuf[i] == 0xFF) {
				count = 11; // HACK: can't encode a 10 (\n) as it breaks the newline parser
			} else {
				count = rawbuf[i] + 1;
			}
		} else {
			count = 1;
		}
		memset(decbuf+decPos, chr, count);
		decPos += count;
	}
}
void gfxParser(uint8_t* line, int spriteLineCount, Spritesheet* s) {
    const int offset = spriteLineCount * 128;
    for (uint8_t i = 0; i < 128; i++) {
	s->sprite_data[ i + offset] = parseChar(line[i]);
    }
}
void mapParser(char* line, int spriteLineCount, uint8_t* map_data) {
    const int offset = spriteLineCount * 128;
    for (uint8_t i = 0; i < 128; i++) {
	uint8_t msn = parseChar(line[i*2  ]);
	uint8_t lsn = parseChar(line[i*2+1]);
	map_data[i+offset] = ((msn & 0x7) << 4) | lsn & 0x7;
    }
}

inline uint8_t parseChar(char c) {
    switch(c) {
	case '0':
	    return 0;
	case '1':
	    return 1;
	case '2':
	    return 2;
	case '3':
	    return 3;
	case '4':
	    return 4;
	case '5':
	    return 5;
	case '6':
	    return 6;
	case '7':
	    return 7;
	case '8':
	    return 8;
	case '9':
	    return 9;
	case 'a':
	    return 10;
	case 'b':
	    return 11;
	case 'c':
	    return 12;
	case 'd':
	    return 13;
	case 'e':
	    return 14;
	case 'f':
	    return 15;
    }
    return 0xAA;
}
