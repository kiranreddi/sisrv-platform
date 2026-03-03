# Formal Verification (`formal/`)

## Current Status

All formal proofs are **passing**. The project uses Yosys + SymbiYosys for formal verification.

## Implemented Proofs

### ALU — All 10 operations (`alu_add.sv` + `alu_prove.ys`)
- **Proof method**: Yosys SAT (direct, no SMT solver needed)
- **Properties proven** (for all 2^64 input combinations):
  - ADD: `result == a + b`
  - SUB: `result == a - b`
  - SLL: `result == a << b[4:0]`
  - SLT: `result == (signed(a) < signed(b))`
  - SLTU: `result == (a < b)`
  - XOR: `result == a ^ b`
  - SRL: `result == a >> b[4:0]`
  - SRA: `result == signed(a) >>> b[4:0]`
  - OR: `result == a | b`
  - AND: `result == a & b`
  - Zero flag correctness for all operations
- **Runtime**: < 1 second

### Register File — x0 invariant (`regfile_x0.sv` + `regfile_x0.sby`)
- **Proof method**: k-induction via SymbiYosys + z3
- **Properties proven**:
  - `rs1_data == 0` whenever `rs1_addr == 0`
  - `rs2_data == 0` whenever `rs2_addr == 0`
  - Holds for any arbitrary write sequence

### Decoder — Field extraction & legality (`decode_legal.sv` + `decode_prove.ys`)
- **Proof method**: Yosys SAT
- **Properties proven** (for all 2^32 possible instructions):
  - Opcode field correctly extracted from `instr[6:0]`
  - rd, rs1, rs2, funct3, funct7 correctly extracted
  - U-type immediate has lower 12 bits always zero
  - B-type immediate has bit 0 always zero
  - J-type immediate has bit 0 always zero
  - `is_legal` is consistent with the OR of all type flags

## Running Formal Proofs

```bash
make formal
```

## Prerequisites

- [Yosys](https://github.com/YosysHQ/yosys) — synthesis/SAT proving
- [SymbiYosys](https://github.com/YosysHQ/sby) — formal verification framework
- [z3](https://github.com/Z3Prover/z3) — SMT solver (for k-induction proofs)
