# test_fetch_buffer_throughput.S — M9 fetch-buffer throughput guard
#
# A dense run of 32 compressed instructions (two 16-bit ops per 32-bit word).
# With the 1-word fetch buffer the second compressed instruction in each word is
# served from the buffer with no bus round-trip; a regression that reintroduces
# the per-halfword re-fetch roughly doubles the fetch cycles and trips the bound.
#
# Direct corebus only (excluded from the AXI-Lite regression, like
# test_pipeline_throughput) — AXI stalls perturb absolute cycle counts.

.section .text.init
.globl _start
_start:
    li    x8, 0
    .align 2          # start the measured block on a 4-byte (word) boundary
    csrr  x5, mcycle

    # 32 back-to-back compressed adds: x8 += 1, packed two per word.
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1
    c.addi x8, 1

    csrr  x6, mcycle
    sub   x7, x6, x5      # measured cycles for the 32-instruction block

    # Functional check: all 32 adds retired.
    li    x21, 32
    bne   x8, x21, fail

    # Throughput bound. Measured 49 cycles with the 1-word fetch buffer; disabling
    # the buffer (per-halfword re-fetch) measures 65. Bound at 58 catches that
    # regression with margin on both sides.
    li    x20, 58
    bgeu  x7, x20, fail

pass:
    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
