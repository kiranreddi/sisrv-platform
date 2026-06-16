# test_pipeline_throughput.S - M6 independent ALU throughput guard
.section .text.init
.globl _start
_start:
    csrr  x5, mcycle

    addi  x1,  x0, 1
    addi  x2,  x0, 2
    addi  x3,  x0, 3
    addi  x4,  x0, 4
    addi  x6,  x0, 6
    addi  x7,  x0, 7
    addi  x8,  x0, 8
    addi  x9,  x0, 9
    addi  x10, x0, 10
    addi  x11, x0, 11
    addi  x12, x0, 12
    addi  x13, x0, 13
    addi  x14, x0, 14
    addi  x15, x0, 15
    addi  x16, x0, 16
    addi  x17, x0, 17

    csrr  x18, mcycle
    sub   x19, x18, x5

    # The direct corebus is single-outstanding, so this is not a 1-CPI memory
    # benchmark. It does catch a regression back to one shared EX/WB slot.
    li    x20, 56
    bgeu  x19, x20, fail

    add   x21, x1, x2
    add   x21, x21, x3
    add   x21, x21, x4
    add   x21, x21, x6
    add   x21, x21, x7
    add   x21, x21, x8
    add   x21, x21, x9
    add   x21, x21, x10
    add   x21, x21, x11
    add   x21, x21, x12
    add   x21, x21, x13
    add   x21, x21, x14
    add   x21, x21, x15
    add   x21, x21, x16
    add   x21, x21, x17
    li    x22, 148
    bne   x21, x22, fail

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
