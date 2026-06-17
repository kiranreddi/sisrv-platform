# test_umode_wfi_tw.S — WFI illegal in U when TW=1; legal NOP when TW=0
.include "pmp_csr.inc"
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    PMP_HARNESS_ENTRY0

    # NA4 R|W for pass/fail MMIO at 0x10000000
    li   t0, 0x04000000
    csrw pmpaddr7, t0
    PMP_SET_CFG 7, 0x13, t1, t2

    li   s4, 0

    # TW=1 phase
    csrr t0, mstatus
    li   t1, 0x200000
    or   t0, t0, t1
    csrw mstatus, t0

    la   t0, u_wfi_tw
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, 0xffffe7ff
    and  t1, t1, t2
    li   t3, 0x200000
    or   t1, t1, t3
    csrw mstatus, t1
    mret

u_wfi_tw:
    wfi
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    beqz s4, tw_trap
    li   t1, 8
    bne  t0, t1, fail
    j    pass

tw_trap:
    li   t1, 2
    bne  t0, t1, fail
    addi s4, s4, 1

    # TW=0 phase — WFI should retire as NOP
    csrr t0, mstatus
    li   t1, 0xffdfffff
    and  t0, t0, t1
    csrw mstatus, t0

    la   t0, u_wfi_ok
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, 0xffffe7ff
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_wfi_ok:
    wfi
    ecall
    j    fail

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
