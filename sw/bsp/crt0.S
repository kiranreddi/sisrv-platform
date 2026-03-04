.section .text.init
.globl _start
_start:
    # Set up stack pointer
    la    sp, _stack_top

    # Clear BSS
    la    t0, _bss_start
    la    t1, _bss_end
1:  bge   t0, t1, 2f
    sw    zero, 0(t0)
    addi  t0, t0, 4
    j     1b
2:

    # Jump to main (if linked)
    jal   ra, main

    # If main returns, signal PASS
    li    a0, 1
    li    a1, 0x10000000
    sw    a0, 0(a1)
3:  j     3b
