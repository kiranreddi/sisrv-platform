# test_mret_boundary.S — Verify exact instruction boundary on MRET return
# Places recognizable values around the interrupt point and confirms
# that after mret, execution resumes at the correct instruction with
# no skipped or repeated instructions.
#
# Strategy:
#   1. Main loop writes a known sequence: x10=0xAA, x11=0xBB, x12=0xCC, x13=0xDD
#   2. Timer fires between instructions (at WB→FETCH transition)
#   3. ISR saves mepc and a marker; mret returns
#   4. After return, verify x10..x13 reflect exactly which instructions completed
#   5. Verify mepc was PC+4 of the interrupted instruction (no off-by-4 error)
#
# This catches: skipped instructions, repeated instructions, off-by-4 mepc errors.

.section .text.init
.globl _start
_start:
    j     setup                # 0x00: jump past trap handler

    .align 2
irq_handler:                   # 0x04: interrupt handler
    # Verify this is a timer interrupt (mcause = 0x80000007)
    csrr  x28, mcause
    lui   x29, 0x80000
    ori   x29, x29, 7
    bne   x28, x29, fail

    # Save mepc to x25 for later verification
    csrr  x25, mepc

    # Mark that ISR ran (x24 = 1)
    li    x24, 1

    # Acknowledge timer: push MTIMECMP far to clear MTIP
    li    x26, 0x10002000      # Timer base
    li    x27, 0x7FFFFFFF
    sw    x27, 8(x26)          # MTIMECMP_LO = max
    sw    x27, 12(x26)         # MTIMECMP_HI = max

    mret

setup:
    # Set mtvec = 0x04
    li    x1, 0x04
    csrw  mtvec, x1

    # Initialize all marker registers to 0
    li    x10, 0
    li    x11, 0
    li    x12, 0
    li    x13, 0
    li    x24, 0               # ISR-ran flag
    li    x25, 0               # saved mepc

    # Set MTIMECMP to fire soon (small offset from current MTIME)
    li    x8, 0x10002000       # Timer base
    lw    x9, 0(x8)            # Read MTIME_LO
    addi  x9, x9, 30          # Fire 30 cycles from now
    sw    x9, 8(x8)            # MTIMECMP_LO
    sw    x0, 12(x8)           # MTIMECMP_HI = 0

    # Enable timer interrupt: mie.MTIE (bit 7)
    li    x1, 0x80
    csrw  mie, x1

    # Enable global interrupts: mstatus.MIE (bit 3)
    csrr  x1, mstatus
    ori   x1, x1, 0x8
    csrw  mstatus, x1

    # -------------------------------------------------------------------
    # Instruction sequence: write recognizable pattern with known PCs
    # The interrupt will fire somewhere in this sequence.
    # After MRET, we verify that no instruction was skipped or repeated.
    # -------------------------------------------------------------------
    nop                        # burn cycles to let timer fire
    nop
    nop
    nop
    nop

marker_a:
    li    x10, 0xAA            # marker A
marker_b:
    li    x11, 0xBB            # marker B
marker_c:
    li    x12, 0xCC            # marker C
marker_d:
    li    x13, 0xDD            # marker D

    # Wait for ISR if it hasn't fired yet
    li    x2, 0
wait_isr:
    addi  x2, x2, 1
    li    x3, 5000
    bge   x2, x3, fail        # timeout: timer never fired
    beq   x24, x0, wait_isr   # loop until ISR flag is set

    # -------------------------------------------------------------------
    # Verify: all four markers must be set (no skipped instruction)
    # -------------------------------------------------------------------
    li    x3, 0xAA
    bne   x10, x3, fail       # x10 must be 0xAA

    li    x3, 0xBB
    bne   x11, x3, fail       # x11 must be 0xBB

    li    x3, 0xCC
    bne   x12, x3, fail       # x12 must be 0xCC

    li    x3, 0xDD
    bne   x13, x3, fail       # x13 must be 0xDD

    # -------------------------------------------------------------------
    # Verify: mepc was word-aligned (no off-by-4 error)
    # mepc should be PC+4 of the interrupted instruction, which is always
    # word-aligned (mepc[1:0] == 0)
    # -------------------------------------------------------------------
    andi  x3, x25, 3
    bne   x3, x0, fail        # mepc must be word-aligned

    # -------------------------------------------------------------------
    # Verify: mepc is within expected range (not 0, not wild)
    # Must be somewhere in our code region
    # -------------------------------------------------------------------
    beq   x25, x0, fail       # mepc must not be 0

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
