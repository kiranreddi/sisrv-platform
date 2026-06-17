# test_umode_mprv_clear_on_mret.S — MRET to U clears MPRV
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

    csrr t0, mstatus
    li   t1, 0x20000
    or   t0, t0, t1
    csrw mstatus, t0

    la   t0, user_code
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, 0xffffe7ff
    and  t1, t1, t2
    li   t3, 0x20000
    or   t1, t1, t3
    csrw mstatus, t1
    mret

user_code:
    ecall
    j    fail

    .align 2
trap_handler:
    csrr t0, mstatus
    li   t1, 0x20000
    and  t0, t0, t1
    bnez t0, fail
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
