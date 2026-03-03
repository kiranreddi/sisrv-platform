# test_jalr_align.S — JALR edge cases: bit[0] masking, rd=x0
.section .text.init
.globl _start
_start:
    # ---- JALR bit[0] masking test ----
    # JALR clears bit[0] of (rs1 + imm): result & 0xFFFFFFFE
    # target1 is at offset 0x10 from _start.
    # Set rs1 = 0x11 (odd). JALR masks bit[0] -> jumps to 0x10 = target1.
    auipc x1, 0               # x1 = 0 (address of this instr)
    addi  x1, x1, 17          # x1 = 0x11 (bit 0 set)
    jalr  x2, x1, 0           # target = 0x11 & ~1 = 0x10 = target1
    j     fail

    .align 2
target1:
    # ---- JALR with rd=x0 (discard link) ----
    auipc x3, 0
    addi  x3, x3, 16          # target2 = auipc + 16 (skip addi, jalr, j fail)
    jalr  x0, x3, 0           # jump, don't save link
    j     fail

target2:
    # Verify x0 is still 0
    bne   x0, x0, fail

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
