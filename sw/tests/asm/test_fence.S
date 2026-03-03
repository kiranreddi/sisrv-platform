# test_fence.S — Test FENCE instruction (should be treated as NOP)
.section .text.init
.globl _start
_start:
    # Set a register value before fence
    addi  x1, x0, 42

    # Execute FENCE (should act as NOP on this single-core, in-order design)
    fence

    # Verify x1 unchanged
    addi  x2, x0, 42
    bne   x1, x2, fail

    # FENCE with various pred/succ bits (all should be NOP)
    fence iorw, iorw
    fence rw, rw

    # Verify normal execution continues
    addi  x3, x0, 100
    addi  x4, x0, 100
    bne   x3, x4, fail

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
