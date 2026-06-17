# test_umode_mprv.S — MPRV=1 uses MPP for load/store permission checks
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    li   s6, RAM_BASE
    li   t0, 0x12345678
    sw   t0, 0(s6)

    # TOR R-only region [0, 0x80001000) — covers RAM, no W for U
    li   t0, 0x20000400
    csrw pmpaddr0, t0
    li   t0, 0x09
    csrw pmpcfg0, t0

    # MPP=U (already 0), MPRV=1
    csrr t0, mstatus
    li   t1, 0x20000
    or   t0, t0, t1
    csrw mstatus, t0

    li   s5, 0
    li   t1, 0xAABBCCDD
    sw   t1, 0(s6)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    beqz s5, mprv_fault
    j    fail

mprv_fault:
    li   t1, 7
    bne  t0, t1, fail
    addi s5, s5, 1

    csrr t0, mstatus
    li   t1, ~0x20000
    and  t0, t0, t1
    csrw mstatus, t0

    li   t1, 0xAABBCCDD
    sw   t1, 0(s6)
    lw   t2, 0(s6)
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
