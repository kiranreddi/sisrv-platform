# test_trigger_load.S — hardware load watchpoint (mcontrol) -> breakpoint
# tdata1 = load|m, tdata2 = &word. A lw from &word faults (cause 3); handler clears
# the trigger and resumes; the lw then completes. A lw from a different address does not fire.
.section .text.init
.globl _start
#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    li   s1, 0
    la   t0, handler
    csrw mtvec, t0

    li   s6, RAM_BASE
    li   t0, 0x12345678
    sw   t0, 0(s6)
    li   t0, 0x9ABCDEF0
    sw   t0, 8(s6)

    csrw 0x7a0, x0
    csrw 0x7a2, s6            # watch RAM_BASE
    li   t3, 0x41             # mcontrol: load(bit0) | m(bit6)
    csrw 0x7a1, t3

    # load from a different address: must NOT fire
    lw   t1, 8(s6)
    li   t2, 0x9ABCDEF0
    bne  t1, t2, fail

watch_load:
    lw   s0, 0(s6)            # fires breakpoint (load suppressed first time)

    li   t0, 1
    bne  s1, t0, fail
    li   t1, 0x12345678
    bne  s0, t1, fail         # after resume the load returned the value
    j    pass

    .align 2
handler:
    csrr t0, mcause
    li   t1, 3
    bne  t0, t1, fail
    csrr t0, mepc
    la   t1, watch_load
    bne  t0, t1, fail
    csrw 0x7a1, x0
    li   s1, 1
    mret

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
