# test_pmp_napot_x.S — NAPOT RW without X: U fetch faults
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

    # 4KB NAPOT at RAM: R|W, no X — pmpaddr = 0x200001FF (t=9)
    li   t0, 0x200001FF
    csrw pmpaddr1, t0
    li   t0, 0x13
    csrw pmpcfg1, t0

  # Write ret instruction to RAM (jalr x0, 0(x0) encoded as 0x00008067)
    li   t0, 0x00008067
    li   s6, RAM_BASE
    sw   t0, 0(s6)

    la   t0, u_jump
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800
    and  t1, t1, t2
    csrw mstatus, t1
    mret

u_jump:
    jalr x0, 0(s6)
    j    fail

    .align 2
trap_handler:
    csrr t0, mcause
    li   t1, 1
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
