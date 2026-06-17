# test_umode_mpp_warl.S — MPP WARL: 01/10 → 00, 11 stays 11
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    csrr t0, mstatus
    li   t1, ~0x1800
    and  t0, t0, t1
    csrw mstatus, t0

    # MPP = 01 → reads 00
    csrr t0, mstatus
    li   t1, 0x800
    or   t0, t0, t1
    csrw mstatus, t0
    csrr t1, mstatus
    srli t1, t1, 11
    andi t1, t1, 3
    bnez t1, fail

    # MPP = 10 → reads 00
    csrr t0, mstatus
    li   t1, ~0x1800
    and  t0, t0, t1
    li   t1, 0x1000
    or   t0, t0, t1
    csrw mstatus, t0
    csrr t1, mstatus
    srli t1, t1, 11
    andi t1, t1, 3
    bnez t1, fail

    # MPP = 11 stays 11
    csrr t0, mstatus
    li   t1, ~0x1800
    and  t0, t0, t1
    li   t1, 0x1800
    or   t0, t0, t1
    csrw mstatus, t0
    csrr t1, mstatus
    srli t1, t1, 11
    andi t1, t1, 3
    li   t2, 3
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
