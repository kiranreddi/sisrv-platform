# Implementation Plan — M9 Fetch Buffer (front-end CPI recovery)

**Status:** Ready for implementation
**Target branch:** new branch off current line — keep isolated from feature work
**Motivation:** [`BENCHMARKS.md`](BENCHMARKS.md) — the C extension currently *costs* ~17–19%
throughput because the IF stage re-fetches words and double-fetches straddling
instructions. This plan recovers it.
**Owner of this doc:** handover to implementing agent — self-contained; read fully first.

> **Scope note / naming.** "M9" has been used loosely for two different ideas. This is the
> **front-end fetch-buffer** rework (IF stage). It is *not* the back-end MEM/WB dual-issue
> experiment that was tried and reverted for being slower on the one-cycle-RAM path. Keep
> them separate; this one is a pure win with no issue-width change.

---

## 1. Goal & scope

Add a small **instruction fetch buffer** to the IF stage so the core stops paying redundant
bus round-trips on compressed code. Target: close most of the `rv32imc` ↔ `rv32im` gap
(1.264 → ~1.45+ CoreMark/MHz, 0.400 → ~0.45+ DMIPS/MHz) **while keeping the code-density
win**, with **zero change to `rv32im` behavior or cycle counts** and **no architectural/ISA
change** (timing-only; lock-step co-sim stays bit-identical on retired PC/insn).

**In scope**
- A **1-word fetch buffer** (last fetched word + word-aligned address + valid + fetch-fault
  bit). Serve the second compressed halfword of a word, and the low half of a sequential
  straddling 32-bit instruction, **from the buffer with no bus access**.
- IF FSM restructure: **buffer-hit fast path** that decodes without `IF_REQ`/`IF_WAIT`.
- Correct invalidation on redirect, and correct PMP/fetch-fault handling for buffered words.
- A cycle-count micro-benchmark test to lock in the gain and prevent regression.

**Out of scope (note as future)**
- Multi-word prefetch / a true I-cache line (a 2–4 word buffer with prefetch-ahead is a
  follow-on; the 1-word buffer captures the dominant re-fetch cost first).
- Branch prediction, dual-issue, MEM/WB restructure — separate efforts.
- I/D coherence (Harvard, no stores to instruction memory — non-issue here).

---

## 2. Why it's slow today (root cause, with RTL references)

The IF FSM (`rtl/core/sisRvCore.sv`) issues **one word-aligned bus fetch per FSM pass and
keeps nothing across instructions**:

- Request address is always word-aligned:
  `i_req_addr = {fetch_pc[31:2], 2'b00}` ([sisRvCore.sv:853](../rtl/core/sisRvCore.sv:853)).
- Response handling at [sisRvCore.sv:1113-1173](../rtl/core/sisRvCore.sv:1113).

Two costs that `rv32im` (all 32-bit, all aligned) never pays:

1. **Word re-fetch for the second compressed halfword.** Offset-0 compressed lower half
   retires with `fetch_pc <= fetch_req_pc + 2` ([:1136](../rtl/core/sisRvCore.sv:1136));
   the next pass has `fetch_pc[1]==1` but `i_req_addr` is still the **same word**, so the
   core re-requests a word it already had to read the upper 16 bits
   ([:1147-1161](../rtl/core/sisRvCore.sv:1147)).
2. **Straddle double-fetch.** Offset-2 with a 32-bit low half (`[17:16]==2'b11`) saves the
   low half into `fetch_upper_hold` and takes a second sequential fetch via
   `IF_SECOND_REQ`/`IF_SECOND_WAIT` ([:1157-1172](../rtl/core/sisRvCore.sv:1157)).

Evidence ([`BENCHMARKS.md`](BENCHMARKS.md)): Dhrystone retires an **identical 507
instructions/iteration** under both ISAs, yet `rv32imc` spends 1,422 cycles/iter vs
`rv32im`'s 1,215 — the whole delta is front-end CPI (2.804 vs 2.396).

---

## 3. The design — 1-word fetch buffer

### 3.1 New state (IF stage)

```systemverilog
logic        fbuf_valid;     // buffer holds a fetched word
logic [29:0] fbuf_word_addr; // word address (PA[31:2]) of the buffered word
logic [31:0] fbuf_data;      // the 32-bit fetched word
logic        fbuf_err;       // fetch fault (bus err or PMP deny) latched with the word
```

Reset: `fbuf_valid <= 1'b0`.

### 3.2 Fill

