# Formal (formal/)

Add SymbiYosys proofs as soon as:
- Milestone 1 core is stable (x0 invariant, no X on state)
- Milestone 3 AXI-Lite bridge exists (protocol checks)

Suggested proofs:
- regfile: x0 hardwired, single write semantics
- core: PC alignment, no illegal state transitions
- axi-lite: handshake stability, bounded response, no deadlock
