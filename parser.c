#include "data.h"
#include <string.h>
#include <stdlib.h>

uint8_t parseChar(char c);

char* readLine(char** text) {
    int count = 1;
    char* line = malloc(256);

    while(**text != '\0') {
	if (**text == '\r' || **text == '\n') {
	    break;
	}
	count++;
	*line++ = *(*text)++;
    }
    *line++ = '\0';
    (*text)++;
    line -= count;
    return line;
}

void gfxParser(char* line, int spriteLineCount, Spritesheet* s) {
	const int offset = spriteLineCount * 128;
	for (uint8_t i = 0; i < 128; i++) {
		s->sprite_data[ i + offset] = parseChar(line[i]);
	}
}
void mapParser(char* line) {
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
}