Whenever a bus instruction response is consumed (`if_rsp_fire` and not discarded), latch the
word into the buffer alongside the existing decode:
```systemverilog
fbuf_valid     <= 1'b1;
fbuf_word_addr <= fetch_req_pc[31:2];
fbuf_data      <= i_rsp_rdata;
fbuf_err       <= i_rsp_err || !pmp_fetch_allow;
```
(For the `IF_SECOND_WAIT` case, latch the **second** word — `fetch_req_pc[31:2] + 1` — so a
following instruction in that next word can hit.)

### 3.3 Hit detection and fast path

Define a combinational hit for the word the PC currently needs:
```systemverilog
wire [29:0] need_word = fetch_pc[31:2];
wire        fbuf_hit  = fbuf_valid && (fbuf_word_addr == need_word);
```
Restructure the `IF_REQ` behavior so that **on a hit, the instruction is assembled directly
from `fbuf_data` in the same cycle with no `i_req_valid` and no `IF_WAIT`** — reusing the
exact halfword-selection / compressed-vs-32-bit / straddle logic that today runs in the
`IF_WAIT` branch, but sourced from `fbuf_data`/`fbuf_err` instead of `i_rsp_rdata`/`i_rsp_err`.
On a **miss**, behave exactly as today (issue the word-aligned request, go to `IF_WAIT`).

This single change removes cost (1) entirely: after an offset-0 compressed instruction,
`fetch_pc` advances to offset-2 of the **same** word, which is now a guaranteed `fbuf_hit`
→ the upper compressed instruction (or the low half of a straddle) is served with no bus
access.

### 3.4 Straddle handling with the buffer

