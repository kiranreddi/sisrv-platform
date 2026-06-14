# test_mtime_write.S — Verify deterministic MTIME write semantics
# MMIO writes overlay the auto-increment in the same cycle (write wins).
# Because MTIME keeps running, reads after separate instructions observe
# written_value + elapsed_cycles, not the exact write data.
#
# Timer registers at CLINT 0x02000000 (MTIMECMP 0x02004000, MTIME 0x0200BFF8)

.section .text.init
.globl _start
_start:
    li    x8, 0x02004000

    # Keep MTIMECMP out of the way for this test.
    li    x9, 0xFFFFFFFF
    sw    x9, 0(x8)
    sw    x9, 4(x8)

    # Write MTIME via CLINT layout (lo at 0xBFF8)
    li    x8, 0x0200BFF8
    li    x9, 50
    sw    x9, 0(x8)
    sw    x9, 0(x8)
    lw    x10, 0(x8)
    blt   x10, x9, fail
    li    x11, 150
    bgt   x10, x11, fail

    # MTIME should continue incrementing after the snap.
    lw    x12, 0(x8)
    addi  x11, x0, 5
wait_loop:
    addi  x11, x11, -1
    bnez  x11, wait_loop
    lw    x13, 0(x8)
    ble   x13, x12, fail

    # Same pattern for MTIME_HI.
    li    x14, 3
    sw    x14, 4(x8)
    sw    x14, 4(x8)
    lw    x15, 4(x8)
    blt   x15, x14, fail
    li    x11, 20
    bgt   x15, x11, fail

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
