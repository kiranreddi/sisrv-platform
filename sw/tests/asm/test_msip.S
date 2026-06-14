# test_msip.S — Machine software interrupt via CLINT MSIP (0x02000000)

.section .text.init
.globl _start
_start:
    j     setup

    .align 2
msip_handler:
    csrr  x5, mcause
    lui   x7, 0x80000
    ori   x7, x7, 3
    bne   x5, x7, fail

    addi  x20, x20, 1

    li    x8, 0x02000000
    sw    x0, 0(x8)

    mret

setup:
    li    x1, 0x04
    csrw  mtvec, x1

    li    x19, 0
    li    x20, 0

    li    x1, 0x8
    csrw  mie, x1

    csrr  x1, mstatus
    ori   x1, x1, 0x8
    csrw  mstatus, x1

    li    x8, 0x02000000
    li    x9, 1
    sw    x9, 0(x8)

main_loop:
    addi  x19, x19, 1
    bne   x20, x0, check_done
    li    x2, 5000
    bge   x19, x2, fail
    j     main_loop

check_done:
    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
