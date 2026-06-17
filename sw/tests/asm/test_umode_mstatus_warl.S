# test_umode_mstatus_warl.S — only MIE/MPIE/MPRV/TW/MPP writable in mstatus
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define MSTATUS_WMASK 0x00221888

_start:
    li   t0, -1
    csrw mstatus, t0
    csrr t1, mstatus
    li   t2, MSTATUS_WMASK
    and  t1, t1, t2
    bne  t1, t2, fail

    csrr t3, mstatus
    li   t4, ~MSTATUS_WMASK
    and  t3, t3, t4
    bnez t3, fail

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
