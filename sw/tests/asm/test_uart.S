# test_uart.S - Verify UART MMIO registers
#
# UART base: 0x1000_4000
#   +0x00 TXDATA
#   +0x04 RXDATA
#   +0x08 STATUS
#   +0x0C CTRL
#   +0x10 BAUDDIV

.section .text.init
.globl _start
_start:
    li    x1, 0x10004000       # UART base

    # STATUS should report TX ready and no RX data after reset.
    lw    x2, 8(x1)
    li    x3, 0x00000001
    bne   x2, x3, fail

    # CTRL defaults to TX enabled.
    lw    x2, 12(x1)
    li    x3, 0x00000001
    bne   x2, x3, fail

    # BAUDDIV read/write placeholder register.
    li    x2, 0x0000001B
    sw    x2, 16(x1)
    lw    x3, 16(x1)
    bne   x3, x2, fail

    # Enable loopback and transmit 'A'.
    li    x2, 0x00000003
    sw    x2, 12(x1)
    li    x4, 0x00000041
    sw    x4, 0(x1)

    # TXDATA readback should expose the last transmitted byte.
    lw    x5, 0(x1)
    bne   x5, x4, fail

    # Loopback should set RX_VALID.
    lw    x5, 8(x1)
    li    x6, 0x00000003
    bne   x5, x6, fail

    # RXDATA read should return 'A' and clear RX_VALID.
    lw    x5, 4(x1)
    bne   x5, x4, fail
    lw    x5, 8(x1)
    li    x6, 0x00000001
    bne   x5, x6, fail

    # Disable TX and verify TXDATA readback does not change.
    sw    x0, 12(x1)
    li    x7, 0x00000055
    sw    x7, 0(x1)
    lw    x5, 0(x1)
    bne   x5, x4, fail

    li    x10, 1
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b

fail:
    li    x10, 0
    li    x11, 0x10000000
    sw    x10, 0(x11)
1:  j     1b
