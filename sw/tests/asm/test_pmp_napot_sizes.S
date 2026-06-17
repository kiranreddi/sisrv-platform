# test_pmp_napot_sizes.S — NAPOT 8B and 4KB boundary checks in U-mode
.include "pmp_csr.inc"
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    PMP_HARNESS_ENTRY0

    li   s9, 0

    # 8-byte NAPOT R|W at RAM_BASE: pmpaddr = 0x20000000 (t=0)
    li   t0, 0x20000000
    csrw pmpaddr1, t0
    PMP_SET_CFG 1, 0x1B, t1, t2

    la   t0, u_8b
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_8b:
    li   s6, RAM_BASE
    lw   t0, 0(s6)
    lw   t0, 4(s6)
    lw   t0, 8(s6)
    j    fail

u_4k:
    li   s6, RAM_BASE
    lw   t0, 0(s6)
    li   t1, 0xFFC
    add  t2, s6, t1
    lw   t0, 0(t2)
    li   t1, 0x1000
    add  t2, s6, t1
    lw   t0, 0(t2)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    li   t1, 5
    bne  t0, t1, fail
    beqz s9, after_8b
    j    pass

after_8b:
    addi s9, s9, 1
    # 4KB NAPOT at RAM_BASE: pmpaddr = 0x200001FF
    li   t0, 0x200001FF
    csrw pmpaddr1, t0
    PMP_SET_CFG 1, 0x1B, t1, t2
    la   t0, u_4k
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
