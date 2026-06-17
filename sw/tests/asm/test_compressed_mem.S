# test_compressed_mem.S - RV32C compressed load/store immediate expansion

.section .text.init
.globl _start
_start:
    li      sp, 0x80001000
    li      a2, 0x80000080
    li      a3, 0x12345678

    .hword  0xc654          # c.sw a3, 12(a2)
    .hword  0x4658          # c.lw a4, 12(a2)
    bne     a4, a3, fail

    .hword  0xc636          # c.swsp a3, 12(sp)
    .hword  0x4732          # c.lwsp a4, 12(sp)
    bne     a4, a3, fail

pass:
    li      a0, 1
    li      a1, 0x10000000
    sw      a0, 0(a1)
1:  j       1b

fail:
    li      a0, 0
    li      a1, 0x10000000
    sw      a0, 0(a1)
2:  j       2b
