# test_pmp_tor_rw.S — NAPOT R-only RAM: U load ok, U store faults
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000
#define RAM_BASE  0x80000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    li   t0, 0x1FFF
    csrw pmpaddr0, t0
    li   t0, 0x1F
    csrw pmpcfg0, t0

    # NAPOT R-only over RAM (same encoding as test_pmp_amo_perm)
    li   t0, 0x20007FFF
    csrw pmpaddr1, t0
    li   t0, 0x19
    csrw pmpcfg1, t0

    li   t0, 0x55AA55AA
    li   s6, RAM_BASE
    sw   t0, 0(s6)

    la   t0, u_test
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, 0xffffe7ff
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_test:
    li   s6, RAM_BASE
    li   t1, 0x11223344
    sw   t1, 0(s6)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    li   t1, 7
    bne  t0, t1, fail
    j    pass

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
