// TODO: consider shifting << 2**12 (slightly above max range) or 2**11
const z8::fix32 VOL_NORMALIZER = 32767.99f/7.f;

static SFX sfx[64];
static Channel channels[4];

// this is can fit an SFX of duration 1;
// so filling this buffer $duration times will play an entire SFX
// it could be anywhere from 1x to 32x
// at 1x, this buffers 5.46ms of data
// and at 32x; 174ms
// 4x sounds reasonable; 21.8ms             (1464 bytes)
// 6x is 32.76 ~ 1 frame (33ms)             (2196 bytes)
// 8x is 43.6ms which is fairly noticeable  (2928 bytes)
// --------
// this total should not exceed 4092 bytes; which is the max supported by ESP32
// which means choices are between 4 and 8
const uint8_t SAMPLES_PER_BUFFER = 6;
uint16_t audiobuf[SAMPLES_PER_DURATION*SAMPLES_PER_BUFFER];

void fill_buffer(uint16_t* buf, Channel* c, uint16_t samples) {
    SFX* _sfx = c->sfx;
    if(_sfx == NULL) {
        return;
    }

    // buffer sizes are always multiples of SAMPLES_PER_DURATION
    // which ensures the notes will always play _entire_ "duration" blocks
    for(uint16_t s=0; s<samples; s++) {
        uint16_t note_id = c->offset / (SAMPLES_PER_DURATION * _sfx->duration);

        Note n = _sfx->notes[note_id];
        z8::fix32 freq = key_to_freq[n.key];
        const z8::fix32 delta = freq / SAMPLE_RATE;

        c->offset += SAMPLES_PER_DURATION;
        if (n.volume == 0) {
            c->phi += SAMPLES_PER_DURATION * delta;
            s += SAMPLES_PER_DURATION-1;
            continue;
        }
        // printf("Note id %d has fx %d\n", note_id, n.effect);
        z8::fix32 volume = n.volume; // can be modified by `n.effect`

        const z8::fix32 norm_vol = VOL_NORMALIZER*volume;
        // const uint16_t n_effect = n.effect; // alias for memory access?
        const uint16_t n_waveform = n.waveform; // alias for memory access?

        for(uint16_t _s=0; _s<SAMPLES_PER_DURATION; _s++) {
            // TODO: apply FX per _sample_ ?? gonna suck
            const z8::fix32 w = waveform(n_waveform, c->phi);
            const int16_t sample = (int16_t)(norm_vol*w);
            uint16_t _offset = (_s+s);

            // NOTE: this is += so that all sfx can be played in parallel
            buf[_offset] += sample;
            if(buf[_offset] < sample) // wrap around
                buf[_offset] = USHRT_MAX;

            c->phi += delta;
        }

        s += SAMPLES_PER_DURATION-1;
    }

    if(c->offset >= (SAMPLES_PER_DURATION*NOTES_PER_SFX*_sfx->duration)) {
        c->sfx      = NULL;
        c->sfx_id   = 0;
        c->offset   = 0;
        c->phi      = 0;
    }
}
