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

const uint8_t FX_NO_EFFECT  = 0;
const uint8_t FX_SLIDE      = 1;
const uint8_t FX_VIBRATO    = 2;
const uint8_t FX_DROP       = 3;
const uint8_t FX_FADE_IN    = 4;
const uint8_t FX_FADE_OUT   = 5;
const uint8_t FX_ARP_FAST   = 6;
const uint8_t FX_ARP_SLOW   = 7;

static z8::fix32 waveform(int instrument, z8::fix32 advance);

const static z8::fix32 key_to_freq[64] = {
    65.40639132514966f,
    69.29565774421802f,
    73.41619197935188f,
    77.78174593052023f,
    82.4068892282175f,
    87.30705785825097f,
    92.4986056779086f,
    97.99885899543733f,
    103.82617439498628f,
    110.0f,
    116.54094037952248f,
    123.47082531403103f,
    130.8127826502993f,
    138.59131548843604f,
    146.8323839587038f,
    155.56349186104046f,
    164.81377845643496f,
    174.61411571650194f,
    184.9972113558172f,
    195.99771799087463f,
    207.65234878997256f,
    220.0f,
    233.08188075904496f,
    246.94165062806206f,
    261.6255653005986f,
    277.1826309768721f,
    293.6647679174076f,
    311.1269837220809f,
    329.6275569128699f,
    349.2282314330039f,
    369.9944227116344f,
    391.99543598174927f,
    415.3046975799451f,
    440.0f,
    466.1637615180899f,
    493.8833012561241f,
    523.2511306011972f,
    554.3652619537442f,
    587.3295358348151f,
    622.2539674441618f,
    659.2551138257398f,
    698.4564628660078f,
    739.9888454232688f,
    783.9908719634985f,
    830.6093951598903f,
    880.0f,
    932.3275230361799f,
    987.7666025122483f,
    1046.5022612023945f,
    1108.7305239074883f,
    1174.6590716696303f,
    1244.5079348883237f,
    1318.5102276514797f,
    1396.9129257320155f,
    1479.9776908465376f,
    1567.981743926997f,
    1661.2187903197805f,
    1760.0f,
    1864.6550460723597f,
    1975.533205024496f,
    2093.004522404789f,
    2217.4610478149766f,
    2349.31814333926f,
    2489.0158697766474f,
};


