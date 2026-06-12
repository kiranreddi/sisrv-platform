# test_illegal_funct.S — Test illegal-instruction traps for invalid funct encodings
.section .text.init
.globl _start
_start:
    j     setup

    .align 2
trap_handler:
    csrr  x5, mcause
    li    x6, 2
    bne   x5, x6, fail

    csrr  x20, mscratch
    addi  x20, x20, 1
    csrw  mscratch, x20

    csrr  x10, mepc
    addi  x10, x10, 4
    csrw  mepc, x10

    mret

setup:
    li    x1, 0x04
    csrw  mtvec, x1
    csrw  mscratch, x0

    # RV32M-looking MUL encoding (funct7=1 under OP-ALU-REG)
    .word 0x020080b3

    # Invalid ALU reg: XOR with funct7=1
    .word 0x02004033

    # Invalid branch funct3=010
    .word 0x00002063

    # Invalid JALR funct3=001
    .word 0x00001067

    # Invalid SYSTEM funct3=000 with unknown imm
    .word 0x10000073

    # Invalid FENCE funct3=001
    .word 0x0000100f

    csrr  x3, mscratch
    li    x4, 6
    bne   x3, x4, fail

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
