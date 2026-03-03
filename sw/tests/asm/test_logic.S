# test_logic.S — Test AND, OR, XOR, ANDI, ORI, XORI
.section .text.init
.globl _start
_start:
    li    x1, 0xFF00FF00
    li    x2, 0x0F0F0F0F

    # AND
    and   x3, x1, x2         # x3 = 0x0F000F00
    li    x4, 0x0F000F00
    bne   x3, x4, fail

    # OR
    or    x5, x1, x2         # x5 = 0xFF0FFF0F
    li    x6, 0xFF0FFF0F
    bne   x5, x6, fail

    # XOR
    xor   x7, x1, x2         # x7 = 0xF00FF00F
    li    x8, 0xF00FF00F
    bne   x7, x8, fail

    # ANDI
    andi  x9, x1, 0xFF       # x9 = 0x00 (0xFF00FF00 & 0x000000FF = 0x00000000)
    bne   x9, x0, fail

    # ORI
    addi  x10, x0, 5         # x10 = 5
    ori   x11, x10, 0xF0     # x11 = 5 | 0xF0 = 0xF5
    addi  x12, x0, 0xF5
    bne   x11, x12, fail

    # XORI
    addi  x13, x0, 0xFF
    xori  x14, x13, 0xFF     # x14 = 0xFF ^ 0xFF = 0
    bne   x14, x0, fail

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
