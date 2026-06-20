# Implementation Plan — Hardware Debug Triggers (breakpoints / watchpoints)

**Status:** ✅ MVP LANDED — 2 type-2 `mcontrol` triggers (execute/load/store address breakpoints
→ breakpoint exception), `tselect`/`tdata1`/`tdata2`/`tinfo` CSRs with WARL, reset-inert.
Validated by `test_trigger_{exec,load,store,csr}` + 75/75 regression + lint + pipeline-debug.
Follow-on (not done): action=1 debug-mode entry (needs `dcsr`/`dpc`), value-match, range/NAPOT,
chaining, `mcontrol6`.
**Goal:** add a RISC-V Debug 0.13 **Trigger Module** so firmware/gdb can set hardware
breakpoints (execute) and watchpoints (load/store address) — table-stakes MCU debug that the
current DM (halt/resume/step + abstract GPR) lacks. Code in ROM/flash can't take software
breakpoints, so HW triggers are the only option there.

---

## 1. Scope

**In scope (MVP)**
- `NTRIGGER` trigger slots (default **2**), each a type-2 **`mcontrol`** trigger.
- CSRs: `tselect` (0x7A0), `tdata1` (0x7A1, = mcontrol), `tdata2` (0x7A2, compare value),
  `tinfo` (0x7A4).
- Match types: **execute** (PC), **load** address, **store** address; equality match
  (`match==0`); per-privilege enable (`m`, `u` bits).
- Action **0 = breakpoint exception** (cause 3) — fires *before* the matching instruction
  commits (execute) or the access completes (load/store). `mepc`/`mtval` set per spec.
- `hit` bit (tdata1[20]) set on fire.

**Out of scope (follow-on)**
- Action **1 = enter Debug Mode** — needs `dcsr`/`dpc`/debug-mode privilege the core does
  not yet implement. Note where it would hook in.
- Data-value match (`select=1`), chaining, `mcontrol6` (Debug 1.0), `icount`/`itrigger`/
  `etrigger` types, address-range (NAPOT/`maskmax`) matches. Equality only for MVP.

---

## 2. Architecture orientation

| Concern | Location |
|---|---|
| CSR file (trap CSRs, read/write, WARL) | `rtl/core/sisCsr.sv` |
| Breakpoint trap (cause 3, today from `ebreak`) | `sisRvCore.sv` WB trap `always_comb` (`wb_is_ebreak`) |
| Instruction PC available in EX | `ex_pc` |
| Computed load/store address in EX | `alu_result` (`ex_mem_req_addr`) for the access |
| Privilege (for m/u match) | `priv_o` from `sisCsr` (already exported) |
| Trap entry / `mepc`/`mtval` | `sisCsr` trap block + `sisRvCore` `trap_*` |

