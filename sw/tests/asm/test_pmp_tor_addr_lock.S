# test_pmp_tor_addr_lock.S — TOR+L on entry i+1 blocks pmpaddr[i] write
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    li   t0, 0x20000000
    csrw pmpaddr0, t0
    li   t0, 0x00
    csrw pmpcfg0, t0

    li   t0, 0x20000400
    csrw pmpaddr1, t0
    li   t0, 0x89
    csrw pmpcfg1, t0

    li   t0, 0x20001000
    csrw pmpaddr0, t0

    csrr t1, pmpaddr0
    li   t2, 0x20000000
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
