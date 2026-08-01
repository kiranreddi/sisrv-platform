# test_plic_irq.S — External IRQ via PLIC (source 1, priority 5)

.section .text.init
.globl _start
_start:
    j     setup

    .align 2
ext_handler:
    csrr  x5, mcause
    lui   x7, 0x80000
    ori   x7, x7, 11
    bne   x5, x7, fail

    # PLIC claim (read) then complete (write) @ 0x0C200004
    li    x8, 0x0C200004
    lw    x9, 0(x8)
    addi  x20, x20, 1
    sw    x9, 0(x8)

    mret

setup:
    li    x1, 0x04
    csrw  mtvec, x1

    # Mask CLINT timer/software so only PLIC MEIP can fire
    li    x8, 0x02004000
    li    x9, -1
    sw    x9, 0(x8)
    sw    x9, 4(x8)
    li    x8, 0x02000000
    sw    x0, 0(x8)

    li    x19, 0
    li    x20, 0

    # priority[1] = 5
    li    x8, 0x0C000004
    li    x9, 5
    sw    x9, 0(x8)

    # enable source 1
    li    x8, 0x0C002000
    li    x9, 2
    sw    x9, 0(x8)

    # threshold = 0 (allow priority 5) @ 0x0C200000
    li    x8, 0x0C200000
    sw    x0, 0(x8)

    # Cover PLIC readback paths (pending/enable/threshold)
    li    x8, 0x0C001000
    lw    x9, 0(x8)
    li    x8, 0x0C002000
    lw    x9, 0(x8)
    li    x8, 0x0C200000
    lw    x9, 0(x8)

    li    x1, 0x800
    csrw  mie, x1

    csrr  x1, mstatus
    ori   x1, x1, 0x8
    csrw  mstatus, x1

    li    x8, 0x1000300C
    li    x9, 2
    sw    x9, 0(x8)

main_loop:
    addi  x19, x19, 1
    bne   x20, x0, check_done
    li    x2, 8000
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
