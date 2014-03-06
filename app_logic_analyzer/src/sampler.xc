#include <xs1.h>
#include "uart_print.h"
#ifdef OSCILL
#include "usb_tile_support.h"
#endif

/*
 * TODO:
 *  - Don't reorder bits on device, pass data for reorder on a host;
 *  - Sync input ports to the rising edge of the clock,
 *    so they are sampled in the same clock cycle. See chapter 5
 *    "Port Buffering" in "XC Programming Guide" (X1009B).
 */

/* These lookup tables are used to change order of bits in a byte we got from
 * buffered port input.*/
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

#ifdef OSCILL

#ifdef DEBUG
//#define DEBUG_OSCILL
#endif

#define OSCILL_PERIOD   (XS1_TIMER_HZ / 10000)
#ifdef DEBUG_OSCILL
#define PRINT_PERIOD    (XS1_TIMER_HZ / 100)
#endif

#pragma unsafe arrays
void sampler_oscill(const_adc_config_ref_t adc_config, out port p_adc_trigger, chanend c_adc, streaming chanend sce_out)
{
    unsigned int data[4];
    unsigned int value;
#if 0
    unsigned adc_time;
    timer t_adc;
#endif
#ifdef DEBUG_OSCILL
    unsigned print_time;
    timer t_print;
#endif

#if 0
    t_adc :> adc_time;
    adc_time += OSCILL_PERIOD;
#endif
#ifdef DEBUG_OSCILL
    t_print :> print_time;
    print_time += PRINT_PERIOD;
#endif
    while(1) {
        select {
#if 0
        case t_adc when timerafter(adc_time) :> void:
            adc_trigger_packet(p_adc_trigger, adc_config);
            adc_time += OSCILL_PERIOD;
            break;
#endif

        case adc_read_packet(c_adc, adc_config, data):
            value = data[0];
            value |= data[1] << 8;
            value |= data[2] << 16;
            value |= data[3] << 24;
            sce_out <: value;
            break;

#ifdef DEBUG_OSCILL
        case t_print when timerafter(print_time) :> void:
            print_time += PRINT_PERIOD;
            {
                char str[] = "|                                |\r\n";
                static unsigned int prev_val = 0;
                unsigned int val;

                val = data[3] >> 3;
                str[1 + prev_val] = ' ';
                str[1 + val] = '*';
                prev_val = val;
                printstr(str);
            }
            break;
#endif
        }
    }
}
#endif  /* OSCILL */

void sampler(buffered in port:8 p[], const_adc_config_ref_t adc_config, out port p_adc_trigger, chanend c_adc, streaming chanend sce_out)
{
#ifdef OSCILL
    sampler_oscill(adc_config, p_adc_trigger, c_adc, sce_out);
#else
    sampler_logic(p[], sce_out);
#endif
}
