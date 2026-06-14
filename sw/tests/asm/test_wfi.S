# test_wfi.S - Verify WFI is a legal no-op on this core
.section .text.init
.globl _start
_start:
    li    x1, 42
    wfi
    li    x2, 42
    bne   x1, x2, fail

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
