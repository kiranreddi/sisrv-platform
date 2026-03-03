# test_alu_edge.S — ALU edge-case / corner-case tests
# Tests overflow, INT_MIN, INT_MAX, zero operands for all ALU ops
.section .text.init
.globl _start
_start:
    # ---- ADD overflow (positive + positive -> negative) ----
    li    x1, 0x7FFFFFFF       # INT_MAX
    addi  x2, x0, 1
    add   x3, x1, x2           # 0x7FFFFFFF + 1 = 0x80000000 (wraps to INT_MIN)
    li    x4, 0x80000000
    bne   x3, x4, fail

    # ---- ADD overflow (negative + negative -> positive wrap) ----
    li    x1, 0x80000000       # INT_MIN
    li    x2, 0x80000000
    add   x3, x1, x2           # wraps to 0
    bne   x3, x0, fail

    # ---- SUB overflow (INT_MIN - 1 = INT_MAX) ----
    li    x1, 0x80000000
    addi  x2, x0, 1
    sub   x3, x1, x2           # 0x80000000 - 1 = 0x7FFFFFFF
    li    x4, 0x7FFFFFFF
    bne   x3, x4, fail

    # ---- SUB: x - x = 0 ----
    li    x1, 0xDEADBEEF
    sub   x2, x1, x1
    bne   x2, x0, fail

    # ---- ADD with zero ----
    li    x1, 0x12345678
    add   x2, x1, x0
    bne   x1, x2, fail

    # ---- ADDI sign-extend edge: -2048 ----
    addi  x1, x0, -2048        # minimum I-immediate
    li    x2, 0xFFFFF800
    bne   x1, x2, fail

    # ---- ADDI: +2047 ----
    addi  x1, x0, 2047
    li    x2, 0x000007FF
    bne   x1, x2, fail

    # ---- SLL by 0 (no shift) ----
    li    x1, 0xAAAAAAAA
    slli  x2, x1, 0
    bne   x1, x2, fail

    # ---- SLL by 31 (shift all to MSB) ----
    addi  x1, x0, 1
    slli  x2, x1, 31
    li    x3, 0x80000000
    bne   x2, x3, fail

    # ---- SRL by 31 ----
    li    x1, 0x80000000
    srli  x2, x1, 31
    addi  x3, x0, 1
    bne   x2, x3, fail

    # ---- SRA by 31 (all sign bits) ----
    li    x1, 0x80000000
    srai  x2, x1, 31
    li    x3, 0xFFFFFFFF
    bne   x2, x3, fail

    # ---- SRA positive number (zero-fills) ----
    li    x1, 0x7FFFFFFF
    srai  x2, x1, 31
    bne   x2, x0, fail

    # ---- XOR self = 0 ----
    li    x1, 0xDEADBEEF
    xor   x2, x1, x1
    bne   x2, x0, fail

    # ---- OR with 0 ----
    li    x1, 0xCAFEBABE
    or    x2, x1, x0
    bne   x2, x1, fail

    # ---- AND with all-ones ----
    li    x1, 0xCAFEBABE
    li    x2, 0xFFFFFFFF
    and   x3, x1, x2
    bne   x3, x1, fail

    # ---- AND with 0 = 0 ----
    li    x1, 0xCAFEBABE
    and   x2, x1, x0
    bne   x2, x0, fail

    # ---- SLT: INT_MIN < INT_MAX ----
    li    x1, 0x80000000
    li    x2, 0x7FFFFFFF
    slt   x3, x1, x2
    addi  x4, x0, 1
    bne   x3, x4, fail

    # ---- SLT: equal values ----
    li    x1, 42
    slt   x2, x1, x1
    bne   x2, x0, fail

    # ---- SLTU: 0 < 1 ----
    sltu  x1, x0, x4            # x4 = 1
    bne   x1, x4, fail

    # ---- SLTU: 0xFFFFFFFF not < 0 ----
    li    x1, 0xFFFFFFFF
    sltu  x2, x1, x0
    bne   x2, x0, fail

    # ---- SLTU: 0 not < 0 ----
    sltu  x1, x0, x0
    bne   x1, x0, fail

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
