#include "synth.h"
#include "fix32.h"

const fix32_t QUARTER = fix32_from_float(0.25f);
const fix32_t THIRD   = fix32_from_float(0.3333f);
const fix32_t HALF    = fix32_from_float(0.5f);
const fix32_t ONE     = fix32_from_int8(1);
const fix32_t TWO     = fix32_from_int8(2);
const fix32_t THREE   = fix32_from_int8(3);
const fix32_t FOUR    = fix32_from_int8(4);
const fix32_t SIX     = fix32_from_int8(6);

const fix32_t SAW_FACTOR  = fix32_from_float(0.653f);

fix32_t waveform(int instrument, fix32_t advance)
{
    fix32_t t = fix32_t::decimals(advance);
    fix32_t ret = 0;

    // Multipliers were measured from PICO-8 WAV exports. Waveforms are
    // inferred from those exports by guessing what the original formulas
    // could be.
    switch (instrument)
    {
        case INST_TRIANGLE:
            return (fix32_t::abs(fix32_t::fast_shl(t, 2) - TWO) - ONE) >> 1;
            //return fix32_t::fast_shr(fix32_t::abs(fix32_t::fast_shl(t, 2) - TWO) - ONE, 1);
        case INST_TILTED_SAW:
        {
            static fix32_t const a = 0.9f;
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
            ret = t < HALF ? THREE  - fix32_t::abs(24 * t - SIX)
                           : ONE    - fix32_t::abs(16 * t - 12);
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
            return (fix32_t(rand() >> 16)/fix32_t(RAND_MAX >> 17)) * THIRD;
        }
        case INST_PHASER:
        {   // This one has a subfrequency of freq/128 that appears
            // to modulate two signals using a triangle wave
            // FIXME: amplitude seems to be affected, too
            fix32_t k = fix32_t::abs(TWO * fix32_t::decimals(advance >> 7) - ONE);
            fix32_t u = fix32_t::decimals(t + HALF * k);
            ret = fix32_t::abs((u<<2) - TWO) - fix32_t::abs((t<<3) - FOUR);
            return ret / SIX;
        }
    }

    return 0;
}

void apply_fx(SFX* s, Note* n, fix32_t* volume, uint16_t* freq, uint16_t offset, uint16_t speed, uint16_t note_id) {
    switch(n->effect) {
        case FX_NO_EFFECT:
            return;
        case FX_SLIDE:
            {
                float t = fmod(offset, 1.f);
                // From the documentation: “Slide to the next note and volume”,
                // but it’s actually _from_ the _prev_ note and volume.
                /*
                   freq = lol::mix(key_to_freq(m_state.channels[chan].prev_key), freq, t);
                   if (m_state.channels[chan].prev_vol > 0.f)
                   volume = lol::mix(m_state.channels[chan].prev_vol, volume, t);
                   */
                break;
            }
        case FX_VIBRATO:
            {
                // 7.5f and 0.25f were found empirically by matching
                // frequency graphs of PICO-8 instruments.
                // float t = fabs(fmod(7.5f * offset / offset_per_second, 1.0f) - 0.5f) - 0.25f;
                // Vibrato half a semi-tone, so multiply by pow(2,1/12)
                // freq = lol::mix(freq, freq * 1.059463094359f, t);
                break;
            }
        case FX_DROP:
            *freq *= 1.f - fmod(offset, 1.f);
            break;
        case FX_FADE_IN:
            *volume *= fmodf(offset, 1.f);
            break;
        case FX_FADE_OUT:
            *volume *= 1.f - fmodf(offset, 1.f);
            break;
        case FX_ARP_FAST:
        case FX_ARP_SLOW:
            // From the documentation:
            // “6 arpeggio fast  //  Iterate over groups of 4 notes at speed of 4
            //  7 arpeggio slow  //  Iterate over groups of 4 notes at speed of 8”
            // “If the SFX speed is <= 8, arpeggio speeds are halved to 2, 4”
            int const m = (speed <= 8 ? 32 : 16) / (n->effect == FX_ARP_FAST ? 4 : 8);
            //int const n = (int)(m * 7.5f * offset / offset_per_second);
            //int const arp_note = (note_id & ~3) | (n & 3);
            //*freq = key_to_freq[s->notes[arp_note].key];
            break;
    }
}
