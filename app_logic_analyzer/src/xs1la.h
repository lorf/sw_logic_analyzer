#ifndef _XS1LA_H
#define _XS1LA_H

enum xs1la_cmd {
    XS1LA_CMD_SET_CONFIG = 0,    /* 3 bytes */
};

struct xs1la_cmd_set_config {
    unsigned char divider;
    unsigned char sample_width;
};

#endif /* _XS1LA_H */
