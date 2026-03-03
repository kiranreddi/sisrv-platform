# test_ecall.S — Test ECALL trap handling
# Layout: trap_handler placed right after _start's first jump
.section .text.init
.globl _start
_start:
    j     setup                # 0x00: jump past trap handler

    .align 2
trap_handler:                  # 0x04: trap handler
    csrr  x5, mcause
    li    x6, 11
    bne   x5, x6, fail

    li    x7, 1
    csrw  mscratch, x7

    csrr  x8, mepc
    addi  x8, x8, 4
    csrw  mepc, x8

    mret

setup:
    # Set mtvec = 0x04 (address of trap_handler)
    li    x1, 0x04
    csrw  mtvec, x1

    # Clear mscratch
    csrw  mscratch, x0

    # Execute ECALL — should trap to trap_handler
    ecall

    # After MRET returns here:
    csrr  x3, mscratch
    li    x4, 1
    bne   x3, x4, fail

    # PASS
    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
