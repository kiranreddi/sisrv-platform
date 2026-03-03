# test_slt.S — Test SLT, SLTU, SLTI, SLTIU
.section .text.init
.globl _start
_start:
    # SLT (signed)
    addi  x1, x0, -1         # x1 = -1
    addi  x2, x0, 1          # x2 = 1
    slt   x3, x1, x2         # x3 = 1 (-1 < 1)
    addi  x4, x0, 1
    bne   x3, x4, fail

    slt   x5, x2, x1         # x5 = 0 (1 < -1 is false)
    bne   x5, x0, fail

    # SLTU (unsigned)
    sltu  x6, x2, x1         # x6 = 1 (1 < 0xFFFFFFFF unsigned)
    bne   x6, x4, fail

    sltu  x7, x1, x2         # x7 = 0 (0xFFFFFFFF < 1 is false)
    bne   x7, x0, fail

    # SLTI
    slti  x8, x1, 0          # x8 = 1 (-1 < 0)
    bne   x8, x4, fail

    slti  x9, x2, 0          # x9 = 0 (1 < 0 is false)
    bne   x9, x0, fail

    # SLTIU
    sltiu x10, x0, 1         # x10 = 1 (0 < 1 unsigned)
    bne   x10, x4, fail

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
