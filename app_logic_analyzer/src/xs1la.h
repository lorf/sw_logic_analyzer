#ifndef _XS1LA_H
#define _XS1LA_H

#ifdef _XS1LA_IMPL

#define VERSION_MAJOR   0
#define VERSION_MINOR   1

#if defined(TARGET_BOARD_XTAG2)
#define HWINFO_BOARD    XS1LA_BRD_XTAG2
#define HWINFO_REVISION 0   /* Of unknown revision */
#elif defined(TARGET_BOARD_STARTKIT)
#define HWINFO_BOARD    XS1LA_BRD_STARTKIT
#define HWINFO_REVISION 0   /* Of unknown revision */
#endif

#endif /* _XS1LA_IMPL */

enum xs1la_cmd {
    XS1LA_CMD_SET_CONFIG = 0,
    XS1LA_CMD_GET_FWINFO,   /* Get firmware version */
    XS1LA_CMD_GET_HWINFO,   /* Get hardware info */
};

struct xs1la_ctl_config {
    unsigned char divider;
    unsigned char sample_bit_width;
};

struct xs1la_ctl_fwinfo {
    unsigned char version_major;
    unsigned char version_minor;
};

enum xs1la_boards {
    XS1LA_BRD_XTAG2 = 0,
    XS1LA_BRD_STARTKIT,
};

struct xs1la_ctl_hwinfo {
    unsigned char board;
    unsigned char revision;  /* 0 for unknown */
};

#endif /* _XS1LA_H */
