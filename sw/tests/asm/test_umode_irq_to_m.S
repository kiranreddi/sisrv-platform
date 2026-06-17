# test_umode_irq_to_m.S — trap from U saves MPP=U (ECALL stand-in for MSIP/MTIP path)
# MTIP delivery matches test_timer.S; this test verifies the MPP save half of the
# irq-to-M contract without relying on interrupt timing in the bare-metal harness.
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    la    t0, trap_handler
    csrw  mtvec, t0

    li    t0, 0x1FFF
    csrw  pmpaddr0, t0
    li    t0, 0x1F
    csrw  pmpcfg0, t0

    la    t0, u_ecall
    csrw  mepc, t0
    csrr  t1, mstatus
    li    t2, 0xffffe7ff
    and   t1, t1, t2
    ori   t1, t1, 0x88
    csrw  mstatus, t1
    mret

u_ecall:
    ecall
    j     fail

    .align 2
trap_handler:
    csrr  t0, mstatus
    srli  t0, t0, 11
    andi  t0, t0, 3
    bnez  t0, fail
    j     pass

pass:
    li    x10, 1
    li    x11, PASS_ADDR
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, PASS_ADDR
    sw    x10, 0(x11)
1:  j     1b
