# Formal verification (formal/)

## Current status

Formal proofs are planned for future milestones. The current verification is
through directed simulation tests (13/13 passing).

## Planned proofs (SymbiYosys)

### Core invariants
- **x0 always zero**: Prove that register x0 can never hold a non-zero value
- **PC alignment**: Prove PC is always word-aligned
- **No illegal state transitions**: Prove FSM only transitions to valid states

### AXI4-Lite bridge
- **Handshake stability**: VALID signals held until READY
- **No deadlock**: Bridge always eventually returns to idle
- **Bounded response**: Response within N cycles of request

### Bus fabric
- **No simultaneous routing**: Only one slave selected per transaction
- **Request forwarding**: Every accepted request produces a response

## Prerequisites

- [SymbiYosys](https://github.com/YosysHQ/sby) — formal verification framework
- [Yosys](https://github.com/YosysHQ/yosys) — synthesis tool
- A formal backend (e.g., Z3, boolector, or yices2)
