# test_back_to_back.S — Rapid instruction sequence stress test
# Tests pipeline/FSM correctness under fast instruction transitions
.section .text.init
.globl _start
_start:
    li    x20, 0x80000000     # RAM base

    # ---- Rapid ALU sequence with data dependencies ----
    addi  x1, x0, 1
    add   x2, x1, x1          # 2
    add   x3, x2, x1          # 3
    add   x4, x3, x2          # 5
    add   x5, x4, x3          # 8
    add   x6, x5, x4          # 13
    add   x7, x6, x5          # 21

    addi  x8, x0, 21
    bne   x7, x8, fail

    # ---- Alternating loads and stores ----
    li    x1, 0xAAAAAAAA
    sw    x1, 0(x20)
    lw    x2, 0(x20)
    addi  x2, x2, 1
    sw    x2, 4(x20)
    lw    x3, 4(x20)
    addi  x3, x3, 1
    sw    x3, 8(x20)
    lw    x4, 8(x20)

    li    x5, 0xAAAAAAAA
    addi  x5, x5, 2           # 0xAAAAAAAC
    bne   x4, x5, fail

    # ---- Store then immediate load (read-after-write) ----
    li    x1, 0x42424242
    sw    x1, 12(x20)
    lw    x2, 12(x20)
    bne   x1, x2, fail

    # ---- Branch after ALU ----
    addi  x1, x0, 10
    addi  x2, x0, 10
    sub   x3, x1, x2          # 0
    beq   x3, x0, branch_ok
    j     fail
branch_ok:

    # ---- JAL after store ----
    sw    x1, 16(x20)
    jal   x0, jal_ok
    j     fail
jal_ok:

    # ---- Loop with counter ----
    addi  x1, x0, 0           # counter
    addi  x2, x0, 10          # limit
loop:
    addi  x1, x1, 1
    bne   x1, x2, loop

    addi  x3, x0, 10
    bne   x1, x3, fail

    # ---- Use all 31 registers ----
    addi  x1,  x0, 1
    addi  x2,  x0, 2
    addi  x3,  x0, 3
    addi  x4,  x0, 4
    addi  x5,  x0, 5
    addi  x6,  x0, 6
    addi  x7,  x0, 7
    addi  x8,  x0, 8
    addi  x9,  x0, 9
    addi  x10, x0, 10
    addi  x11, x0, 11
    addi  x12, x0, 12
    addi  x13, x0, 13
    addi  x14, x0, 14
    addi  x15, x0, 15
    addi  x16, x0, 16
    addi  x17, x0, 17
    addi  x18, x0, 18
    addi  x19, x0, 19
    addi  x20, x0, 20
    addi  x21, x0, 21
    addi  x22, x0, 22
    addi  x23, x0, 23
    addi  x24, x0, 24
    addi  x25, x0, 25
    addi  x26, x0, 26
    addi  x27, x0, 27
    addi  x28, x0, 28
    addi  x29, x0, 29
    addi  x30, x0, 30
    addi  x31, x0, 31

    # Sum all registers (use adder chain)
    add   x1, x1, x2
    add   x1, x1, x3
    add   x1, x1, x4
    add   x1, x1, x5
    add   x1, x1, x6
    add   x1, x1, x7
    add   x1, x1, x8
    add   x1, x1, x9
    add   x1, x1, x10
    add   x1, x1, x11
    add   x1, x1, x12
    add   x1, x1, x13
    add   x1, x1, x14
    add   x1, x1, x15
    add   x1, x1, x16
    add   x1, x1, x17
    add   x1, x1, x18
    add   x1, x1, x19
    add   x1, x1, x20
    add   x1, x1, x21
    add   x1, x1, x22
    add   x1, x1, x23
    add   x1, x1, x24
    add   x1, x1, x25
    add   x1, x1, x26
    add   x1, x1, x27
    add   x1, x1, x28
    add   x1, x1, x29
    add   x1, x1, x30
    add   x1, x1, x31

    # Sum 1..31 = 31*32/2 = 496
    li    x2, 496
    bne   x1, x2, fail

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
