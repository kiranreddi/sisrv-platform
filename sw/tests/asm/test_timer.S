# test_timer.S — Test timer interrupt handling
# Sets up timer to fire after a short delay, verifies:
# 1. Main loop increments counter A
# 2. Timer ISR increments counter B
# 3. PASS when B reaches target and A is reasonable
#
# Timer registers at 0x1000_2000:
#   +0x00: MTIME_LO   +0x04: MTIME_HI
#   +0x08: MTIMECMP_LO  +0x0C: MTIMECMP_HI

.section .text.init
.globl _start
_start:
    j     setup                # 0x00: jump past trap handler

    .align 2
timer_handler:                 # 0x04: timer interrupt handler
    # Verify mcause = 0x80000007 (interrupt bit + timer interrupt code)
    csrr  x5, mcause
    li    x6, 0x80000007       # {1'b1, 31'd7}
    # Upper bit check
    lui   x7, 0x80000
    ori   x7, x7, 7
    bne   x5, x7, fail

    # Increment ISR counter (x20)
    addi  x20, x20, 1

    # Acknowledge: push MTIMECMP far into future to clear MTIP
    li    x8, 0x10002000       # Timer base
    li    x9, 0x7FFFFFFF       # Large value
    sw    x9, 8(x8)            # MTIMECMP_LO = 0x7FFFFFFF
    sw    x9, 12(x8)           # MTIMECMP_HI = 0x7FFFFFFF

    mret

setup:
    # Set mtvec = 0x04 (address of timer_handler)
    li    x1, 0x04
    csrw  mtvec, x1

    # Initialize counters
    li    x19, 0               # Main counter A
    li    x20, 0               # ISR counter B

    # Set MTIMECMP to fire quickly (MTIME starts at ~reset+N cycles)
    # Read current MTIME, add small offset
    li    x8, 0x10002000       # Timer base
    lw    x9, 0(x8)            # Read MTIME_LO
    addi  x9, x9, 50           # Fire 50 cycles from now
    sw    x9, 8(x8)            # MTIMECMP_LO
    sw    x0, 12(x8)           # MTIMECMP_HI = 0

    # Enable timer interrupt: mie.MTIE (bit 7)
    li    x1, 0x80
    csrw  mie, x1

    # Enable global interrupts: mstatus.MIE (bit 3)
    csrr  x1, mstatus
    ori   x1, x1, 0x8
    csrw  mstatus, x1

    # Main loop: increment counter A, wait for ISR to fire
main_loop:
    addi  x19, x19, 1

    # Check if ISR has fired (x20 > 0)
    bne   x20, x0, check_done

    # Safety: if main counter exceeds 5000, timer never fired
    li    x2, 5000
    bge   x19, x2, fail

    j     main_loop

check_done:
    # ISR fired at least once
    # Verify main counter is reasonable (> 10, meaning main loop ran)
    li    x2, 10
    blt   x19, x2, fail

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
