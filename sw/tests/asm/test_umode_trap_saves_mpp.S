# test_umode_trap_saves_mpp.S — trap saves interrupted privilege in MPP
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

    li   s8, 0
    ecall
    j    drop_to_u

drop_to_u:
    la   t0, u_trap
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_trap:
    ecall
    j    fail

    .align 2
trap_handler:
    csrr t1, mstatus
    srli t1, t1, 11
    andi t1, t1, 3
    beqz s8, check_m_mpp
    bnez t1, fail
    j    pass

check_m_mpp:
    li   t2, 3
    bne  t1, t2, fail
    addi s8, s8, 1
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
