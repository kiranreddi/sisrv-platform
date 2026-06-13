# test_gpio.S — Verify GPIO MMIO registers
#
# GPIO base: 0x1000_3000
#   +0x00 DATA
#   +0x04 DIR
#   +0x08 IN
#   +0x0C SET
#   +0x10 CLR

.section .text.init
.globl _start
_start:
    li    x1, 0x10003000       # GPIO base

    # Direction register read/write.
    li    x2, 0x0000FFFF
    sw    x2, 4(x1)             # DIR
    lw    x3, 4(x1)
    bne   x3, x2, fail

    # DATA write/read.
    li    x2, 0x000000A5
    sw    x2, 0(x1)             # DATA
    lw    x3, 0(x1)
    bne   x3, x2, fail

    # SET should set selected DATA bits.
    li    x4, 0x0000000A
    sw    x4, 12(x1)            # SET
    lw    x3, 0(x1)
    li    x5, 0x000000AF
    bne   x3, x5, fail

    # CLR should clear selected DATA bits.
    li    x4, 0x0000000F
    sw    x4, 16(x1)            # CLR
    lw    x3, 0(x1)
    li    x5, 0x000000A0
    bne   x3, x5, fail

    # Default Verilator harness drives gpio_in=0.
    lw    x3, 8(x1)             # IN
    bne   x3, x0, fail

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
