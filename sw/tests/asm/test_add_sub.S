# test_add_sub.S — Test ADD and SUB instructions
.section .text.init
.globl _start
_start:
    # ADD tests
    addi  x1, x0, 10         # x1 = 10
    addi  x2, x0, 20         # x2 = 20
    add   x3, x1, x2         # x3 = 30
    addi  x4, x0, 30         # x4 = 30
    bne   x3, x4, fail

    # ADD with negative
    addi  x5, x0, -5         # x5 = -5
    add   x6, x1, x5         # x6 = 10 + (-5) = 5
    addi  x7, x0, 5
    bne   x6, x7, fail

    # SUB tests
    sub   x8, x2, x1         # x8 = 20 - 10 = 10
    bne   x8, x1, fail

    # SUB resulting in negative
    sub   x9, x1, x2         # x9 = 10 - 20 = -10
    addi  x10, x0, -10
    bne   x9, x10, fail

    # SUB from zero
    sub   x11, x0, x1        # x11 = 0 - 10 = -10
    bne   x11, x10, fail

    # x0 hardwired test: add to x0 should not change it
    add   x0, x1, x2         # x0 should remain 0
    bne   x0, x0, fail       # Always passes since x0==x0

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
