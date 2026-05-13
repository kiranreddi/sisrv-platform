# test_mem_edge.S — Memory edge cases: all byte lanes, back-to-back, unaligned half
.section .text.init
.globl _start
_start:
    li    x20, 0x80000000     # RAM base

    # ---- SB/LB/LBU all 4 byte lanes ----
    li    x1, 0xAA
    sb    x1, 0(x20)           # byte 0
    li    x2, 0xBB
    sb    x2, 1(x20)           # byte 1
    li    x3, 0xCC
    sb    x3, 2(x20)           # byte 2
    li    x4, 0xDD
    sb    x4, 3(x20)           # byte 3

    # Read back as word
    lw    x5, 0(x20)
    li    x6, 0xDDCCBBAA
    bne   x5, x6, fail

    # Read back each byte unsigned
    lbu   x7, 0(x20)
    li    x8, 0xAA
    bne   x7, x8, fail

    lbu   x7, 1(x20)
    li    x8, 0xBB
    bne   x7, x8, fail

    lbu   x7, 2(x20)
    li    x8, 0xCC
    bne   x7, x8, fail

    lbu   x7, 3(x20)
    li    x8, 0xDD
    bne   x7, x8, fail

    # Read back each byte signed
    lb    x7, 0(x20)
    li    x8, 0xFFFFFFAA       # sign-ext of 0xAA
    bne   x7, x8, fail

    lb    x7, 3(x20)
    li    x8, 0xFFFFFFDD       # sign-ext of 0xDD
    bne   x7, x8, fail

    # ---- SH/LH/LHU both halfword positions ----
    li    x1, 0x1234
    sh    x1, 4(x20)           # lower half
    li    x2, 0x5678
    sh    x2, 6(x20)           # upper half

    lw    x3, 4(x20)
    li    x4, 0x56781234
    bne   x3, x4, fail

    lhu   x5, 4(x20)
    li    x6, 0x00001234
    bne   x5, x6, fail

    lhu   x5, 6(x20)
    li    x6, 0x00005678
    bne   x5, x6, fail

    lh    x5, 4(x20)
    li    x6, 0x00001234       # positive halfword
    bne   x5, x6, fail

    # SH with sign bit set
    li    x1, 0x8000
    sh    x1, 8(x20)
    lh    x2, 8(x20)
    li    x3, 0xFFFF8000       # sign-extended
    bne   x2, x3, fail

    lhu   x2, 8(x20)
    li    x3, 0x00008000       # zero-extended
    bne   x2, x3, fail

    # ---- Back-to-back stores then loads ----
    li    x1, 0x11111111
    li    x2, 0x22222222
    li    x3, 0x33333333
    li    x4, 0x44444444
    sw    x1, 16(x20)
    sw    x2, 20(x20)
    sw    x3, 24(x20)
    sw    x4, 28(x20)
    lw    x5, 16(x20)
    bne   x5, x1, fail
    lw    x5, 20(x20)
    bne   x5, x2, fail
    lw    x5, 24(x20)
    bne   x5, x3, fail
    lw    x5, 28(x20)
    bne   x5, x4, fail

    # ---- Store 0, load back ----
    sw    x0, 32(x20)
    lw    x1, 32(x20)
    bne   x1, x0, fail

    # ---- Walking ones in word ----
    addi  x1, x0, 1
    sw    x1, 36(x20)
    lw    x2, 36(x20)
    bne   x2, x1, fail

    slli  x1, x1, 1
    sw    x1, 36(x20)
    lw    x2, 36(x20)
    bne   x2, x1, fail

    slli  x1, x1, 1
    sw    x1, 36(x20)
    lw    x2, 36(x20)
    bne   x2, x1, fail

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
