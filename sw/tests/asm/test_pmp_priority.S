# test_pmp_priority.S — lowest-index matching entry wins
.include "pmp_csr.inc"
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    PMP_HARNESS_ENTRY0

    # Entry 1: R-only NAPOT over RAM (deny store)
    li   t0, 0x20007FFF
    csrw pmpaddr1, t0
    PMP_SET_CFG 1, 0x19, t1, t2

    # Entry 2: R|W NAPOT over same RAM (ignored — higher index)
    li   t0, 0x20007FFF
    csrw pmpaddr2, t0
    PMP_SET_CFG 2, 0x1B, t1, t2

    la   t0, u_store
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_store:
    li   s6, RAM_BASE
    li   t0, 1
    sw   t0, 0(s6)
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
