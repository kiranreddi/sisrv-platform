# test_pmp_amo_perm.S — AMO faults on R-only region in U-mode (needs R+W)
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    li   t0, 0x1FFF
    csrw pmpaddr0, t0
    li   t0, 0x1F
    csrw pmpcfg0, t0

    li   t0, 0x20007FFF
    csrw pmpaddr1, t0
    li   t0, 0x19
    csrw pmpcfg1, t0

    li   s6, RAM_BASE
    li   t0, 100
    sw   t0, 0(s6)

    la   t0, u_amo
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, 0xffffe7ff
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_amo:
    li   s6, RAM_BASE
    li   t1, 5
    amoadd.w t0, t1, (s6)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    li   t2, 7
    bne  t0, t2, fail
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
