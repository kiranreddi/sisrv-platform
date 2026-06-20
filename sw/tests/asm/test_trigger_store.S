# test_trigger_store.S — hardware store watchpoint (mcontrol) -> breakpoint
# tdata1 = store|m, tdata2 = &word. A sw to &word faults (cause 3) and the store is
# SUPPRESSED (memory unchanged); handler confirms, clears the trigger, resumes; the
# sw then completes. A sw to a different address does NOT fire.
.section .text.init
.globl _start
#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    li   s1, 0                 # handler-ran flag
    la   t0, handler
    csrw mtvec, t0

    li   s6, RAM_BASE
    li   t0, 0xAAAA1111
    sw   t0, 0(s6)             # seed the watched word (no trigger yet)
    li   t0, 0xBBBB2222
    sw   t0, 8(s6)             # a different word

    csrw 0x7a0, x0
    csrw 0x7a2, s6             # tdata2 = RAM_BASE (watched address)
    li   t3, 0x42              # mcontrol: store(bit1) | m(bit6)
    csrw 0x7a1, t3

    # store to a DIFFERENT address: must NOT fire
    li   t0, 0xCCCC3333
    sw   t0, 8(s6)
    lw   t1, 8(s6)
    li   t2, 0xCCCC3333
    bne  t1, t2, fail

    li   s2, 0x55556666        # store value in a callee-saved reg the handler won't touch
watch_store:
    sw   s2, 0(s6)             # fires breakpoint; store suppressed first time

    li   t0, 1
    bne  s1, t0, fail          # handler must have run
    lw   t1, 0(s6)
    li   t2, 0x55556666
    bne  t1, t2, fail          # after resume the store completed
    j    pass

    .align 2
handler:
    csrr t0, mcause
    li   t1, 3
    bne  t0, t1, fail
    csrr t0, mepc
    la   t1, watch_store
    bne  t0, t1, fail          # mepc at the faulting store
    lw   t0, 0(s6)             # memory must be UNCHANGED (store suppressed)
    li   t1, 0xAAAA1111
    bne  t0, t1, fail
    csrw 0x7a1, x0            # clear trigger
    li   s1, 1
    mret                       # resume -> the sw now executes

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
