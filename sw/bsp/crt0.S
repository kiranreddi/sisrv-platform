.section .text.init
.globl _start
_start:
    # Set up stack pointer
    la    sp, _stack_top

    # Copy initialized data from ROM load address to RAM.
    la    t0, _data_lma
    la    t1, _data_start
    la    t2, _data_end
1:  bgeu  t1, t2, 2f
    lw    t3, 0(t0)
    sw    t3, 0(t1)
    addi  t0, t0, 4
    addi  t1, t1, 4
    j     1b
2:

    # Clear BSS
    la    t0, _bss_start
    la    t1, _bss_end
3:  bgeu  t0, t1, 4f
    sw    zero, 0(t0)
    addi  t0, t0, 4
    j     3b
4:

    # Jump to main (if linked)
    jal   ra, main

    # If main returns, signal PASS
    li    a0, 1
    li    a1, 0x10000000
    sw    a0, 0(a1)
5:  j     5b
