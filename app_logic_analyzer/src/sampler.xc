#include <xs1.h>

/*
 * TODO:
 *  - Don't demangle bits on device, pass mangled data to a host;
 *  - Sync input ports to the rising edge of the clock,
 *    so they are sampled in the same clock cycle. See chapter 5
 *    "Port Buffering" in "XC Programming Guide" (X1009B).
 */

static int _lookuplow[256];
static int _lookuphigh[256];

void sampler_init(void)
{
    for(int i = 0; i < 256; i++) {
        int mask = 0, m;
        for(int k = 1, m = 1 ; k < 16; k <<= 1, m <<= 8) {
            if (k & i) mask |= m;
        }
        _lookuplow[i] = mask;
        for(int k = 16, m = 1 ; k < 256; k <<= 1, m <<= 8) {
            if (k & i) mask |= m;
        }
        _lookuphigh[i] = mask;
    }
}

#pragma unsafe arrays
static inline void _sample_logic_4bit(buffered in port:8 a, buffered in port:8 b, buffered in port:8 c, buffered in port:8 d, int &h, int &l) {
    int tmp;
    a :> tmp;
    l = _lookuplow[tmp];
    h = _lookuphigh[tmp];
    l <<= 1;
    h <<= 1;
    b :> tmp;
    l |= _lookuplow[tmp];
    h |= _lookuphigh[tmp];
    l <<= 1;
    h <<= 1;
    c :> tmp;
    l |= _lookuplow[tmp];
    h |= _lookuphigh[tmp];
    l <<= 1;
    h <<= 1;
    d :> tmp;
    l |= _lookuplow[tmp];
    h |= _lookuphigh[tmp];
}


#pragma unsafe arrays
static void _sample_logic_hi_4bit(buffered in port:8 a, buffered in port:8 b, buffered in port:8 c, buffered in port:8 d, streaming chanend sce_out) {
    while(1) {
        int h, l;
        _sample_logic_4bit(a, b, c, d, h, l);
        h <<= 4;
        sce_out <: h;
        l <<= 4;
        sce_out <: l;
    }
}


#pragma unsafe arrays
static void _sample_logic_low_4bit(buffered in port:8 a, buffered in port:8 b, buffered in port:8 c, buffered in port:8 d, streaming chanend sce_in, streaming chanend sce_out) {
    while(1) {
        int h, l, tmp;
        _sample_logic_4bit(a, b, c, d, h, l);
        sce_in :> tmp;
        sce_out <: h | tmp;
        sce_in :> tmp;
        sce_out <: l | tmp;
    }
}

void sampler_logic_8bit(buffered in port:8 p[8], streaming chanend sce_out) {
    streaming chan sce_samples;
    par {
        _sample_logic_hi_4bit(p[7],p[6],p[5],p[4], sce_samples);
        _sample_logic_low_4bit(p[3],p[2],p[1],p[0], sce_samples, sce_out);
    }
}
