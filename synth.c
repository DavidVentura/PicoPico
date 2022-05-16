#include "synth.h"

const z8::fix32 QUARTER = z8::fix32(0.25f);
const z8::fix32 THIRD   = z8::fix32(0.3333f);
const z8::fix32 HALF    = z8::fix32(0.5f);
const z8::fix32 ONE     = z8::fix32(1);
const z8::fix32 TWO     = z8::fix32(2);
const z8::fix32 THREE   = z8::fix32(3);
const z8::fix32 FOUR    = z8::fix32(4);
const z8::fix32 SIX     = z8::fix32(6);

const z8::fix32 SAW_FACTOR  = z8::fix32(0.653f);

z8::fix32 waveform(int instrument, z8::fix32 advance)
{
    z8::fix32 t = z8::fix32::decimals(advance);
    z8::fix32 ret = 0;

    // Multipliers were measured from PICO-8 WAV exports. Waveforms are
    // inferred from those exports by guessing what the original formulas
    // could be.
    switch (instrument)
    {
        case INST_TRIANGLE:
            return (z8::fix32::abs(z8::fix32::fast_shl(t, 2) - TWO) - ONE) >> 1;
            //return z8::fix32::fast_shr(z8::fix32::abs(z8::fix32::fast_shl(t, 2) - TWO) - ONE, 1);
        case INST_TILTED_SAW:
        {
            static z8::fix32 const a = 0.9f;
            ret = t < a ? 2 * t / a - ONE
                        : 2 * (ONE - t) / (ONE - a) - ONE;
            return ret >> 1;
        }
        case INST_SAW:
            return SAW_FACTOR * (t < HALF ? t : t - ONE);
        case INST_SQUARE:
            return t < HALF ? QUARTER : -QUARTER;
        case INST_PULSE:
            return t < THIRD ? QUARTER : -QUARTER;
        case INST_ORGAN:
            ret = t < HALF ? THREE  - z8::fix32::abs(24 * t - SIX)
                           : ONE    - z8::fix32::abs(16 * t - 12);
            return ret / 9;
        case INST_NOISE:
        {
            // Spectral analysis indicates this is some kind of brown noise,
            // but losing almost 10dB per octave. I thought using Perlin noise
            // would be fun, but it’s definitely not accurate.
            //
            // This may help us create a correct filter:
            // http://www.firstpr.com.au/dsp/pink-noise/

            /*
            static lol::perlin_noise<1> noise;
            for (float m = 1.75f, d = 1.f; m <= 128; m *= 2.25f, d *= 0.75f)
                ret += d * noise.eval(lol::vec_t<float, 1>(m * advance));
            return ret * 0.4f;
            */
            // FIXME: this is now more broken )) it gives _some_ noise
            // but obviously the noise profile is terrible
            return (z8::fix32(rand() >> 16)/z8::fix32(RAND_MAX >> 17)) * THIRD;
        }
        case INST_PHASER:
        {   // This one has a subfrequency of freq/128 that appears
            // to modulate two signals using a triangle wave
            // FIXME: amplitude seems to be affected, too
            z8::fix32 k = z8::fix32::abs(TWO * z8::fix32::decimals(advance >> 7) - ONE);
            z8::fix32 u = z8::fix32::decimals(t + HALF * k);
            ret = z8::fix32::abs((u<<2) - TWO) - z8::fix32::abs((t<<3) - FOUR);
            return ret / SIX;
        }
    }

    return 0;
}
