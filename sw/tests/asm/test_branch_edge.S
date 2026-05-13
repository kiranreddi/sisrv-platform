# test_branch_edge.S — Branch instruction edge cases
# Tests INT_MIN/INT_MAX boundaries, equal values, zero crossings
.section .text.init
.globl _start
_start:
    li    x1, 0x80000000       # INT_MIN
    li    x2, 0x7FFFFFFF       # INT_MAX
    li    x3, 0xFFFFFFFF       # -1 / UINT_MAX
    li    x4, 0x00000000       # 0
    li    x5, 0x00000001       # 1

    # ---- BEQ with identical large values ----
    beq   x1, x1, beq1_ok
    j     fail
beq1_ok:

    # ---- BNE: INT_MIN vs INT_MAX ----
    bne   x1, x2, bne1_ok
    j     fail
bne1_ok:

    # ---- BLT: INT_MIN < INT_MAX (signed) ----
    blt   x1, x2, blt1_ok
    j     fail
blt1_ok:

    # ---- BLT: -1 < 0 (signed) ----
    blt   x3, x4, blt2_ok
    j     fail
blt2_ok:

    # ---- BLT: should NOT branch: 0 < 0 ----
    blt   x4, x4, fail

    # ---- BGE: INT_MAX >= INT_MIN ----
    bge   x2, x1, bge1_ok
    j     fail
bge1_ok:

    # ---- BGE: 0 >= 0 ----
    bge   x4, x4, bge2_ok
    j     fail
bge2_ok:

    # ---- BGE: 0 >= -1 ----
    bge   x4, x3, bge3_ok
    j     fail
bge3_ok:

    # ---- BLTU: 0 < UINT_MAX ----
    bltu  x4, x3, bltu1_ok
    j     fail
bltu1_ok:

    # ---- BLTU: 0x7FFFFFFF < 0x80000000 (unsigned) ----
    bltu  x2, x1, bltu2_ok
    j     fail
bltu2_ok:

    # ---- BLTU: should NOT branch: same values ----
    bltu  x1, x1, fail

    # ---- BGEU: UINT_MAX >= 0 ----
    bgeu  x3, x4, bgeu1_ok
    j     fail
bgeu1_ok:

    # ---- BGEU: same values ----
    bgeu  x3, x3, bgeu2_ok
    j     fail
bgeu2_ok:

    # ---- BGEU: should NOT branch: 0 >= 1 ----
    bgeu  x4, x5, fail

    # ---- Forward/backward branch ----
    addi  x6, x0, 1
    beq   x6, x5, fwd_ok      # forward branch
    j     fail
fwd_ok:

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
