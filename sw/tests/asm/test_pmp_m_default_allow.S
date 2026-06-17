# test_pmp_m_default_allow.S — M-mode with no matching PMP entry is allowed
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    li   s6, RAM_BASE
    li   t0, 0xDEADBEEF
    sw   t0, 0(s6)
    lw   t1, 0(s6)
    bne  t0, t1, fail
    j    pass

pass:
    li   x10, 1
    li   x11, PASS_ADDR
    sw   x10, 0(x11)
1:  j    1b

fail:
    li   x10, 0
    li   x11, PASS_ADDR
    sw   x10, 0(x11)
1:  j    1b
