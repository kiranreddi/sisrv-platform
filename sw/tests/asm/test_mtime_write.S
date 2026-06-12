# test_mtime_write.S — Verify deterministic MTIME write semantics
# MMIO writes to MTIME must take precedence over auto-increment in the same cycle.
#
# Timer registers at 0x1000_2000:
#   +0x00: MTIME_LO   +0x04: MTIME_HI

.section .text.init
.globl _start
_start:
    li    x8, 0x10002000

    # Stop upper half from wrapping during the test.
    sw    x0, 4(x8)

    # Write a known MTIME_LO value; readback must match exactly (not old+1).
    li    x9, 100
    sw    x9, 0(x8)
    lw    x10, 0(x8)
    bne   x9, x10, fail

    # After a few cycles MTIME should advance from the written value.
    li    x11, 5
wait_loop:
    addi  x11, x11, -1
    bnez  x11, wait_loop

    lw    x12, 0(x8)
    ble   x12, x9, fail

    # Write and read MTIME_HI with the same deterministic semantics.
    li    x13, 0x00000042
    sw    x13, 4(x8)
    lw    x14, 4(x8)
    bne   x13, x14, fail

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
