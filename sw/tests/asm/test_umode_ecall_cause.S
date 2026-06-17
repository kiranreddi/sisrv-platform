# test_umode_ecall_cause.S — ECALL from M (mcause=11) then U (mcause=8)
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

    li   s2, 0
    ecall
    j    drop_to_u

drop_to_u:
    la   t0, u_ecall
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, 0xffffe7ff
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_ecall:
    ecall
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    beqz s2, from_m
    li   t1, 8
    bne  t0, t1, fail
    j    pass

from_m:
    li   t1, 11
    bne  t0, t1, fail
    addi s2, s2, 1
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
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
