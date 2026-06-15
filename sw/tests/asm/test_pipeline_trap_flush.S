# test_pipeline_trap_flush.S - M6 trap flush must kill younger wrong-path work
.section .text.init
.globl _start
_start:
    j     setup

    .align 2
trap_handler:
    csrr  x5, mcause
    li    x6, 11
    bne   x5, x6, fail
    la    x7, after_wrong_path
    csrw  mepc, x7
    mret

setup:
    li    x20, 0x80000000
    sw    x0, 0(x20)
    li    x1, 0x04
    csrw  mtvec, x1

    ecall
    li    x2, 0x44444444
    sw    x2, 0(x20)

after_wrong_path:
    lw    x3, 0(x20)
    bne   x3, x0, fail

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
