# Software (sw/)

This folder holds the bare-metal BSP and tests.

Planned toolchain:
- riscv64-unknown-elf-gcc (compile RV32 via -march=rv32i / -mabi=ilp32)

Folders:
- bsp/   : crt0, linker script, simple drivers (UART/timer)
- tests/ : asm and C tests

As milestones progress, the test programs will be built into:
- ELF: for debug
- BIN/HEX: for ROM/RAM initialization in simulation
