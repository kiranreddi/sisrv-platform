# Software (sw/)

This folder holds the bare-metal BSP and assembly tests for the sisrv-platform.

## Toolchain

- `riscv64-linux-gnu-gcc` (compile RV32I via `-march=rv32i_zicsr -mabi=ilp32`)
- Install: `sudo apt-get install gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu`

## Directory structure

- `bsp/` — Board Support Package
  - `crt0.S` — C runtime startup (stack setup, BSS clear, call main)
  - `link.ld` — Linker script (ROM at 0x0, RAM at 0x80000000)
- `tests/asm/` — Assembly test programs

## Test programs

Each test is a standalone assembly file that:
1. Executes the instructions being tested
2. Writes `1` to `0x10000000` (tohost) on success (PASS)
3. Writes `0` to `0x10000000` on failure (FAIL)

### Building tests

```bash
make sw          # Build all test hex files
make regress     # Build and run all tests
make run-test_addi  # Run a specific test
```

### Test list

| Test | Coverage |
|------|----------|
| test_pass | Minimal end-to-end sanity |
| test_addi | ADDI instruction |
| test_add_sub | ADD, SUB |
| test_logic | AND, OR, XOR + immediate forms |
| test_shift | SLL, SRL, SRA + immediate forms |
| test_slt | SLT, SLTU, SLTI, SLTIU |
| test_branch | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| test_lui_auipc | LUI, AUIPC |
| test_jal_jalr | JAL, JALR |
| test_load_store | LW, LH, LHU, LB, LBU, SW, SH, SB |
| test_x0 | x0 hardwired zero invariant |
| test_csr | CSR read/write (CSRRW, CSRRS, CSRRC, CSRRWI) |
| test_ecall | ECALL trap + MRET return |
