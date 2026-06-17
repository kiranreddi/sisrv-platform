# test_pmp_lock_immutable.S — locked pmpcfg/pmpaddr writes are ignored
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    li   t0, 0x20007FFF
    csrw pmpaddr0, t0
    li   t0, 0x99
    csrw pmpcfg0, t0

    li   t0, 0x20000000
    csrw pmpaddr0, t0
    li   t0, 0x1B
    csrw pmpcfg0, t0

    csrr t1, pmpaddr0
    li   t2, 0x20007FFF
    bne  t1, t2, fail
    csrr t1, pmpcfg0
    li   t2, 0x99
    bne  t1, t2, fail
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
