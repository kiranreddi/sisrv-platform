# test_atomics.S — RV32A atomics functional test
# Covers: LR.W+SC.W success, SC.W fail (no LR), SC.W fail (after trap clears reservation),
#         AMOSWAP, AMOADD, AMOXOR, AMOAND, AMOOR, AMOMIN/AMOMAX (signed), AMOMINU/AMOMAXU (unsigned).
#
# RAM base 0x80000000 — used as the atomic test word.
# Pass/fail signal: write 1/0 to 0x10000000 (testbench sentinel).

.section .text.init
.globl _start

_start:
    # Set up mtvec (direct mode, base=_start) for SC-after-trap test
    la   x1, trap_handler
    csrw mtvec, x1

    li   x28, 0x80000000    # test word address

    # ----------------------------------------------------------------
    # Test 1: LR.W + SC.W success
    # ----------------------------------------------------------------
    li   x1, 0xDEADBEEF
    sw   x1, 0(x28)
    lr.w x2, (x28)          # x2 = 0xDEADBEEF; sets reservation
    bne  x2, x1, fail
    li   x3, 0x12345678
    sc.w x4, x3, (x28)      # should succeed; x4 = 0
    bnez x4, fail
    lw   x5, 0(x28)
    bne  x5, x3, fail       # memory should hold 0x12345678

    # ----------------------------------------------------------------
    # Test 2: SC.W fail — no preceding LR (reservation cleared by SC in test 1)
    # ----------------------------------------------------------------
    li   x1, 0xABCD1234
    sc.w x4, x1, (x28)      # no active reservation; should fail (x4=1)
    li   x2, 1
    bne  x4, x2, fail
    lw   x5, 0(x28)
    li   x6, 0x12345678
    bne  x5, x6, fail       # memory unchanged

    # ----------------------------------------------------------------
    # Test 3: SC.W fail — reservation cleared by exception (ecall)
    # ----------------------------------------------------------------
    li   x1, 0x11223344
    sw   x1, 0(x28)
    lr.w x2, (x28)          # set reservation
    ecall                   # trap → reservation cleared, handler sets x29=1
    li   x3, 1
    bne  x29, x3, fail      # verify handler ran
    li   x3, 0xCAFEBABE
    sc.w x4, x3, (x28)      # reservation was cleared; must fail
    li   x2, 1
    bne  x4, x2, fail

    # ----------------------------------------------------------------
    # Test 4: AMOSWAP.W
    # ----------------------------------------------------------------
    li   x1, 0x00001111
    sw   x1, 0(x28)
    li   x2, 0x00002222
    amoswap.w x3, x2, (x28) # x3=old=0x00001111, mem=0x00002222
    bne  x3, x1, fail
    lw   x4, 0(x28)
    bne  x4, x2, fail

    # ----------------------------------------------------------------
    # Test 5: AMOADD.W
    # ----------------------------------------------------------------
    li   x1, 100
    sw   x1, 0(x28)
    li   x2, 42
    amoadd.w x3, x2, (x28)  # x3=old=100, mem=142
    bne  x3, x1, fail
    lw   x4, 0(x28)
    li   x5, 142
    bne  x4, x5, fail

    # ----------------------------------------------------------------
    # Test 6: AMOXOR.W
    # ----------------------------------------------------------------
    li   x1, 0xFF00FF00
    sw   x1, 0(x28)
    li   x2, 0x0F0F0F0F
    amoxor.w x3, x2, (x28)  # x3=old, mem=0xF00FF00F
    bne  x3, x1, fail
    lw   x4, 0(x28)
    li   x5, 0xF00FF00F
    bne  x4, x5, fail

    # ----------------------------------------------------------------
    # Test 7: AMOAND.W
    # ----------------------------------------------------------------
    li   x1, 0xFF00FF00
    sw   x1, 0(x28)
    li   x2, 0x0F0F0F0F
    amoand.w x3, x2, (x28)  # x3=old, mem=0x0F000F00
    bne  x3, x1, fail
    lw   x4, 0(x28)
    li   x5, 0x0F000F00
    bne  x4, x5, fail

    # ----------------------------------------------------------------
    # Test 8: AMOOR.W
    # ----------------------------------------------------------------
    li   x1, 0xFF00FF00
    sw   x1, 0(x28)
    li   x2, 0x0F0F0F0F
    amoor.w x3, x2, (x28)   # x3=old, mem=0xFF0FFF0F
    bne  x3, x1, fail
    lw   x4, 0(x28)
    li   x5, 0xFF0FFF0F
    bne  x4, x5, fail

    # ----------------------------------------------------------------
    # Test 9: AMOMIN.W — signed: -1 < 1, so mem gets -1
    # ----------------------------------------------------------------
    li   x1, 1
    sw   x1, 0(x28)
    li   x2, -1              # 0xFFFFFFFF signed = -1
    amomin.w x3, x2, (x28)  # x3=old=1, mem=min(1,-1)=-1
    bne  x3, x1, fail
    lw   x4, 0(x28)
    bne  x4, x2, fail

    # ----------------------------------------------------------------
    # Test 10: AMOMAX.W — signed: max(−1, 1) = 1, mem stays 1
    # ----------------------------------------------------------------
    li   x1, -1              # mem = -1 from previous test
    # mem already = -1 from test 9; no sw needed
    li   x2, 1
    amomax.w x3, x2, (x28)  # x3=old=-1, mem=max(-1,1)=1
    bne  x3, x1, fail
    lw   x4, 0(x28)
    bne  x4, x2, fail

    # ----------------------------------------------------------------
    # Test 11: AMOMINU.W — unsigned: 0x80000000 > 1, so min is 1
    # ----------------------------------------------------------------
    li   x1, 0x80000000
    sw   x1, 0(x28)
    li   x2, 1
    amominu.w x3, x2, (x28) # unsigned: min(0x80000000,1)=1; x3=old
    bne  x3, x1, fail
    lw   x4, 0(x28)
    bne  x4, x2, fail

    # ----------------------------------------------------------------
    # Test 12: AMOMAXU.W — unsigned: max(1, 0x80000000)=0x80000000
    # ----------------------------------------------------------------
    # mem = 1 from test 11
    li   x2, 0x80000000
    li   x1, 1
    amomaxu.w x3, x2, (x28) # unsigned: max(1,0x80000000)=0x80000000; x3=old=1
    bne  x3, x1, fail
    lw   x4, 0(x28)
    bne  x4, x2, fail

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

    # ----------------------------------------------------------------
    # Trap handler: for ecall (test 3), set x29=1 and return
    # ----------------------------------------------------------------
    .align 2        # ensure 4-byte alignment (mtvec_base strips bits[1:0])
trap_handler:
    csrr x30, mcause
    li   x31, 11            # ECALL from M-mode = cause 11
    bne  x30, x31, fail
    li   x29, 1             # signal that handler ran
    csrr x30, mepc
    addi x30, x30, 4        # skip ecall instruction
    csrw mepc, x30
    mret
