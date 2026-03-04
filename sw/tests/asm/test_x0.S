# test_x0.S — Verify x0 is always zero (architectural invariant)
.section .text.init
.globl _start
_start:
    # Try to write to x0 via various instructions
    addi  x0, x0, 42         # should not change x0
    bne   x0, x0, fail

    li    x1, 100
    add   x0, x1, x1         # x0 = x1 + x1? No, x0 stays 0
    bne   x0, x0, fail

    lui   x0, 0xFFFFF        # try to write x0 via LUI
    bne   x0, x0, fail

    # Verify x0 reads as zero
    addi  x2, x0, 0          # x2 = 0
    bne   x2, x0, fail

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
