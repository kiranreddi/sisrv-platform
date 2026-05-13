# test_addi.S — Test ADDI instruction
.section .text.init
.globl _start
_start:
    # Test ADDI
    addi  x1, x0, 5          # x1 = 5
    addi  x2, x1, 3          # x2 = 8
    addi  x3, x0, 8          # x3 = 8

    # Verify: x2 should equal x3
    bne   x2, x3, fail

    # Test negative immediate
    addi  x4, x0, -1         # x4 = -1 = 0xFFFFFFFF
    addi  x5, x4, 1          # x5 = 0

    bne   x5, x0, fail

    # Test zero
    addi  x6, x0, 0          # x6 = 0
    bne   x6, x0, fail

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
