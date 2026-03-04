# test_csr_edge.S — CSR edge cases
# CSRRS/CSRRC with rs1=x0 should read but not write
# CSRRWI/CSRRSI/CSRRCI with uimm=0
.section .text.init
.globl _start
_start:
    # ---- CSRRW: write then read ----
    li    x1, 0xDEADBEEF
    csrw  mscratch, x1
    csrr  x2, mscratch
    bne   x1, x2, fail

    # ---- CSRRS with rs1=x0: read-only (should NOT modify) ----
    li    x1, 0x12345678
    csrw  mscratch, x1
    csrrs x2, mscratch, x0     # read mscratch into x2, don't set bits
    bne   x2, x1, fail
    csrr  x3, mscratch         # verify unchanged
    bne   x3, x1, fail

    # ---- CSRRC with rs1=x0: read-only ----
    csrrc x4, mscratch, x0     # read mscratch into x4, don't clear bits
    bne   x4, x1, fail
    csrr  x5, mscratch
    bne   x5, x1, fail

    # ---- CSRRS set specific bits ----
    csrw  mscratch, x0         # clear mscratch
    li    x6, 0x000000FF
    csrrs x7, mscratch, x6     # x7 = old value (0), set bits 0xFF
    bne   x7, x0, fail         # old was 0
    csrr  x8, mscratch
    bne   x8, x6, fail         # new should be 0xFF

    # ---- CSRRC clear specific bits ----
    li    x9, 0x0000000F
    csrrc x10, mscratch, x9    # x10 = old (0xFF), clear bits 0x0F
    bne   x10, x6, fail        # old was 0xFF
    csrr  x11, mscratch
    li    x12, 0x000000F0
    bne   x11, x12, fail       # new should be 0xF0

    # ---- CSRRWI with uimm=0 ----
    csrwi mscratch, 0
    csrr  x13, mscratch
    bne   x13, x0, fail

    # ---- CSRRWI with uimm=31 (max 5-bit) ----
    csrwi mscratch, 31
    csrr  x14, mscratch
    addi  x15, x0, 31
    bne   x14, x15, fail

    # ---- CSRRSI with uimm ----
    csrw  mscratch, x0
    csrsi mscratch, 5          # set bits 0 and 2
    csrr  x16, mscratch
    addi  x17, x0, 5
    bne   x16, x17, fail

    # ---- CSRRCI with uimm ----
    csrci mscratch, 1          # clear bit 0
    csrr  x18, mscratch
    addi  x19, x0, 4           # 5 & ~1 = 4
    bne   x18, x19, fail

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
