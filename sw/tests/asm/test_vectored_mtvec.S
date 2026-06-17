# test_vectored_mtvec.S — verify mtvec vectored mode (MODE=1)
# ROM base = 0x0000_0000. mtvec = _start | 1 → BASE=0x0, MODE=1.
# MSIP interrupt: cause=3, vectored offset = 3*4 = 12 bytes from BASE.
#
# Vector table (each entry = one 4-byte jump to the actual handler):
#   [0]  j setup        entry 0: sync exceptions → setup (falls through to fail since x20==0)
#   [4]  j fail         entry 1: should never fire
#   [8]  j fail         entry 2: should never fire
#   [12] j msip_handler entry 3: MSIP (cause code 3)

.section .text.init
.globl _start
_start:
    j    setup          # entry 0: sync exception target
    j    fail           # entry 1
    j    fail           # entry 2
    j    msip_handler   # entry 3 — MUST be at byte 12 (= 3*4 from _start)

msip_handler:
    # Verify mcause == 0x80000003
    csrr x5, mcause
    li   x6, 0x80000003
    bne  x5, x6, fail
    # Clear MSIP at CLINT 0x02000000
    li   x8, 0x02000000
    sw   x0, 0(x8)
    addi x20, x20, 1
    mret

setup:
    # Set mtvec = _start | 1  (BASE=0x00000000, MODE=1 vectored)
    la   x1, _start
    ori  x1, x1, 1
    csrw mtvec, x1

    li   x20, 0          # handler-fired counter

    # Enable MSIP in mie (bit 3) and global MIE in mstatus (bit 3)
    li   x1, 0x8
    csrw mie, x1
    csrr x1, mstatus
    ori  x1, x1, 0x8
    csrw mstatus, x1

    # Fire MSIP via CLINT (write 1 to 0x02000000)
    li   x8, 0x02000000
    li   x9, 1
    sw   x9, 0(x8)

    # Spin up to 10000 cycles waiting for interrupt
    li   x19, 0
wait_loop:
    addi x19, x19, 1
    li   x2, 10000
    bge  x19, x2, fail
    beqz x20, wait_loop

    # Verify handler fired exactly once
    li   x2, 1
    bne  x20, x2, fail

pass:
    li   x10, 1
    li   x11, 0x10000000
    sw   x10, 0(x11)
1:  j    1b

fail:
    li   x10, 0
    li   x11, 0x10000000
    sw   x10, 0(x11)
1:  j    1b
