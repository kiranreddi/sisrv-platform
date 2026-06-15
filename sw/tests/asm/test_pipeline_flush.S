# test_pipeline_flush.S - M6 branch/jump flush must kill younger wrong-path work
.section .text.init
.globl _start
_start:
    li    x20, 0x80000000
    sw    x0, 0(x20)

    addi  x1, x0, 1
    beq   x1, x1, branch_taken
    li    x2, 0x11111111
    sw    x2, 0(x20)
branch_taken:
    lw    x3, 0(x20)
    bne   x3, x0, fail

    jal   x4, jal_target
    li    x2, 0x22222222
    sw    x2, 0(x20)
jal_target:
    lw    x3, 0(x20)
    bne   x3, x0, fail
    beq   x4, x0, fail

    la    x5, jalr_target
    jalr  x6, 0(x5)
    li    x2, 0x33333333
    sw    x2, 0(x20)
jalr_target:
    lw    x3, 0(x20)
    bne   x3, x0, fail
    beq   x6, x0, fail

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
