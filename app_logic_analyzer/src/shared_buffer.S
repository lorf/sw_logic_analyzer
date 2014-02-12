#define SHARED_BUFFER_IMPL
#include "shared_buffer.h"

.section .dp.bss, "awd", @nobits

.align 4

.globl shared_buffers_int
.globl shared_buffers_char
shared_buffers_int:
shared_buffers_char:
  .space SHARED_BUFFERS_LEN
