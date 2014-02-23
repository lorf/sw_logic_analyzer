#include <xs1.h>

/*
 * TODO:
 *  - Don't demangle bits on device, pass mangled data to a host;
 *  - Sync input ports to the rising edge of the clock,
 *    so they are sampled in the same clock cycle. See chapter 5
 *    "Port Buffering" in "XC Programming Guide" (X1009B).
 */

static int _lookup_8bit_low[256];
static int _lookup_8bit_hi[256];

void sampler_init(void)
{
    for(int i = 0; i < 256; i++) {
        int mask = 0, m;
        for(int k = 1, m = 1 ; k < 16; k <<= 1, m <<= 8) {
            if (k & i) mask |= m;
        }
        _lookup_8bit_low[i] = mask;
        for(int k = 16, m = 1 ; k < 256; k <<= 1, m <<= 8) {
            if (k & i) mask |= m;
        }
        _lookup_8bit_hi[i] = mask;
    }
}

#pragma unsafe arrays
inline void _sample_logic_1bit(buffered in port:8 a, streaming chanend sce_out) {
    while(1) {
        int tmp;

        a :> tmp;

        sce_out <: _lookup_8bit_hi[tmp];
        sce_out <: _lookup_8bit_low[tmp];
    }
}

#pragma unsafe arrays
inline void _sample_logic_2bit(buffered in port:8 a, buffered in port:8 b, streaming chanend sce_out) {
    while (1) {
        int tmp, h, l;

        a :> tmp;
        h = _lookup_8bit_hi[tmp];
        l = _lookup_8bit_low[tmp];
        b :> tmp;
        sce_out <: (h << 1) | _lookup_8bit_hi[tmp];
        sce_out <: (l << 1) | _lookup_8bit_low[tmp];
    }
}

#pragma unsafe arrays
static inline void _sample_logic_4bit(buffered in port:8 a, buffered in port:8 b, buffered in port:8 c, buffered in port:8 d, streaming chanend sce_out) {
    while(1) {
        int tmp, h, l;

        a :> tmp;
        h = _lookup_8bit_hi[tmp];
        l = _lookup_8bit_low[tmp];
        h <<= 1;
        l <<= 1;
        b :> tmp;
        h |= _lookup_8bit_hi[tmp];
        l |= _lookup_8bit_low[tmp];
        h <<= 1;
        l <<= 1;
        c :> tmp;
        h |= _lookup_8bit_hi[tmp];
        l |= _lookup_8bit_low[tmp];
        d :> tmp;
        sce_out <: (h << 1) | _lookup_8bit_hi[tmp];
        sce_out <: (l << 1) | _lookup_8bit_low[tmp];
    }
}

#pragma unsafe arrays
static inline void _sample_logic_half_8bit(buffered in port:8 a, buffered in port:8 b, buffered in port:8 c, buffered in port:8 d, int &h, int &l) {
    int tmp;
    a :> tmp;
    l = _lookup_8bit_low[tmp];
    h = _lookup_8bit_hi[tmp];
    l <<= 1;
    h <<= 1;
    b :> tmp;
    l |= _lookup_8bit_low[tmp];
    h |= _lookup_8bit_hi[tmp];
    l <<= 1;
    h <<= 1;
    c :> tmp;
    l |= _lookup_8bit_low[tmp];
    h |= _lookup_8bit_hi[tmp];
    l <<= 1;
    h <<= 1;
    d :> tmp;
    l |= _lookup_8bit_low[tmp];
    h |= _lookup_8bit_hi[tmp];
}


#pragma unsafe arrays
static void _sample_logic_8bit_hi(buffered in port:8 a, buffered in port:8 b, buffered in port:8 c, buffered in port:8 d, streaming chanend sce_inter) {
    while(1) {
        int h, l;
        _sample_logic_half_8bit(a, b, c, d, h, l);
        h <<= 4;
        sce_inter <: h;
        l <<= 4;
        sce_inter <: l;
    }
}


#pragma unsafe arrays
static void _sample_logic_8bit_low(buffered in port:8 a, buffered in port:8 b, buffered in port:8 c, buffered in port:8 d, streaming chanend sce_inter, streaming chanend sce_out) {
    while(1) {
        int h, l, tmp;
        _sample_logic_half_8bit(a, b, c, d, h, l);
        sce_inter :> tmp;
        sce_out <: h | tmp;
        sce_inter :> tmp;
        sce_out <: l | tmp;
    }
}

void sampler_logic(buffered in port:8 p[], streaming chanend sce_out) {

#if 0
   streaming chan sce_inter;
   par {
        _sample_logic_8bit_hi(p[7],p[6],p[5],p[4], sce_inter);
        _sample_logic_8bit_low(p[3],p[2],p[1],p[0], sce_inter, sce_out);
   }
#endif

    _sample_logic_4bit(p[3], p[2], p[1], p[0], sce_out);

   /*_sample_logic_1bit(p[7], sce_out);*/
}
