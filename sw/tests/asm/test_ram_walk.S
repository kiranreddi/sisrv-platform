# test_ram_walk.S — Walking-ones and walking-zeros RAM test
# Verifies data integrity across multiple RAM locations
.section .text.init
.globl _start
_start:
    li    x20, 0x80000000     # RAM base

    # ---- Walking ones: store 1,2,4,8,...,0x80000000 ----
    addi  x1, x0, 1          # bit pattern
    addi  x2, x0, 0          # offset counter
    addi  x3, x0, 32         # num iterations (32 bits)

walk_ones_store:
    beq   x2, x3, walk_ones_verify
    slli  x4, x2, 2          # offset in bytes (x2 * 4)
    add   x5, x20, x4
    sw    x1, 0(x5)
    slli  x1, x1, 1          # next bit
    addi  x2, x2, 1
    j     walk_ones_store

walk_ones_verify:
    addi  x1, x0, 1
    addi  x2, x0, 0

walk_ones_check:
    beq   x2, x3, walk_zeros
    slli  x4, x2, 2
    add   x5, x20, x4
    lw    x6, 0(x5)
    bne   x6, x1, fail
    slli  x1, x1, 1
    addi  x2, x2, 1
    j     walk_ones_check

    # ---- Walking zeros: store ~1, ~2, ~4, etc. ----
walk_zeros:
    addi  x1, x0, 1
    addi  x2, x0, 0
    li    x7, 0xFFFFFFFF
    addi  x10, x0, 128       # offset base for walking zeros (128 bytes from base)

walk_zeros_store:
    beq   x2, x3, walk_zeros_verify
    xor   x8, x7, x1          # ~(1 << i)
    slli  x4, x2, 2
    add   x5, x20, x4
    add   x5, x5, x10
    sw    x8, 0(x5)
    slli  x1, x1, 1
    addi  x2, x2, 1
    j     walk_zeros_store

walk_zeros_verify:
    addi  x1, x0, 1
    addi  x2, x0, 0

walk_zeros_check:
    beq   x2, x3, done
    xor   x8, x7, x1
    slli  x4, x2, 2
    add   x5, x20, x4
    add   x5, x5, x10
    lw    x6, 0(x5)
    bne   x6, x8, fail
    slli  x1, x1, 1
    addi  x2, x2, 1
    j     walk_zeros_check

done:
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
