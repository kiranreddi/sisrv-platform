# test_hpmcounters.S — Zihpm-style mhpmcounter/mhpmevent smoke
#
# Event map is platform-defined:
#   bit0 retire, bit1 load retire, bit2 store retire, bit3 taken branch,
#   bit4 control redirect, bit5 exception trap, bit6 interrupt, bit7 load-use stall.

.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    la    t0, trap_handler
    csrw  mtvec, t0

    # Allow U-mode to fetch this ROM test image.
    li    t0, 0x1FFF
    csrw  pmpaddr0, t0
    li    t0, 0x1F
    csrw  pmpcfg0, t0

    # Counter 3: retired instructions.
    csrw  0xB03, x0           # mhpmcounter3
    csrw  0xB83, x0           # mhpmcounter3h
    li    t0, 0x00000001
    csrw  0x323, t0           # mhpmevent3 = retire
    csrr  s0, 0xB03
    addi  t1, x0, 1
    addi  t1, t1, 1
    addi  t1, t1, 1
    csrr  s1, 0xB03
    bgeu  s0, s1, fail

    # Counter 4: loads.
    csrw  0xB04, x0
    csrw  0xB84, x0
    li    t0, 0x00000002
    csrw  0x324, t0
    li    t2, 0x80000080
    lw    t3, 0(t2)
    lw    t4, 0(t2)
    csrr  s2, 0xB04
    beqz  s2, fail

    # Counter 5: stores.
    csrw  0xB05, x0
    csrw  0xB85, x0
    li    t0, 0x00000004
    csrw  0x325, t0
    sw    t3, 4(t2)
    sw    t4, 8(t2)
    csrr  s3, 0xB05
    beqz  s3, fail

    # Counter 6: taken branches.
    csrw  0xB06, x0
    csrw  0xB86, x0
    li    t0, 0x00000008
    csrw  0x326, t0
    beq   x0, x0, 1f
    j     fail
1:  csrr  s4, 0xB06
    beqz  s4, fail

    # Counter 7: mcountinhibit bit 7 freezes HPM7.
    csrw  0xB07, x0
    csrw  0xB87, x0
    li    t0, 0x00000001
    csrw  0x327, t0
    li    t0, 0x80
    csrw  mcountinhibit, t0
    csrr  s5, 0xB07
    addi  t1, t1, 1
    addi  t1, t1, 1
    csrr  s6, 0xB07
    bne   s5, s6, fail
    csrw  mcountinhibit, x0

    # U-mode hpmcounter3 access is controlled by mcounteren bit 3.
    li    s7, 0
    li    t0, 0x8
    csrw  mcounteren, t0
    la    t0, u_hpm_allowed
    csrw  mepc, t0
    csrr  t1, mstatus
    li    t2, ~0x1800
    and   t1, t1, t2
    csrw  mstatus, t1
    mret

u_hpm_allowed:
    csrr  t0, 0xC03           # hpmcounter3
    ecall

u_hpm_denied:
    csrr  t0, 0xC03           # should trap as illegal when mcounteren[3]=0
    j     fail

trap_handler:
    csrr  t0, mcause
    beqz  s7, check_u_ecall
    li    t1, 2
    bne   t0, t1, fail
    j     pass

check_u_ecall:
    li    t1, 8
    bne   t0, t1, fail
    addi  s7, s7, 1
    csrw  mcounteren, x0
    la    t0, u_hpm_denied
    csrw  mepc, t0
    csrr  t1, mstatus
    li    t2, ~0x1800
    and   t1, t1, t2
    csrw  mstatus, t1
    mret

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
