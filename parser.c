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
    *line -= count;
    return count;
}

void gfxParser(const uint8_t* line, int spriteLineCount, Spritesheet* s) {
    const int offset = spriteLineCount * 128;
    for (uint8_t i = 0; i < 128; i++) {
	    s->sprite_data[ i + offset] = parseChar(line[i]);
    }
}

void noteParser(const uint8_t* line, uint8_t sfx_id, Note* notes) {
    for(uint8_t note=0; note<NOTES_PER_SFX; note++) {
        notes[note].key         = (parseChar(line[note*5+0]) << 4) | parseChar(line[note*5+1]);
        notes[note].waveform    = parseChar(line[note*5+2]);
        notes[note].volume      = parseChar(line[note*5+3]);
        notes[note].effect      = parseChar(line[note*5+4]);
    }
}
void SFXParser(const uint8_t* line, int n, SFX* s) {
    // byte 0 is for the editor
    s[n].id         = n;
    s[n].duration   = (parseChar(line[2]) << 4) | parseChar(line[3]);
    s[n].loop_start = (parseChar(line[4]) << 4) | parseChar(line[5]);
    s[n].loop_end   = (parseChar(line[6]) << 4) | parseChar(line[7]);
    noteParser(line+8, n, s[n].notes);
}
void mapParser(const uint8_t* line, int spriteLineCount, uint8_t* map_data) {
    const int offset = spriteLineCount * 128;
    uint8_t msn, lsn;
    for (uint8_t i = 0; i < 128; i++) {
        // lsb, gfx->map
        msn = line[i*2+1];
        lsn = line[i*2  ];
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
