# test_umode_csr_priv.S — U-mode access to M-mode CSRs traps
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

    li   s3, 0

    la   t0, user_code
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

user_code:
    csrr t0, mstatus
    j    fail
u_mscratch:
    csrr t0, mscratch
    j    fail
u_mtvec:
    csrr t0, mtvec
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    li   t1, 2
    bne  t0, t1, fail
    addi s3, s3, 1
    li   t1, 1
    beq  s3, t1, resume_mscratch
    li   t1, 2
    beq  s3, t1, resume_mtvec
    li   t1, 3
    bne  s3, t1, fail
    j    pass

resume_mscratch:
    la   t0, u_mscratch
    csrw mepc, t0
    mret

resume_mtvec:
    la   t0, u_mtvec
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
