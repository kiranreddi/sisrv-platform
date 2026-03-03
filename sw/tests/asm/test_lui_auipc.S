# test_lui_auipc.S — Test LUI and AUIPC
.section .text.init
.globl _start
_start:
    # LUI: load upper immediate
    lui   x1, 0x12345         # x1 = 0x12345000
    lui   x2, 0x12345         # x2 = 0x12345000 (same)
    bne   x1, x2, fail

    # LUI with 0
    lui   x3, 0               # x3 = 0
    bne   x3, x0, fail

    # LUI with high value
    lui   x4, 0xFFFFF         # x4 = 0xFFFFF000
    lui   x5, 0xFFFFF         # x5 = 0xFFFFF000
    bne   x4, x5, fail

    # AUIPC: PC + upper immediate
    auipc x6, 0               # x6 = PC of this instruction (A)
    # next instr is at A+4 (the auipc x8 below)
    auipc x8, 0               # x8 = PC of this instruction (A+4)
    addi  x7, x6, 4           # x7 = A + 4
    bne   x7, x8, fail        # x7 should equal x8

    # AUIPC with non-zero immediate
    auipc x9, 0               # x9 = PC (B)
    auipc x10, 1              # x10 = PC(B+4) + 0x1000
    sub   x11, x10, x9        # x11 = (B+4+0x1000) - B = 0x1004
    li    x12, 0x1004
    bne   x11, x12, fail

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
