# test_csr.S — Test CSR read/write operations
.section .text.init
.globl _start
_start:
    # Write to mscratch, then read back
    li    x1, 0xDEADBEEF
    csrw  mscratch, x1        # CSRRW: mscratch = x1
    csrr  x2, mscratch        # CSRRS with rs1=x0: read mscratch
    bne   x1, x2, fail

    # CSRRS: set bits
    li    x3, 0x0000FF00
    csrs  mscratch, x3        # mscratch |= x3
    csrr  x4, mscratch
    li    x5, 0xDEADFF0F      # 0xDEADBEEF | 0x0000FF00 = 0xDEADFFEF
    # Wait, 0xDEADBEEF | 0x0000FF00 = 0xDEADFFEF, not 0xDEADFF0F
    li    x5, 0xDEADFFEF
    bne   x4, x5, fail

    # CSRRC: clear bits
    li    x6, 0x0000FFFF
    csrc  mscratch, x6        # mscratch &= ~x6
    csrr  x7, mscratch
    # 0xDEADFFEF & ~0x0000FFFF = 0xDEADFFEF & 0xFFFF0000 = 0xDEAD0000
    li    x8, 0xDEAD0000
    bne   x7, x8, fail

    # CSRRWI: write immediate
    csrwi mscratch, 15        # mscratch = 15
    csrr  x9, mscratch
    addi  x10, x0, 15
    bne   x9, x10, fail

    # Write to mtvec
    li    x1, 0x100           # trap vector address
    csrw  mtvec, x1
    csrr  x2, mtvec
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
