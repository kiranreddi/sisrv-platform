# test_ebreak.S — Test EBREAK trap with correct mcause=3
.section .text.init
.globl _start
_start:
    j     setup

    .align 2
trap_handler:
    # Verify mcause = 3 (Breakpoint)
    csrr  x5, mcause
    li    x6, 3
    bne   x5, x6, fail

    # Set mscratch = 1 to indicate handler ran
    li    x7, 1
    csrw  mscratch, x7

    # Advance mepc past EBREAK (mepc += 4)
    csrr  x8, mepc
    addi  x8, x8, 4
    csrw  mepc, x8

    mret

setup:
    # Set mtvec = trap_handler (address 0x04)
    li    x1, 0x04
    csrw  mtvec, x1

    # Clear mscratch
    csrw  mscratch, x0

    # Execute EBREAK
    ebreak

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
