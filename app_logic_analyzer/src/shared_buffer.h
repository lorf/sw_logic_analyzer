#ifndef _SHARED_BUFFER_H
#define _SHARED_BUFFER_H

/* 512 comes from XUD? */
#define SHARED_BUFFER_LEN   512  /* Buffer length in bytes */
#define NUM_SHARED_BUFFERS  16
#define SHARED_BUFFERS_LEN  (NUM_SHARED_BUFFERS * SHARED_BUFFER_LEN)

#ifndef SHARED_BUFFER_IMPL
extern unsigned int shared_buffers_int[NUM_SHARED_BUFFERS][SHARED_BUFFER_LEN/4];
extern unsigned char shared_buffers_char[NUM_SHARED_BUFFERS][SHARED_BUFFER_LEN];
#endif

#endif /* _SHARED_BUFFER_H */