**Where to put it:** a small **`rtl/core/sisTrigger.sv`** module holding the trigger CSRs and a
purely combinational match function, instantiated in `sisRvCore`. Keeps `sisCsr` (already large)
focused. `sisCsr` forwards trigger-CSR reads/writes to it (or the module is addressed directly
from the core's CSR mux).

---

## 3. Trigger CSR encoding (type-2 `mcontrol`, RV32)

`tdata1` (mcontrol) fields used:
- `[31:28] type` = 2 (read-only).
- `[27] dmode` = 0 (M-mode-writable; we don't gate on debug mode in the MVP).
- `[20] hit` — set on match, W1C.
- `[15:12] action` — 0 = breakpoint exception (MVP supports 0 only; writing 1 is WARL-kept but
  treated as 0 until debug-mode lands, or rejected — pick and document).
- `[10:7] match` — 0 = equal (others WARL to 0).
- `[6] m`, `[3] u` — privilege enables.
- `[2] execute`, `[1] store`, `[0] load` — what to match.
- Other bits (`select`, `timing`, `sizelo`, `chain`) WARL-0.

`tdata2` — the compare value (PC or address). Full 32-bit.
`tselect` — index; WARL-clamped to `< NTRIGGER`.
`tinfo` — `[15:0]` bitmask of supported types → bit 2 set (mcontrol). Read-only.

A trigger is "enabled" when `type==2 && (m&priv==M | u&priv==U) && (execute|load|store)`.

---

## 4. Match & fire semantics

For the instruction in EX (valid, about to commit), for each trigger `t`:
- **execute**: `t.execute && (ex_pc == tdata2[t])` → fire.
- **load**:    `t.load    && ex_is_load  && (alu_result == tdata2[t])` → fire.
- **store**:   `t.store   && (ex_is_store|sc|amo) && (alu_result == tdata2[t])` → fire.
…gated by the privilege bits (`m`/`u` vs current priv).

On fire (action 0):
- Raise a **breakpoint exception (cause 3)** through the existing trap path, *instead of*
  committing the instruction (execute) / doing the access (load/store). I.e. it behaves like an
  `ebreak` at that instruction.
- `mepc` = the matching instruction's PC. `mtval`: per spec, for mcontrol breakpoints `mtval`
  is **0** (Debug 0.13) — set 0 (document; some tools expect the trigger address — keep 0 for
  spec-compliance, revisit if a tool needs it).
- Set `tdata1[t].hit`.
- Priority: a trigger fire is an exception; order it with the existing fault priority. Execute
  triggers fire before the instruction's own exceptions? Per spec, "before" the instruction —
  place the trigger-breakpoint **ahead of** the instruction's normal execution but the relative
  order vs. fetch/illegal is implementation-defined; put it after fetch faults and after
  illegal-decode (a trigger on an illegal insn still illegal-traps is acceptable), and before
  ecall/ebreak/mem traps. Document the chosen order.

The fire signal becomes another input to `ex_redirect` / the WB trap logic, mapped to cause 3,
mirroring `ebreak`.

---

## 5. Integration steps (gate after each)

| # | Step | Files | Gate |
|---|------|-------|------|
| 1 | `sisTrigger.sv`: CSRs (`tselect/tdata1/tdata2/tinfo`) + WARL + read mux | new file | `make lint` |
| 2 | Wire trigger CSR addresses into `sisCsr`/core CSR read+write path | `sisCsr.sv`/`sisRvCore.sv` | CSR read/write test |
| 3 | Combinational match (execute/load/store, priv-gated) → `ex_trigger_hit` | `sisRvCore.sv`, `sisTrigger.sv` | lint |
| 4 | Route fire → breakpoint trap (cause 3), suppress the instruction, set `hit` | `sisRvCore.sv` | directed tests |
| 5 | `tinfo`, `hit` W1C, `tselect` clamp, `dmode`/`action` WARL | `sisTrigger.sv` | lint; tests |
| 6 | Param plumb `NTRIGGER` to top | `sisPlatformTop.sv` | `make regress` |
| 7 | Docs: PRM "Trigger Module" section; INDUSTRY_COMPARISON debug row | docs | — |

Run each RTL step with `make lint && make regress RV_PREFIX=riscv64-elf-`.

---

## 6. Test plan (`sw/tests/asm/`)

- **test_trigger_exec**: set tdata1=execute|m, tdata2=&target; jump toward `target`; verify
  breakpoint trap (cause 3) at `target` with `mepc==&target`; handler clears the trigger and
  resumes; verify `target` then executes once.
- **test_trigger_load**: tdata1=load|m, tdata2=&word; `lw` from `&word` → cause 3, `mepc` at the
  load; a `lw` from a *different* address does **not** trap.
- **test_trigger_store**: tdata1=store|m, tdata2=&word; `sw` to `&word` → cause 3; memory
  **not** written (store suppressed); other-address `sw` doesn't trap.
- **test_trigger_priv**: trigger with `u` only; matching access in M-mode does **not** fire;
  drop to U and confirm it fires (reuses the U-mode harness).
- **test_trigger_hit_tselect**: write/read all triggers via `tselect`; verify `hit` sets on fire
  and is W1C; `tselect` clamps to `< NTRIGGER`; `tinfo` reads the type-2 bit.
- **test_trigger_disabled**: type-2 trigger with no execute/load/store bits, or wrong priv →
  never fires.

Plus: existing `test_ebreak`/`test_trap_faults` stay green (breakpoint-cause path shared).

---

## 7. Verification & acceptance

- [ ] `make lint` clean; `make regress` green (existing + new trigger tests).
- [ ] `make cosim-lockstep` — unaffected (triggers default-off; tdata1 reset = 0 → no fire), so
      random programs behave identically. (If a future cosim sets triggers, spike models them.)
- [ ] `make riscof-act` — unaffected (I/M/C subset). Trigger ACT tests are a later add.
- [ ] PRM updated; debug-capability row in INDUSTRY_COMPARISON flips to "DM 0.13 + 2 HW
      triggers (exec/load/store breakpoints)".

---

## 8. Risks / decisions

| Risk / decision | Guidance |
|---|---|
| **Fmax** — execute match compares `ex_pc==tdata2` (32-bit eq × NTRIGGER) and feeds the trap path. Keep the comparators shallow; they parallel the existing illegal/ebreak → trap path. Re-check STA. |
| **action=1 (debug mode)** | Not implemented (no `dcsr`/`dpc`). `tdata1.action` is WARL — decide whether to keep-as-written-but-treat-as-0 or force 0 on write. Force-0 is simplest/clearest for the MVP. |
| **mtval value** | Debug 0.13 says 0 for mcontrol; keep 0. Revisit if a debugger needs the address. |
| **store suppression timing** | The matching store must **not** write memory. Fire in EX before the bus write is issued (mirror the misaligned/PMP-fault suppression already in `ex_mem_access`). |
| **Reset** | All `tdata1=0` (type field still reads 2 on read, but enable bits 0 → no fire). Triggers are inert until firmware programs them — preserves all existing test/cosim behavior. |
| **Don't over-build** | Equality match, 2 triggers, action 0 only. Resist NAPOT/range/chain/value-match until there's a consumer. |

---

*End of plan. Land it in §5 order; the governing invariant is that an unprogrammed trigger
module (reset state) is completely inert, so nothing already passing changes.*
