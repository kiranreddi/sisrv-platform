# test_load_store.S — Test LW, LH, LHU, LB, LBU, SW, SH, SB
.section .text.init
.globl _start
_start:
    # Set up RAM base address
    li    x20, 0x80000000     # RAM base

    # ---- SW / LW test ----
    li    x1, 0xDEADBEEF
    sw    x1, 0(x20)          # store word
    lw    x2, 0(x20)          # load word
    bne   x1, x2, fail

    # ---- SW at offset / LW ----
    li    x3, 0x12345678
    sw    x3, 4(x20)          # store at offset 4
    lw    x4, 4(x20)
    bne   x3, x4, fail

    # ---- SH / LH / LHU test ----
    li    x5, 0xABCD
    sh    x5, 8(x20)          # store halfword at offset 8
    lh    x6, 8(x20)          # load halfword (sign-extended)
    # 0xABCD sign-extended = 0xFFFFABCD
    li    x7, 0xFFFFABCD
    bne   x6, x7, fail

    lhu   x8, 8(x20)          # load halfword unsigned
    li    x9, 0x0000ABCD
    bne   x8, x9, fail

    # ---- SB / LB / LBU test ----
    li    x10, 0x80            # 128 (negative as signed byte)
    sb    x10, 12(x20)
    lb    x11, 12(x20)         # load byte sign-extended
    li    x12, 0xFFFFFF80
    bne   x11, x12, fail

    lbu   x13, 12(x20)         # load byte unsigned
    li    x14, 0x00000080
    bne   x13, x14, fail

    # ---- Positive byte test ----
    li    x15, 0x7F
    sb    x15, 13(x20)
    lb    x16, 13(x20)
    li    x17, 0x0000007F
    bne   x16, x17, fail

    # ---- Halfword at upper half ----
    li    x1, 0x1234
    sh    x1, 18(x20)         # store at halfword-aligned offset
    lhu   x2, 18(x20)
    li    x3, 0x00001234
    bne   x2, x3, fail

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
