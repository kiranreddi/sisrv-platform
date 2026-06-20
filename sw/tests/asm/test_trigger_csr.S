# test_trigger_csr.S — Trigger Module CSR encoding: tinfo, type field, WARL, tselect, 2 triggers
.section .text.init
.globl _start
#define PASS_ADDR 0x10000000

_start:
    # tinfo: type-2 (mcontrol) supported -> bit 2 set
    csrr t0, 0x7a4
    li   t1, 0x4
    bne  t0, t1, fail

    # tselect = 0; write tdata1 all-ones, confirm WARL keeps only supported fields and
    # the read reconstructs type=2 in [31:28].
    csrw 0x7a0, x0
    li   t0, 0xFFFFFFFF
    csrw 0x7a1, t0
    csrr t0, 0x7a1
    li   t1, 0x2010004F      # type(2)<<28 | hit(0x100000) | m/u/x/s/l(0x4F)
    bne  t0, t1, fail

    # clear it back; confirm action/match bits did not stick (they are forced 0)
    csrw 0x7a1, x0
    csrr t0, 0x7a1
    li   t1, 0x20000000      # type 2, no fields
    bne  t0, t1, fail

    # tselect clamps to < NTRIGGER (=2): writing 2 must not stick (stays 0)
    li   t0, 2
    csrw 0x7a0, t0
    csrr t0, 0x7a0
    bnez t0, fail

    # two independent triggers via tselect
    csrw 0x7a0, x0
    li   t0, 0x44            # exec|m
    csrw 0x7a1, t0
    li   t0, 0xCAFE0000
    csrw 0x7a2, t0
    li   t0, 1
    csrw 0x7a0, t0          # tselect = 1
    li   t0, 0x41           # load|m
    csrw 0x7a1, t0
    li   t0, 0xBEEF0000
    csrw 0x7a2, t0

    # read back trigger 1
    csrr t0, 0x7a2
    li   t1, 0xBEEF0000
    bne  t0, t1, fail
    csrr t0, 0x7a1
    li   t1, 0x20000041     # type2 | load|m (hit=0, never fired)
    bne  t0, t1, fail
    # switch to trigger 0, confirm it is independent
    csrw 0x7a0, x0
    csrr t0, 0x7a2
    li   t1, 0xCAFE0000
    bne  t0, t1, fail
    csrr t0, 0x7a1
    li   t1, 0x20000044     # type2 | exec|m (hit=0, never fired)
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
