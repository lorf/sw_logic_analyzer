// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <print.h>
#include <safestring.h>
#include "xud.h"
#include "usb.h"
#include "usb_defs.h"
#include "usb_device.h"
/*#include "DescriptorRequests.h"*/

#define XUD_DESC_STR_USENG     0x0409 // US English

// This devices Device Descriptor:
#define DESC_DEVICE \
{ \
  18, 				     /* 0  bLength : Size of descriptor in Bytes (18 Bytes) */ \
  1,                                 /* 1  bdescriptorType */ \
  0,                                 /* 2  bcdUSB */ \
  2,                                 /* 3  bcdUSB */ \
  0xff,                              /* 4  bDeviceClass */ \
  0xff,                              /* 5  bDeviceSubClass */ \
  0xff,                              /* 6  bDeviceProtocol */ \
  64,                                /* 7  bMaxPacketSize */ \
  0xb1,                              /* 8  idVendor */ \
  0x20,                              /* 9  idVendor */ \
  0x61,                              /* 10 idProduct */ \
  0x10,                              /* 11 idProduct */ \
  0x00,                              /* 12 bcdDevice : Device release number */ \
  0x00,                              /* 13 bcdDevice : Device release number */ \
  0x01,                              /* 14 iManufacturer : Index of manufacturer string */ \
  0x00,                              /* 15 iProduct : Index of product string descriptor */ \
  0x00,                              /* 16 iSerialNumber : Index of serial number decriptor */ \
  0x01                               /* 17 bNumConfigurations : Number of possible configs */ \
}

                                    
#if 0
/* Device Qualifier Descriptor */
#define DESC_DEVQUAL \
{ \
    10,                              /* 0  bLength (10 Bytes) */ \
    DEVICE_QUALIFIER,                /* 1  bDescriptorType */ \
    0,                               /* 2  bcdUSB */ \
    2,                               /* 3  bcdUSB */ \
    2,                               /* 4  bDeviceClass */ \
    0,                               /* 5  bDeviceSubClass */ \
    0,                               /* 6  bDeviceProtocol */ \
    64,                              /* 7  bMaxPacketSize */ \
    0x01,                            /* 8  bNumConfigurations : Number of possible configs */ \
    0x00                             /* 9  bReserved (must be zero) */ \
}
#endif

#define DESC_DEBUG \
{ \
    4, \
    10, \
    0, \
    0 \
}

static unsigned char cfgDesc[] =
{
    /* Configuration descriptor: */ 
    0x09,                               /* 0  bLength */ 
    0x02,                               /* 1  bDescriptorType */ 
    0x27, 0x0,                         /* 2  wTotalLength */ 
    0x01,                               /* 4  bNumInterface: Number of interfaces*/ 
    0x01,                               /* 5  bConfigurationValue */ 
    0x00,                               /* 6  iConfiguration */ 
    0x00,                               /* 7  bmAttributes */ 
    0xFA,                               /* 8  bMaxPower */  

    /*  Interface Descriptor (Note: Must be first with lowest interface number)r */
    0x09,                               /* 0  bLength: 9 */
    0x04,                               /* 1  bDescriptorType: INTERFACE */
    0x00,                               /* 2  bInterfaceNumber */
    0x00,                               /* 3  bAlternateSetting: Must be 0 */
    0x03,                               /* 4  bNumEndpoints (0 or 1 if optional interupt endpoint is present */
    0xff,                               /* 5  bInterfaceClass: VENDOR */
    0xff,                               /* 6  bInterfaceSubClass: VENDOR */
    0xff,                               /* 7  bInterfaceProtocol: VENDOR */
    0x00,                               /* 8  iInterface */ 

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    0x05,                               /* 1  bDescriptorType: ENDPOINT */
    0x01,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x00,                               /* 6  bInterval */

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    0x05,                               /* 1  bDescriptorType: ENDPOINT */
    0x81,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x00,                               /* 6  bInterval */

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    0x05,                               /* 1  bDescriptorType: ENDPOINT */
    0x82,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x00,                               /* 6  bInterval */
};

#define DESC_STR_LANGIDS \
{ \
  XUD_DESC_STR_USENG & 0xff,               /* 2  wLangID[0] */ \
  XUD_DESC_STR_USENG>>8,            /* 3  wLangID[0] */ \
  '\0' \
}

