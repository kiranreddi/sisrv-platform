# test_pmp_locked_in_m.S — Locked entry denies M-mode store without W
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    li   t0, 0x20007FFF
    csrw pmpaddr0, t0
    li   t0, 0x99
    csrw pmpcfg0, t0

    li   s6, RAM_BASE
    li   t1, 0xAABBCCDD
    sw   t1, 0(s6)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    li   t1, 7
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
