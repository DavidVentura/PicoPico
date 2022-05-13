#include "lua/fix32.h"
// https://github.com/samhocevar/zepto8/blob/master/src/synth.h
const uint8_t INST_TRIANGLE   = 0; // Triangle signal
const uint8_t INST_TILTED_SAW = 1; // Slanted triangle
const uint8_t INST_SAW        = 2; // Sawtooth
const uint8_t INST_SQUARE     = 3; // Square signal
const uint8_t INST_PULSE      = 4; // Asymmetric square signal
const uint8_t INST_ORGAN      = 5; // Some triangle stuff again
const uint8_t INST_NOISE      = 6;
const uint8_t INST_PHASER     = 7;

static z8::fix32 waveform(int instrument, z8::fix32 advance);
