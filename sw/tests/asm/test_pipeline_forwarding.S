# test_pipeline_forwarding.S - M6 pipeline ALU/WB forwarding stress
.section .text.init
.globl _start
_start:
    addi  x1, x0, 1
    add   x2, x1, x1
    add   x3, x2, x1
    add   x4, x3, x2
    add   x5, x4, x3
    add   x6, x5, x4
    add   x7, x6, x5
    li    x8, 21
    bne   x7, x8, fail

    addi  x9, x0, 5
    addi  x10, x9, 7
    sub   x11, x10, x9
    li    x12, 7
    bne   x11, x12, fail

    addi  x13, x0, 0
    addi  x13, x13, 1
    addi  x13, x13, 2
    addi  x13, x13, 3
    addi  x13, x13, 4
    li    x14, 10
    bne   x13, x14, fail

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
