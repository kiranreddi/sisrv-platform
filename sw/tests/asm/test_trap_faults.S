# test_trap_faults.S - Verify precise misalignment and access-fault traps
.section .text.init
.globl _start
_start:
    j     setup

    .align 2
trap_handler:
    csrr  x5, mscratch
    csrr  x6, mcause
    csrr  x7, mtval

    beq   x5, x0, case_lh_misalign
    li    x8, 1
    beq   x5, x8, case_lw_misalign
    li    x8, 2
    beq   x5, x8, case_sh_misalign
    li    x8, 3
    beq   x5, x8, case_sw_misalign
    li    x8, 4
    beq   x5, x8, case_jalr_misalign
    li    x8, 5
    beq   x5, x8, case_jal_misalign
    li    x8, 6
    beq   x5, x8, case_branch_misalign
    li    x8, 7
    beq   x5, x8, case_load_access
    li    x8, 8
    beq   x5, x8, case_store_access
    li    x8, 9
    beq   x5, x8, case_fetch_access
    j     fail

case_lh_misalign:
    li    x8, 4
    bne   x6, x8, fail
    li    x8, 0x80000001
    bne   x7, x8, fail
    j     trap_resume

case_lw_misalign:
    li    x8, 4
    bne   x6, x8, fail
    li    x8, 0x80000002
    bne   x7, x8, fail
    j     trap_resume

case_sh_misalign:
    li    x8, 6
    bne   x6, x8, fail
    li    x8, 0x80000001
    bne   x7, x8, fail
    j     trap_resume

case_sw_misalign:
    li    x8, 6
    bne   x6, x8, fail
    li    x8, 0x80000002
    bne   x7, x8, fail
    j     trap_resume

case_jalr_misalign:
    li    x8, 0
    bne   x6, x8, fail
    li    x8, 0x12
    bne   x7, x8, fail
    j     trap_resume

case_jal_misalign:
    li    x8, 0
    bne   x6, x8, fail
    csrr  x9, mepc
    addi  x10, x9, 2
    bne   x7, x10, fail
    j     trap_resume

case_branch_misalign:
    li    x8, 0
    bne   x6, x8, fail
    csrr  x9, mepc
    addi  x10, x9, 2
    bne   x7, x10, fail
    j     trap_resume

case_load_access:
    li    x8, 5
    bne   x6, x8, fail
    li    x8, 0x20000000
    bne   x7, x8, fail
    j     trap_resume

case_store_access:
    li    x8, 7
    bne   x6, x8, fail
    li    x8, 0x20000000
    bne   x7, x8, fail
    j     trap_resume

case_fetch_access:
    li    x8, 1
    bne   x6, x8, fail
    li    x8, 0x20000000
    bne   x7, x8, fail
    j     pass

trap_resume:
    addi  x5, x5, 1
    csrw  mscratch, x5
    csrr  x9, mepc
    addi  x9, x9, 4
    csrw  mepc, x9
    mret

setup:
    li    x1, 0x04
    csrw  mtvec, x1
    csrw  mscratch, x0
    li    x20, 0x80000000
    sw    x0, 0(x20)

    lh    x2, 1(x20)          # load address misaligned
    lw    x2, 2(x20)          # load address misaligned
    sh    x2, 1(x20)          # store address misaligned
    sw    x2, 2(x20)          # store address misaligned
    li    x3, 0x12
    jalr  x0, 0(x3)           # instruction address misaligned (JALR)
    .balign 4
    jal   x0, . + 2           # instruction address misaligned (JAL)
    .balign 4
    li    x10, 1
    beq   x10, x10, . + 2     # taken branch to misaligned target
    li    x3, 0x20000000
    lw    x4, 0(x3)           # load access fault
    sw    x4, 0(x3)           # store access fault
    jalr  x0, 0(x3)           # fetch access fault, handler passes

    j     fail

pass:
    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
