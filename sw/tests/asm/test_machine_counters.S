# test_machine_counters.S - Verify machine ID and counter CSRs
.section .text.init
.globl _start
_start:
    csrr  x1, 0x301           # misa
    li    x2, 0x40001100       # RV32, I + M
    bne   x1, x2, fail

    csrr  x1, 0xF11           # mvendorid
    bne   x1, x0, fail
    csrr  x1, 0xF12           # marchid
    bne   x1, x0, fail
    csrr  x1, 0xF13           # mimpid
    bne   x1, x0, fail
    csrr  x1, 0xF14           # mhartid
    bne   x1, x0, fail
    csrr  x1, 0xF15           # mconfigptr
    bne   x1, x0, fail

    csrr  x3, 0xB00           # mcycle
    addi  x0, x0, 0
    csrr  x4, 0xB00           # mcycle
    bgeu  x3, x4, fail

    csrr  x5, 0xB02           # minstret
    addi  x6, x0, 1
    addi  x6, x6, 1
    addi  x6, x6, 1
    csrr  x7, 0xB02           # minstret
    bgeu  x5, x7, fail

    li    x8, 0x5              # inhibit CY and IR
    csrw  0x320, x8           # mcountinhibit
    csrr  x9, 0xB00           # mcycle
    csrr  x10, 0xB02          # minstret
    addi  x6, x6, 1
    addi  x6, x6, 1
    addi  x6, x6, 1
    csrr  x11, 0xB00          # mcycle
    csrr  x12, 0xB02          # minstret
    bne   x9, x11, fail
    bne   x10, x12, fail

    csrw  0x320, x0           # mcountinhibit

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
