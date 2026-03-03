# Verification plan

## Phases
1) Directed instruction tests (per opcode group)
2) Software bring-up tests (C runtime, stack, memory)
3) Bus protocol stress (random waits, concurrency rules)
4) Formal proofs (high ROI): regfile/x0, pipeline invariants, AXI-Lite handshake

## Test types
### ASM directed (Tier 1)
- add/sub/and/or/xor/slt/sltu
- shifts (sll/srl/sra + immediate)
- branches (beq/bne/blt/bge/bltu/bgeu)
- jumps (jal/jalr)
- load/store (lb/lbu/lh/lhu/lw/sb/sh/sw)
- lui/auipc

### C tests (Tier 2)
- memcpy/memset
- CRC or small hash
- linked-list pointer chasing (load/stores)
- exception/trap tests (after CSR milestone)

### AXI wait-state stress
- Independent random stalls on AR, R, AW, W, B
- Random response latency
- Deadlock detection: timeout with full trace dump

## Debug knobs
- tracing on failure: always dump FST for last N cycles
- print architectural state every K cycles behind a verbose flag
- deterministic seed logging

## Coverage goals (practical)
- opcode coverage (seen each instruction)
- branch direction coverage (taken/not taken)
- load/store sizes and sign-ext coverage
- CSR access coverage once implemented
