# test_shift.S — Test SLL, SRL, SRA, SLLI, SRLI, SRAI
.section .text.init
.globl _start
_start:
    # SLL
    addi  x1, x0, 1
    addi  x2, x0, 4
    sll   x3, x1, x2         # x3 = 1 << 4 = 16
    addi  x4, x0, 16
    bne   x3, x4, fail

    # SRL (logical right shift)
    li    x5, 0x80000000      # MSB set
    addi  x6, x0, 4
    srl   x7, x5, x6         # x7 = 0x08000000 (logical shift)
    li    x8, 0x08000000
    bne   x7, x8, fail

    # SRA (arithmetic right shift)
    sra   x9, x5, x6         # x9 = 0xF8000000 (sign-extended)
    li    x10, 0xF8000000
    bne   x9, x10, fail

    # SLLI
    slli  x11, x1, 8         # x11 = 1 << 8 = 256
    addi  x12, x0, 256
    bne   x11, x12, fail

    # SRLI
    li    x13, 0xFF000000
    srli  x14, x13, 24       # x14 = 0xFF
    addi  x15, x0, 0xFF
    bne   x14, x15, fail

    # SRAI
    li    x16, 0x80000000
    srai  x17, x16, 16       # x17 = 0xFFFF8000
    li    x18, 0xFFFF8000
    bne   x17, x18, fail

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