For a 32-bit instruction straddling words W → W+1:
- Low half comes from `fbuf_data` (word W) — already resident in the common sequential case.
- Issue **one** fetch for word W+1, combine `i_rsp_rdata[15:0]` with the buffered low half.
- This keeps the `IF_SECOND_*` path but eliminates the *re-fetch of W* when W was buffered.
  (If the core just branched into offset-2 of W, W is fetched once then W+1 once — genuinely
  two words of data, unavoidable without prefetch; that's the rare case.)

### 3.5 Invalidation & correctness

- **Redirect** (branch/jump/trap/MRET — the existing `ex_redirect` and `wb_single_step_stop`
  blocks at [sisRvCore.sv:1288-1314](../rtl/core/sisRvCore.sv:1288)): the buffer may still be
  valid and is keyed by address, so a redirect **does not require invalidation** — a target
  landing in a still-buffered word is a legitimate hit (e.g. a tight backward branch within
  one word). Keep `fbuf_valid` across redirect; rely on the `fbuf_word_addr == need_word`
  check. **Simpler-but-safe fallback:** invalidate on redirect if any corner case is
  unclear, then optimize. Decide explicitly and document.
- **`if_discard_rsp`**: when an in-flight response is being discarded after a redirect
  ([:1294-1298](../rtl/core/sisRvCore.sv:1294)), do **not** fill the buffer from it.
- **PMP / privilege:** privilege only changes via redirect; serve-from-buffer re-evaluates
  `pmp_fetch_allow` combinationally on `fbuf_word_addr` anyway, so a U→M or M→U change (which
  redirects) is safe. Carry `fbuf_err` so a buffered access-faulting word still traps with
  cause 1.
- **Single-outstanding bus invariant** is preserved — a hit issues *no* request, so there is
  never more than one outstanding fetch.

### 3.6 Optional follow-on (not this milestone)

A **2-word buffer with prefetch-ahead** (fetch W+1 while decoding W) would also remove the
rare branch-into-offset-2 straddle cost and smooth back-to-back 32-bit fetches. Land the
1-word buffer first, measure, then decide if prefetch is worth the timing cost.

---

## 4. Implementation order (gate after each)

| # | Step | Gate |
|---|------|------|
| 1 | Add `fbuf_*` state + reset; fill on `if_rsp_fire` (no hit path yet — buffer is write-only) | `make lint`; `make regress` unchanged |
| 2 | Add `fbuf_hit` + serve-from-buffer fast path in `IF_REQ`, refactoring the halfword/straddle assembly to take its word from a source mux (`fbuf_data` on hit, `i_rsp_rdata` on miss) | `make regress` all green |
| 3 | Carry `fbuf_err` into the fetch-fault path; confirm cause-1 still precise | `test_trap_faults`, `test_pmp_*` green |
| 4 | Decide redirect policy (keep-and-addr-check vs invalidate); implement | `test_pmp_napot_x`, branch/jump tests green |
| 5 | Cycle-count micro-benchmark test (C-dense loop) | new test passes; records baseline |
| 6 | Re-run benchmarks; confirm `rv32imc` improves and **`rv32im` is unchanged** | `make benchmark` |
| 7 | Re-run STA; confirm Fmax not regressed by the fast-path combinational decode | `make sta-sky130` |

Run each RTL step with `make lint && make regress RV_PREFIX=riscv64-elf-` (toolchain prefix
is `riscv64-elf-`).

---

## 5. Test plan

### 5.1 Correctness (directed asm — `sw/tests/asm/`)
- **Sequential C pairs:** a run of compressed instructions packed two-per-word; verify
  correct execution and (via the micro-benchmark) that the second-in-word costs no extra
  fetch.
- **Straddling 32-bit instruction:** force a 32-bit instruction to start at a 2-byte offset
  (e.g. one C instruction then a 32-bit instruction) crossing a word boundary; verify correct
  decode/execution.
- **Backward branch within one word:** tight loop whose body fits in a single word; verify a
  buffer hit on the branch target (must still execute correctly).
- **Branch/jump to a new word:** verify the buffer miss path issues a fresh fetch and the old
  word isn't wrongly reused (addr-check correctness).
- **Fetch fault on a buffered word path:** a PMP/access fault region; verify cause-1 still
  precise whether served from bus or buffer (`fbuf_err`).
- Existing `test_compressed*`, `test_pmp_napot_x`, `test_trap_faults`, branch/jump/jalr-align
  tests must all stay green.

### 5.2 Performance lock-in
- Add `test_fetch_buffer_throughput.S` (mirror `test_pipeline_throughput.S`): a fixed C-dense
  loop with a known retired-instruction count; assert the cycle count is **at/below a
  threshold** so a future regression that reintroduces re-fetch fails CI. Wire it like the
  existing throughput guard.

### 5.3 Whole-program
- `make benchmark RV_PREFIX=riscv64-elf-` — record new `rv32imc` CoreMark/Dhrystone; confirm
  **`rv32im` numbers are byte-identical** to today (proves no collateral change).
- `make cosim-lockstep COSIM_SEEDS=10000` — must stay green (timing-only change is invisible
  to retired-PC/insn lock-step; this is the safety net that the buffer never returns wrong
  data).
- `make riscof-act` — unchanged pass.

### 5.4 Formal (optional)
- Invariant: a buffer hit returns the same bytes a bus fetch of `need_word` would
  (`fbuf_valid && addr-match ⇒ served data == memory[need_word]`), assuming I-memory is
  immutable (Harvard). Bounded SymbiYosys check.

---

## 6. Acceptance criteria

- [ ] `make lint` clean; `make regress` green (existing + new fetch tests).
- [ ] `rv32im` CoreMark/Dhrystone cycle counts **unchanged** vs current `build/bench/summary.json`.
- [ ] `rv32imc` CoreMark/MHz and DMIPS/MHz **materially improved** (target: ≥80% of the gap
      to `rv32im` closed by the 1-word buffer; record actuals in `BENCHMARKS.md`).
- [ ] `make cosim-lockstep` (10k) green; `make riscof-act` green.
- [ ] `make sta-sky130` — Fmax not regressed (or regression quantified and accepted).
- [ ] `BENCHMARKS.md` updated with before/after and the buffer description; the "Analysis"
      section's "Fix direction" paragraph moved to "done".

---

## 7. Risks & decisions

| Risk / decision | Guidance |
|---|---|
| **Critical path / Fmax** | The serve-from-buffer fast path adds a combinational route from `fbuf_data` through halfword-select/decompress into ID. Keep the mux shallow (source-select before the existing assembly logic, not a parallel copy). Re-run STA; if Fmax drops, consider registering the buffer-hit decode (costs the 1-cycle saving on hits — measure both). |
| **Redirect staleness** | Keep-and-addr-check is the performant choice and is safe because hits are address-verified. If unsure, ship invalidate-on-redirect first (still removes the dominant same-word re-fetch, since that doesn't cross a redirect), then optimize. |
| **Discarded responses** | Never fill the buffer from a response being discarded (`if_discard_rsp`) — would cache a wrong-path word. |
| **Fetch-fault provenance** | Latch `fbuf_err` with the word; a hit on a faulting word must still raise cause-1 with `mtval = PC`. |
| **`rv32im` neutrality** | All-aligned 32-bit code: every word is consumed whole, so the buffer is filled and immediately superseded — there must be **no extra cycle and no behavioral change**. Verify by byte-identical `rv32im` benchmark cycle counts. |
| **Don't over-build** | 1-word buffer first. Resist jumping to a multi-word I-cache; measure the 1-word win before adding prefetch complexity and its timing cost. |

---

*End of plan. Land it in §4 order, gate on §6, and hold the invariant that `rv32im` cycle
counts do not move — that's the proof the change is a pure front-end win.*
