#include <xs1.h>
#include "usb_tile_support.h"

void sampler_init(void);
void sampler_logic(buffered in port:8 p[], streaming chanend sce_out);
#ifdef OSCILL
void sampler_oscill(const_adc_config_ref_t adc_config, out port p_adc_trigger, chanend c_adc, streaming chanend sce_out);
#endif
void sampler(buffered in port:8 p[], const_adc_config_ref_t adc_config, out port p_adc_trigger, chanend c_adc, streaming chanend sce_out);
