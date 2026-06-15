# test_compressed.S — RV32C only (halfword-aligned stream, no 32-bit span)

.section .text.init
.globl _start
_start:
    .hword 0x5529          # c.li a0, 42
    .hword 0x4581          # c.li a1, 0
    .hword 0x9b2a          # c.add a1, a0
    .hword 0x4505          # c.li a0, 1
    .align 2
    .word 0x100005b7        # lui a1, 0x10000
    .word 0x00a5a023        # sw a0, 0(a1)
1:  j      1b
