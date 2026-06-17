# test_pmp_na4.S — NA4 single-word match in U-mode
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

    # NA4 on RAM_BASE word only
    li   t0, 0x20000000
    csrw pmpaddr1, t0
    li   t0, 0x11
    csrw pmpcfg1, t0

    li   t0, 0xCAFEBABE
    li   s6, RAM_BASE
    sw   t0, 0(s6)
    li   t0, 0
    sw   t0, 4(s6)

    la   t0, u_test
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_test:
    lw   t0, 0(s6)
    li   t1, 0xCAFEBABE
    bne  t0, t1, fail
    lw   t0, 4(s6)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    li   t1, 5
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
