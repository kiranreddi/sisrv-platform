# test_pipeline_interrupt_flush.S - M6 interrupt flush must kill younger wrong-path work
.section .text.init
.globl _start
_start:
    j     setup

    .align 2
irq_handler:
    csrr  x5, mcause
    lui   x6, 0x80000
    ori   x6, x6, 3
    bne   x5, x6, fail

    li    x7, 0x02000000
    sw    x0, 0(x7)

1:  auipc x8, %pcrel_hi(after_wrong_path)
    addi  x8, x8, %pcrel_lo(1b)
    csrw  mepc, x8
    mret

setup:
    li    x20, 0x80000000
    sw    x0, 0(x20)

    li    x1, 0x04
    csrw  mtvec, x1

    li    x1, 0x8
    csrw  mie, x1

    csrr  x1, mstatus
    ori   x1, x1, 0x8
    csrw  mstatus, x1

    li    x7, 0x02000000
    li    x9, 1
    sw    x9, 0(x7)
    li    x2, 0x55555555
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
