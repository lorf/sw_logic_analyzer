// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <syscall.h>
#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <stdio.h>
#include "xud.h"
#include "usb.h"
#ifdef DEBUG
#include "uart_print.h"
#endif

#include "sampler.h"
#include "endpoint0.h"
#include "shared_buffer.h"

#define _XS1LA_IMPL
#include "xs1la.h"

#define ARRAY_SIZE(a)   (sizeof(a) / sizeof(a[0]))

#ifdef DEBUG
#define DEBUG_PRINTF(...)   printf(__VA_ARGS__);
#else
#define DEBUG_PRINTF(...)   /* Empty */
#endif

#define USB_HOST_BUF_LEN    512

/* Endpoint type tables */
XUD_EpType epTypeTableOut[1] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE,
}; 

XUD_EpType epTypeTableIn[2] = {   XUD_EPTYPE_CTL | XUD_STATUS_ENABLE,
                                  XUD_EPTYPE_BUL | XUD_STATUS_ENABLE,
};

/* USB Port declarations */
#if (XUD_SERIES_SUPPORT == XUD_L_SERIES)

    /* USB reset port declarations for L series */
    on USB_TILE: out port p_usb_rst   = XS1_PORT_1I;
    on USB_TILE: clock    clk_usb_rst = XS1_CLKBLK_3;

#else   /* XUD_U_SERIES implied */

    /* USB Reset not required for U series - pass null to XUD */
#   define p_usb_rst    null
#   define clk_usb_rst  null

#endif

clock clk_sampling = XS1_CLKBLK_2;  /* Was XS1_CLKBLK_4, but it is used
                                     * in XUD on U-series chips. */

#if defined(TARGET_BOARD_XTAG2)

/*
 * These port declarations are specific to the XTAG2, the pins on the XK-1
 * are pins 0-7 in order, starting at pin 3 on the connector, follow the
 * top row all the way to pin 17. Use any of pins 4, 8, 12, 16, or 20 as
 * ground.
 */
buffered in port:8 sample_pins[] = {
    /* Port order: LSB to MSB */

    XS1_PORT_1L, // Pin 3 on the connector
    XS1_PORT_1A, // Pin 5 on the connector
    XS1_PORT_1C, // Pin 7 on the connector
    XS1_PORT_1D, // Pin 9 on the connector

#if 0
    XS1_PORT_1K, // Pin 11 on the connector
    XS1_PORT_1B, // Pin 13 on the connector
    XS1_PORT_1M, // Pin 15 on the connector
    XS1_PORT_1J, // Pin 17 on the connector
#endif
};

#elif defined(TARGET_BOARD_STARTKIT)

/*
 * These port declarations are specific to the startKIT.
 */
buffered in port:8 sample_pins[] = {
    /* Port order: LSB to MSB */

    XS1_PORT_1A, // Pin CLK on J6
    XS1_PORT_1B, // Pin nRST on J6
    XS1_PORT_1C, // Pin DIG0 on J5
    XS1_PORT_1D, // Pin DIG1 on J5

#if 0
    XS1_PORT_1E, // Pin I (#5) on TP1
    XS1_PORT_1F, // Pin S (#6) on TP1
    XS1_PORT_1G, // Pin K (#7) on TP1
    XS1_PORT_1L, // Pin O (#9) on TP1
#endif
};

#else
#error "You need to define a target"
#endif


#pragma unsafe arrays
void buffer_thread(chanend ce_xfer_thread, streaming chanend sce_sampler) {
    unsigned int sample_val;
    unsigned xfer_signal;
    unsigned write_ptr = 0;
    int buf_num = 0;
    int read_num = 0;
    int asked = 0;
    
    while (1) {
        select {
        /* Receive sync from USB output thread */
        case inuint_byref(ce_xfer_thread, xfer_signal):
            if (!xfer_signal) {
                return;
            }
            if (buf_num == read_num) {
                asked = 1;
            } else {
                outuchar(ce_xfer_thread, read_num);
                read_num = read_num + 1;
                if (read_num == NUM_SHARED_BUFFERS)
                    read_num = 0;
            }
            break;
            
        case sce_sampler :> sample_val:
            shared_buffers_int[buf_num][write_ptr] = sample_val;
            write_ptr++;
            if (write_ptr >= SHARED_BUFFER_LEN/4) {
                /* Buffer is filled */
                if (asked) {
                    /* Notify USB output thread */
                    outuchar(ce_xfer_thread, buf_num);
                    asked = 0;
                } else {
                    buf_num = buf_num + 1;
                    if (buf_num == NUM_SHARED_BUFFERS)
                        buf_num = 0;
                }
                write_ptr = 0;
            }
            break;
        }
    }
}

