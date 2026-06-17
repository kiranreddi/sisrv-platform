# test_mcounteren.S — U-mode cycle/instret gated by mcounteren
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    li   t0, 0x1FFF
    csrw pmpaddr0, t0
    li   t0, 0x1F
    csrw pmpcfg0, t0

    li   s7, 0

    li   t0, 1
    csrw mcounteren, t0

    la   t0, u_rdcycle
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_rdcycle:
    csrr t0, cycle
    ecall

u_rdcycle_denied:
    csrr t0, cycle
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    beqz s7, cycle_ok
    li   t1, 2
    bne  t0, t1, fail
    j    pass

cycle_ok:
    li   t1, 8
    bne  t0, t1, fail
    addi s7, s7, 1
    csrw mcounteren, x0
    la   t0, u_rdcycle_denied
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
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
