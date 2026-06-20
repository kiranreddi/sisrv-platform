# test_trigger_exec.S — hardware execute trigger (mcontrol) -> breakpoint
# tdata1 = execute|m, tdata2 = &trig_target. Reaching trig_target faults (cause 3)
# BEFORE it executes; handler clears the trigger and resumes; trig_target then runs once.
.section .text.init
.globl _start
#define PASS_ADDR 0x10000000

_start:
    li   s0, 0                 # "trig_target executed" counter
    li   s1, 0                 # "handler ran" flag
    la   t0, handler
    csrw mtvec, t0

    csrw 0x7a0, x0             # tselect = 0
    la   t2, trig_target
    csrw 0x7a2, t2             # tdata2 = &trig_target
    li   t3, 0x44              # mcontrol: execute(bit2) | m(bit6)
    csrw 0x7a1, t3             # tdata1

    nop
    nop
trig_target:
    addi s0, s0, 1            # must run exactly once, only after the breakpoint+resume

    li   t0, 1
    bne  s0, t0, fail         # executed exactly once
    bne  s1, t0, fail         # handler ran
    j    pass

    .align 2
handler:
    csrr t0, mcause
    li   t1, 3
    bne  t0, t1, fail         # breakpoint cause
    csrr t0, mepc
    la   t1, trig_target
    bne  t0, t1, fail         # mepc == faulting instruction
    csrw 0x7a1, x0           # clear trigger so it doesn't re-fire after mret
    li   s1, 1
    mret                      # resume at trig_target (now executes)

pass:
    li   x10, 1
    li   x11, PASS_ADDR
    sw   x10, 0(x11)
1:  j    1b
fail:
    li   x10, 0
    li   x11, PASS_ADDR
    sw   x10, 0(x11)
1:  j    1b
