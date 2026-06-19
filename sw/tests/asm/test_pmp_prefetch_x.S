# test_pmp_prefetch_x.S — PMP X-check on a SEQUENTIALLY-prefetched word.
#
# The M9 prefetch slot fetches the next sequential word ahead of need. Its PMP
# fetch permission must be checked against the *prefetched* address, not the
# demand address. Here U-mode code falls through (no branch) into a word that a
# lower-priority NA4 entry denies execute — so the faulting word is reached via
# the prefetch path, not a redirect/demand fetch. Without the per-prefetch PMP
# check this would execute a no-X instruction in U-mode (silent privilege escape).

.include "pmp_csr.inc"
.section .text.init
.globl _start

#define PASS_ADDR 0x10000000

_start:
    la   t0, trap_handler
    csrw mtvec, t0

    # Entry 0 (lowest priority): NA4 over fault_word, R only (no X).
    la   t0, fault_word
    srli t0, t0, 2
    csrw pmpaddr0, t0
    PMP_SET_CFG 0, 0x11, t1, t2      # A=NA4(10), R=1 W=0 X=0

    # Entry 1: NAPOT [0,64KB) RWX so the rest of the U code is executable.
    li   t0, 0x1FFF
    csrw pmpaddr1, t0
    PMP_SET_CFG 1, 0x1F, t1, t2      # A=NAPOT(11), RWX

    la   t0, u_code
    csrw mepc, t0
    csrr t1, mstatus
    li   t2, ~0x1800                 # MPP <- U
    and  t1, t1, t2
    csrw mstatus, t1
    mret

    .align 2
u_code:
    addi x5, x0, 1                   # runs under entry 1 (X granted)
    addi x5, x5, 1
    addi x5, x5, 1
    addi x5, x5, 1
    addi x5, x5, 1
    addi x5, x5, 1
    # fall through (no branch) into the no-X word, reached via the prefetch slot
    .align 2
fault_word:
    addi x6, x0, 9                   # fetch must fault (cause 1) before executing
    j    fail                        # reached only if the no-X fetch was NOT denied

    .align 2
trap_handler:
    csrr t0, mcause
    li   t1, 1                       # instruction access fault
    bne  t0, t1, fail
    csrr t0, mtval
    la   t1, fault_word
    bne  t0, t1, fail                # mtval must be the prefetched faulting word
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
