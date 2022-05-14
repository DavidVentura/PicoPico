#include "data.h"
#include <cstring> // memset

uint8_t parseChar(char c);

uint32_t readLine(const uint8_t** text, uint8_t* line) {
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
void flagParser(uint8_t* line, int spriteLineCount, Spritesheet* s) {
    const int offset = spriteLineCount * 128;
    for (uint8_t i = 0; i < 128; i++) {
        uint8_t msn = parseChar(line[i*2  ]);
        uint8_t lsn = parseChar(line[i*2+1]);
        uint8_t flag = ((msn & 0xf) << 4) | (lsn & 0xf);
        s->flags[i+offset] = flag;
    }
}
void gfxParser(uint8_t* line, int spriteLineCount, Spritesheet* s) {
    const int offset = spriteLineCount * 128;
    for (uint8_t i = 0; i < 128; i++) {
	s->sprite_data[ i + offset] = parseChar(line[i]);
    }
}

void noteParser(char* line, Note* notes) {
    for(uint8_t note=0; note<32; note++) {
        notes[note].key         = (parseChar(line[note*5+0]) << 4) | parseChar(line[note*5+1]);
        notes[note].waveform    = parseChar(line[note*5+2]);
        notes[note].volume      = parseChar(line[note*5+3]);
        notes[note].effect      = parseChar(line[note*5+4]);
    }
}
void SFXParser(char* line, int n, SFX* s) {
    // byte 0 is for the editor
    s[n].duration   = (parseChar(line[2]) << 4) | parseChar(line[3]);
    s[n].loop_start = (parseChar(line[4]) << 4) | parseChar(line[5]);
    s[n].loop_end   = (parseChar(line[6]) << 4) | parseChar(line[7]);
    noteParser(line+8, s[n].notes);
}
void mapParser(char* line, int spriteLineCount, uint8_t* map_data) {
    const int offset = spriteLineCount * 128;
    for (uint8_t i = 0; i < 128; i++) {
        uint8_t msn = parseChar(line[i*2  ]);
        uint8_t lsn = parseChar(line[i*2+1]);
        uint8_t sprite = ((msn & 0xf) << 4) | (lsn & 0xf);
        map_data[i+offset] = sprite;
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
