# test_pass.S — Minimal test: writes PASS (1) to tohost
# Expected: simulation exits with PASS

.section .text.init
.globl _start
_start:
    li    x1, 1                  # x1 = 1 (PASS code)
    li    x2, 0x10000000         # x2 = tohost address
    sw    x1, 0(x2)              # write PASS to tohost
1:  j     1b                     # infinite loop (sim should stop)
