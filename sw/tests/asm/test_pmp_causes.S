# test_pmp_causes.S — fetch=1, load=5, store=7 with mtval=addr
.include "pmp_csr.inc"
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    li   s10, 0
    li   s6, RAM_BASE

    PMP_HARNESS_ENTRY0
    li   t0, 0x20007FFF
    csrw pmpaddr1, t0
    PMP_SET_CFG 1, 0x13, t1, t2
    li   t0, 0x00008067
    sw   t0, 0(s6)
    la   t0, u_fetch
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_fetch:
    jalr x0, 0(s6)
    j    fail

u_load:
    lw   t0, 0(s6)
    j    fail

u_store:
    li   t0, 1
    sw   t0, 0(s6)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    csrr t1, mtval
    beqz s10, check_fetch
    li   t2, 1
    beq  s10, t2, check_load
    li   t2, 2
    bne  s10, t2, fail
    li   t3, 7
    bne  t0, t3, fail
    bne  t1, s6, fail
    j    pass

check_fetch:
    li   t3, 1
    bne  t0, t3, fail
    bne  t1, s6, fail
    addi s10, s10, 1
    # ROM only — U load from RAM has no matching entry
    la   t0, u_load
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

check_load:
    li   t3, 5
    bne  t0, t3, fail
    bne  t1, s6, fail
    addi s10, s10, 1
    li   t0, 0x20007FFF
    csrw pmpaddr1, t0
    PMP_SET_CFG 1, 0x19, t1, t2
    la   t0, u_store
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

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
