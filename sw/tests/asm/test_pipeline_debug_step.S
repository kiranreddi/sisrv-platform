# test_pipeline_debug_step.S - program stepped by the Verilator debug pipeline test
.section .text.init
.globl _start
_start:
    addi  x1, x0, 1
    addi  x2, x1, 2
    addi  x3, x2, 3

pass:
    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