#if 0
/* OtherSpeed Configuration Descriptor */
/* TODO: Move to DeviceDescriptors.h */
uint8 oSpeedCfgDesc[] =
{
    0x09,                              /* 0  bLength */
    OTHER_SPEED_CONFIGURATION,         /* 1  bDescriptorType */
    0x12,                              /* 2  wTotalLength */
    0x00,                              /* 3  wTotalLength */
    0x01,                              /* 4  bNumInterface: Number of interfaces*/
    0x00,                              /* 5  bConfigurationValue */
    0x00,                              /* 6  iConfiguration */
    0x80,                              /* 7  bmAttributes */
    0xFA,                              /* 8  bMaxPower */

    0x09,                              /* 0 bLength : Size of this descriptor, in bytes. (field size 1 bytes) */
    0x04,                              /* 1 bDescriptorType : INTERFACE descriptor. (field size 1 bytes) */
    0x00,                              /* 2 bInterfaceNumber : Index of this interface. (field size 1 bytes) */
    0x00,                              /* 3 bAlternateSetting : Index of this setting. (field size 1 bytes) */
    0x00,                              /* 4 bNumEndpoints : 0 endpoints. (field size 1 bytes) */
    0x00,                              /* 5 bInterfaceClass :  */
    0x00,                              /* 6 bInterfaceSubclass */
    0x00,                              /* 7 bInterfaceProtocol : Unused. (field size 1 bytes) */
    0x00,                              /* 8 iInterface : Unused. (field size 1 bytes) */

};
#endif


//#define STRINGER(x) PRODUCT#x
/* Standard descriptors */
static unsigned char devDesc[] = DESC_DEVICE;
//static unsigned char cfgDesc[] = DESC_CONFIG;
/*static unsigned char devQualDesc[] = DESC_DEVQUAL;*/
//static unsigned char debugDesc[] = DESC_DEBUG;

/* String descriptors */
static unsigned char strDesc_langIDs[] = DESC_STR_LANGIDS;

/* Strings table for string desctiptors. Note: for usabilty unicode and datalengh are dealt with automatically */
/* therefore just the strings are required below. string[0] (langIDs) is a speacial one... */
static unsigned char strDescs[][40] = 
{
    "string0", 				                    /* 0: Place holder for string 0 (LANGIDs) */ 
    "Generic USB",	  		                    /* 1: iManufacturer */ 
}; 



void Endpoint0( chanend c_ep0_out, chanend c_ep0_in, chanend ?c_usb_test)
{
    unsigned char buffer[1024];
    USB_SetupPacket_t sp;
    XUD_BusSpeed usbBusSpeed;

    XUD_ep ep0_out = XUD_InitEp(c_ep0_out);
    XUD_ep ep0_in  = XUD_InitEp(c_ep0_in);

    /* Copy langIDs string desc into string[0] */
    /* TODO: Macro? */
    safememcpy(strDescs[0], strDesc_langIDs, sizeof(strDesc_langIDs));
 
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
#if 0
                    case USB_GET_DESCRIPTOR:
                        /* Inspect which descriptor require (high byte of wValue) */ 
                        switch( sp.wValue & 0xff00 ) {
                            /* HID Report Descriptor */
                        ///case  WVALUE_GETDESC_HID_REPORT:
                            /* Go Get Request protocol */
                           // retVal = XUD_DoGetRequest( ep0_out, ep0_in, hidReportDesc, sizeof( hidReportDesc ));
                            //break;
                        default:
                            XUD_Error( "Unknown descriptor request\n" );
                            break;
                        }
                        break;
#endif
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
                            /* Note: Really we should wait until ACK is received for status stage before changing address
                             * We will just wait some time... */
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

#if 0
                    default:
                        XUD_Error("Unknown device request");
                        break;
#endif
                    }  
                    break;
#if 0
                default: 
                    /* Got a request to a recipient we didn't recognise... */ 
                    //XUD_Error("Unknown Recipient"); 
                    break;
#endif
                }
                break;
#if 0
            default:
                //printstr("ERR: Unknown request: ");
                break;
#endif
            }
        }

        /* If we haven't handled the request about, 
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

  // END control tokens.
  //inct(ep0);
  //inct(ep0_con);
  
  //endpoint1dead();
 //stop_streaming_slave(ep0);
 //stop_streaming_slave(ep0_con);

  //printstrln("ep thread exit");
}
