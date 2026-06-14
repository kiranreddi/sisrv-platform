# test_rv32m.S - Verify RV32M multiply/divide/remainder instructions
.section .text.init
.globl _start
_start:
    # MUL: low half of signed product
    li    x1, 7
    li    x2, -3
    .word 0x022080b3        # mul x1, x1, x2 -> -21
    li    x3, -21
    bne   x1, x3, fail

    # MULH: high half of signed product (-1 * 2 = -2)
    li    x1, -1
    li    x2, 2
    .word 0x022091b3        # mulh x3, x1, x2 -> 0xffffffff
    li    x4, -1
    bne   x3, x4, fail

    # MULHSU: high half of signed * unsigned (-1 * 2 = -2)
    li    x1, -1
    li    x2, 2
    .word 0x0220a1b3        # mulhsu x3, x1, x2 -> 0xffffffff
    bne   x3, x4, fail

    # MULHU: high half of unsigned product (0xffffffff * 2)
    li    x1, -1
    li    x2, 2
    .word 0x0220b1b3        # mulhu x3, x1, x2 -> 1
    li    x4, 1
    bne   x3, x4, fail

    # DIV: signed quotient
    li    x1, -21
    li    x2, 4
    .word 0x0220c1b3        # div x3, x1, x2 -> -5
    li    x4, -5
    bne   x3, x4, fail

    # DIVU: unsigned quotient
    li    x1, 21
    li    x2, 4
    .word 0x0220d1b3        # divu x3, x1, x2 -> 5
    li    x4, 5
    bne   x3, x4, fail

    # REM: signed remainder
    li    x1, -21
    li    x2, 4
    .word 0x0220e1b3        # rem x3, x1, x2 -> -1
    li    x4, -1
    bne   x3, x4, fail

    # REMU: unsigned remainder
    li    x1, 21
    li    x2, 4
    .word 0x0220f1b3        # remu x3, x1, x2 -> 1
    li    x4, 1
    bne   x3, x4, fail

    # Divide-by-zero architectural results
    li    x1, 123
    li    x2, 0
    .word 0x0220c1b3        # div x3, x1, x2 -> -1
    li    x4, -1
    bne   x3, x4, fail
    .word 0x0220e1b3        # rem x3, x1, x2 -> dividend
    li    x4, 123
    bne   x3, x4, fail

    # Signed overflow architectural results: INT_MIN / -1
    li    x1, 0x80000000
    li    x2, -1
    .word 0x0220c1b3        # div x3, x1, x2 -> INT_MIN
    li    x4, 0x80000000
    bne   x3, x4, fail
    .word 0x0220e1b3        # rem x3, x1, x2 -> 0
    bne   x3, x0, fail

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