void ep_data_out(chanend ce_to_host, chanend ce_cmd) {
    unsigned char buf_num;
    int datalength;

    XUD_ep ep_to_host = XUD_InitEp(ce_to_host);
    
    /* Send sync to buffer thread */
    outuint(ce_cmd, 1);
    while (1) {
        /* Receive buffer number from buffer thread */
        inuchar_byref(ce_cmd, buf_num);
        /* Output buffer to the host. */
        datalength = XUD_SetBuffer(ep_to_host, shared_buffers_char[(int)buf_num], SHARED_BUFFER_LEN);
        /* Send sync to buffer thread */
        outuint(ce_cmd, 1);

        if (datalength < 0) {
            XUD_ResetEndpoint(ep_to_host, null);
        }
    }
}

#if 0
/*
 * TODO:
 *  - Start/stop sampling commands.
 */
void endpoint1_cmd(chanend ce_from_host, chanend ce_to_host, clock clk_sampling) {
    /* XXX: do we need whole 512 bytes buffer? */
    unsigned char buffer[USB_HOST_BUF_LEN];
    unsigned char div, sample_width;

    XUD_ep ep_from_host = XUD_InitEp(ce_from_host);
    XUD_ep ep_to_host = XUD_InitEp(ce_to_host);
    
    while (1) {
        int datalength = XUD_GetBuffer(ep_from_host, buffer);
        if (datalength > 0) {
            switch(buffer[0]) {
            case XS1LA_CMD_SET_CONFIG:
                div = buffer[1];
                sample_width = buffer[2];

                /* Configure clock with the divider.
                 * Clock rate is 100 MHz / (2 * div),
                 * according to section 1.2 "Clock blocks"
                 * of "Introduction to XS1 ports". */
                stop_clock(clk_sampling);
                configure_clock_ref(clk_sampling, div);
                start_clock(clk_sampling);

                datalength = 0;
                break;
            default:        // unknown command, ignore without ack
                datalength = 0;
                break;
            }
            /* Prepare data for a host to read. */
            if (datalength) {
                datalength = XUD_SetBuffer(ep_to_host, buffer, datalength);
            }
        }

        if (datalength < 0) {
            XUD_ResetEndpoint(ep_from_host, ep_to_host);
        }
    }
}
#endif

#ifdef DEBUG
out port uart_print_tx_port = on tile[0] : XS1_PORT_1G; /* TCK, TP1 pin 7 (K) */
#endif

int main() {
    chan c_ep_out[1];
    chan c_ep_in[2];
    chan c_buf_usb_out_cmd;
    streaming chan sc_sampler2buf_xfer;

#ifdef DEBUG
    uart_print_init(115200);
#endif

    sampler_init();

    for (int i = 0; i < ARRAY_SIZE(sample_pins); i++) {
        set_port_pull_down(sample_pins[i]);
        configure_in_port(sample_pins[i], clk_sampling);
    }

    /* Set 1 MHz clock rate by default.
     * Clock rate is 100 MHz / (2 * div),
     * according to section 1.2 "Clock blocks"
     * of "Introduction to XS1 ports". */
    configure_clock_ref(clk_sampling, 50);
    start_clock(clk_sampling);

    par {
        /* USB manager thread */
        XUD_Manager(c_ep_out, 1, c_ep_in, 2,
                     null, epTypeTableOut, epTypeTableIn,
                     p_usb_rst, clk_usb_rst, -1, XUD_SPEED_HS, null,
                     XUD_PWR_BUS);
        /* Generic endpoint 0 thread, USB config */
        Endpoint0( c_ep_out[0], c_ep_in[0], null, clk_sampling);
        /* Get commands from USB */
        /*endpoint1_cmd(c_ep_out[1], c_ep_in[1], clk_sampling);*/
        /* USB output thread. Buffers, shared with buffer thread,
         * are transferred to the host via USB */
        ep_data_out(c_ep_in[1], c_buf_usb_out_cmd);
        /* Read from sampler thread, add to a buffer shared with transfer thread */
        buffer_thread(c_buf_usb_out_cmd, sc_sampler2buf_xfer);
        /* Sampler thread, output to buffer thread.
         * Starts another thread to sample 4 channels per thread in parallel. */
        sampler_logic(sample_pins, sc_sampler2buf_xfer);
    }

    return 0;
}
