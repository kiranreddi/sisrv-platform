# test_pipeline_load_use.S - M6 pipeline load-use stall and forwarding stress
.section .text.init
.globl _start
_start:
    li    x20, 0x80000000

    li    x1, 0x12345678
    sw    x1, 0(x20)
    lw    x2, 0(x20)
    addi  x3, x2, 1
    li    x4, 0x12345679
    bne   x3, x4, fail

    sw    x3, 4(x20)
    lw    x5, 4(x20)
    add   x6, x5, x2
    li    x7, 0x2468ACF1
    bne   x6, x7, fail

    li    x8, 0xFFFFFF80
    sw    x8, 8(x20)
    lb    x9, 8(x20)
    addi  x10, x9, 1
    li    x11, 0xFFFFFF81
    bne   x10, x11, fail

pass:
    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
