# test_branch.S — Test BEQ, BNE, BLT, BGE, BLTU, BGEU
.section .text.init
.globl _start
_start:
    addi  x1, x0, 5
    addi  x2, x0, 5
    addi  x3, x0, 10
    addi  x4, x0, -1         # 0xFFFFFFFF

    # BEQ: should branch
    beq   x1, x2, beq_ok
    j     fail
beq_ok:

    # BEQ: should not branch
    beq   x1, x3, fail

    # BNE: should branch
    bne   x1, x3, bne_ok
    j     fail
bne_ok:

    # BNE: should not branch
    bne   x1, x2, fail

    # BLT (signed): 5 < 10
    blt   x1, x3, blt_ok
    j     fail
blt_ok:

    # BLT: should not branch (10 < 5 is false)
    blt   x3, x1, fail

    # BLT: -1 < 5 (signed)
    blt   x4, x1, blt_neg_ok
    j     fail
blt_neg_ok:

    # BGE (signed): 10 >= 5
    bge   x3, x1, bge_ok
    j     fail
bge_ok:

    # BGE: 5 >= 5
    bge   x1, x2, bge_eq_ok
    j     fail
bge_eq_ok:

    # BGE: should not branch (5 >= 10 is false)
    bge   x1, x3, fail

    # BLTU (unsigned): 5 < 0xFFFFFFFF
    bltu  x1, x4, bltu_ok
    j     fail
bltu_ok:

    # BLTU: should not branch (0xFFFFFFFF < 5 is false unsigned)
    bltu  x4, x1, fail

    # BGEU (unsigned): 0xFFFFFFFF >= 5
    bgeu  x4, x1, bgeu_ok
    j     fail
bgeu_ok:

    # BGEU: 5 >= 5
    bgeu  x1, x2, bgeu_eq_ok
    j     fail
bgeu_eq_ok:

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
