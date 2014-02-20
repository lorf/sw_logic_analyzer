// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <print.h>
#include <safestring.h>
#include "usb_device.h"
#include "read_serial_number.h"

#define DESC_STR_LANGID_USENG     0x0409 // US English

#define VENDOR_ID           0x20b1
#if defined(TARGET_BOARD_XTAG2)
#   define DEVICE_ID        0xf7d1
#elif defined(TARGET_BOARD_STARTKIT)
#   define DEVICE_ID        0xf7d3
#else
#   define DEVICE_ID        0x1061
#endif
/* Device release number */
#define BCD_DEVICE          0x0001

#define MANUFACTURER_STR    "XMOS"
#if defined(TARGET_BOARD_XTAG2)
#   define PRODUCT_STR      "XTAG-2 LA"
#elif defined(TARGET_BOARD_STARTKIT)
#   define PRODUCT_STR      "startKIT LA"
#else
#   define PRODUCT_STR      "Unknown"
#endif

/* Strings table for string desctiptors. Note: for usabilty unicode and
 * datalengh are dealt with automatically, therefore just the strings are
 * required below. string[0] (langIDs) is a speacial one... */

static unsigned char strDescs[][40] = {
    {
        DESC_STR_LANGID_USENG & 0xff,
        DESC_STR_LANGID_USENG >> 8,
        0,
    },                  /* 0: wLANGID */
    MANUFACTURER_STR,   /* 1: iManufacturer */
    PRODUCT_STR,        /* 2: iProduct */
    "Serial#",          /* 3: Placeholder for iSerialNumber */
};

#define LANGIDS_STR_IDX         0
#define MANUFACTURER_STR_IDX    1
#define PRODUCT_STR_IDX         2
#define SERIAL_STR_IDX          3

/* USB Device Descriptor */
static unsigned char devDesc[] =
{
    18,                     /* 0  bLength : Size of descriptor in Bytes (18 Bytes) */
    USB_DEVICE,             /* 1  bdescriptorType */
    0x00,                   /* 2  bcdUSB, USB 2.0 */
    0x02,                   /* 3  bcdUSB, USB 2.0 */
    0xff,                   /* 4  bDeviceClass: Vendor */
    0xff,                   /* 5  bDeviceSubClass: Vendor */
    0xff,                   /* 6  bDeviceProtocol: Vendor */
    64,                     /* 7  bMaxPacketSize */
    (VENDOR_ID & 0xff),     /* 8  idVendor */
    (VENDOR_ID >> 8),       /* 9  idVendor */
    (DEVICE_ID & 0xff),     /* 10 idProduct */
    (DEVICE_ID >> 8),       /* 11 idProduct */
    (BCD_DEVICE & 0xff),    /* 12 bcdDevice : Device release number */
    (BCD_DEVICE >> 8),      /* 13 bcdDevice : Device release number */
    MANUFACTURER_STR_IDX,   /* 14 iManufacturer : Index of manufacturer string */
    PRODUCT_STR_IDX,        /* 15 iProduct : Index of product string descriptor */
    SERIAL_STR_IDX,         /* 16 iSerialNumber : Index of serial number decriptor */
    0x01                    /* 17 bNumConfigurations : Number of possible configs */
};

