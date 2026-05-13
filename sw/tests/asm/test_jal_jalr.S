# test_jal_jalr.S — Test JAL and JALR
.section .text.init
.globl _start
_start:
    # JAL: jump and link
    jal   x1, target1        # x1 = return address (PC+4)
    j     fail                # should be skipped

target1:
    # JALR test: compute target2 address in x2
    auipc x2, 0               # x2 = current PC (addr of this instr)
    addi  x2, x2, 16          # x2 = auipc_addr + 16 = target2
    jalr  x3, x2, 0           # jump to target2, x3 = return addr
    j     fail                 # should be skipped

target2:
    # Second JALR test
    auipc x4, 0               # x4 = current PC
    addi  x4, x4, 16          # x4 = auipc_addr + 16 = target3
    jalr  x5, x4, 0
    j     fail

target3:
    # JAL to x0 (don't link)
    jal   x0, target4
    j     fail

target4:
    # Verify x0 is still 0 after JAL to x0
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
