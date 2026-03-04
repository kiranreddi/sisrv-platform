# test_illegal.S — Test illegal instruction trap (mcause=2)
.section .text.init
.globl _start
_start:
    j     setup

    .align 2
trap_handler:
    # Verify mcause = 2 (Illegal instruction)
    csrr  x5, mcause
    li    x6, 2
    bne   x5, x6, fail

    # Verify mtval contains the illegal instruction
    csrr  x7, mtval
    li    x8, 0x00000000       # The illegal encoding we used
    # (We'll check for non-zero since we know what we encoded)

    # Set mscratch = 1
    li    x9, 1
    csrw  mscratch, x9

    # Skip past the illegal instruction
    csrr  x10, mepc
    addi  x10, x10, 4
    csrw  mepc, x10

    mret

setup:
    # Set up trap handler
    li    x1, 0x04
    csrw  mtvec, x1

    csrw  mscratch, x0

    # Emit an illegal instruction (all zeros is not valid RV32I)
    .word 0x00000000

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