static unsigned char cfgDesc[] =
{
    /* Configuration descriptor: */ 
    0x09,                               /* 0  bLength */ 
    USB_CONFIGURATION,                  /* 1  bDescriptorType */ 
    0x27, 0x00,                         /* 2  wTotalLength */ 
    0x01,                               /* 4  bNumInterface: Number of interfaces*/ 
    0x01,                               /* 5  bConfigurationValue */ 
    0x00,                               /* 6  iConfiguration */ 
    0x80,                               /* 7  bmAttributes: Self-powered */ 
    0xFA,                               /* 8  bMaxPower: 500 mA */  

    /*  Interface Descriptor (Note: Must be first with lowest interface number) */
    0x09,                               /* 0  bLength: 9 */
    USB_INTERFACE,                      /* 1  bDescriptorType: INTERFACE */
    0x00,                               /* 2  bInterfaceNumber */
    0x00,                               /* 3  bAlternateSetting: Must be 0 */
    0x03,                               /* 4  bNumEndpoints */
    0xff,                               /* 5  bInterfaceClass: VENDOR */
    0xff,                               /* 6  bInterfaceSubClass: VENDOR */
    0xff,                               /* 7  bInterfaceProtocol: VENDOR */
    0x00,                               /* 8  iInterface */ 

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    USB_ENDPOINT,                       /* 1  bDescriptorType: ENDPOINT */
    0x01,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,                               /* 3  bmAttributes: Bulk */
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x00,                               /* 6  bInterval */

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    USB_ENDPOINT,                       /* 1  bDescriptorType: ENDPOINT */
    0x81,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,                               /* 3  bmAttributes: Bulk */
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x00,                               /* 6  bInterval */

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    USB_ENDPOINT,                       /* 1  bDescriptorType: ENDPOINT */
    0x82,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,                               /* 3  bmAttributes: Bulk */
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x00,                               /* 6  bInterval */
};

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in, chanend ?c_usb_test)
{
    unsigned char buffer[1024];
    USB_SetupPacket_t sp;
    XUD_BusSpeed usbBusSpeed;

    XUD_ep ep0_out = XUD_InitEp(c_ep0_out);
    XUD_ep ep0_in  = XUD_InitEp(c_ep0_in);

    /* Read serial number from OTP */
    read_serial_number(strDescs[SERIAL_STR_IDX], sizeof(strDescs[SERIAL_STR_IDX]));

    while(1)
    {
        /* Returns 0 on success, < 0 for USB RESET */
        int retVal = USB_GetSetupPacket(ep0_out, ep0_in, sp);

        if (retVal == 0) {
            /*
             * Set retVal to non-zero, we expect it to get set to 0
             * if a request is handled
             */
            retVal = 1;

            switch(sp.bmRequestType.Type) {
            case USB_BM_REQTYPE_TYPE_STANDARD:
                switch(sp.bmRequestType.Recipient) {
                case USB_BM_REQTYPE_RECIP_INTER:
                    switch(sp.bRequest) {
                        /* Set Interface */
                    case USB_SET_INTERFACE:
                        /* TODO: Set the interface */
                        /* No data stage for this request, just do data stage */
                        retVal = XUD_DoSetRequestStatus(ep0_in);
                        break;
                        /* Get descriptor */ 
                    }
                    break;
                    /* Recipient: Device */
                case USB_BM_REQTYPE_RECIP_DEV:
                    /* Standard Device requests (8) */
                    switch( sp.bRequest ) {      
                        /* TODO Check direction */
                        /* Standard request: SetConfiguration */
                    case USB_SET_CONFIGURATION:
                        /* TODO: Set the config */
                        /* No data stage for this request, just do status stage */
                        retVal = XUD_DoSetRequestStatus(ep0_in);
                        break;
                    case USB_GET_CONFIGURATION:
                        buffer[0] = 1;
                        retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 1, sp.wLength);
                        break; 
                        
                        /* Set Device Address: This is a unique set request. */
                    case USB_SET_ADDRESS:
                        /* Status stage: Send a zero length packet */
                        retVal = XUD_DoSetRequestStatus(ep0_in);
                        if (retVal >= 0) {
                            /* Note: Really we should wait until ACK is
                             * received for status stage before changing
                             * address.  We will just wait some time... */
                            {
                                timer t;
                                unsigned time;
                                t :> time;
                                t when timerafter(time+50000) :> void;
                            }
                            /* Set device address in XUD */
                            XUD_SetDevAddr(sp.wValue);
                            retVal = 0;
                        }
                        break;
                    case USB_GET_STATUS:

                        buffer[0] = 0; // bus powered
                        buffer[1] = 0; // remote wakeup not supported
                        
                        retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer,  2, sp.wLength);
                        break;
                    }  
                    break;
                }
                break;
            }
        }

        /* If we haven't handled the request above, 
         * then do standard enumeration requests  */
        if (retVal > 0) {

            /* Returns  0 if handled okay,
             *          1 if request was not handled (STALLed),
             *         -1 for USB Reset */
            retVal = USB_StandardRequests(ep0_out, ep0_in, devDesc,
                    sizeof(devDesc), cfgDesc, sizeof(cfgDesc),
                    null, 0, null, 0, strDescs, sp, c_usb_test,
                    usbBusSpeed);
        }

        /* USB bus reset detected, reset EP and get new bus speed */
        if (retVal < 0) {
            usbBusSpeed = XUD_ResetEndpoint(ep0_in, ep0_out);
        }
    }
}
