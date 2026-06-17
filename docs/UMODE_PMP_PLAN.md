# Implementation Plan — U-mode + PMP (Privilege Separation)

**Status:** Ready for implementation
**Target branch:** new branch off current (`codex/benchmark-bringup` lineage) — do **not** mix with unrelated WIP
**Prereqs already landed:** vectored mtvec (MODE=1), RV32A atomics, misa.A/C
**Owner of this doc:** handover to implementing agent — this is self-contained; read it fully before touching RTL.

---

## 1. Goal & scope

Add **U-mode (user privilege)** and **PMP (Physical Memory Protection)** to `sisRvCore` so the
core can run untrusted code under M-mode supervision. This is the floor for any "secure MCU" /
RTOS privilege-separation claim and moves the core from *M-mode bare-metal* to *MCU-class IP*.

**In scope**
- Two privilege modes: **M (11)** and **U (00)**. No S-mode, no H.
- `mstatus` privilege fields: **MPP, MPIE/MIE (exist), MPRV, TW**. WARL masking on writes.
- Current-privilege register `priv` in the CSR unit; correct M↔U transitions on trap / MRET.
- **ECALL cause by mode** (U=8, M=11).
- **Privileged-instruction enforcement**: MRET in U → illegal; WFI in U with `TW=1` → illegal;
  CSR access below required privilege → illegal; read-only CSR write → illegal.
- **`mcounteren`** (0x306) + user counter shadows (`cycle`/`instret`, high halves) gated for U.
- **PMP**: `pmpcfg0..N`, `pmpaddr0..N`, parameter `PMP_ENTRIES` (default **8**, min 4 to meet claim).
  Address modes **OFF / TOR / NA4 / NAPOT**, **L (lock)**, R/W/X. Lowest-matching-entry wins.
  Checks on **fetch (X)**, **load/LR (R)**, **store/SC/AMO (W, AMO also needs R)**.
  PMP faults map to access faults: fetch=1, load=5, store/AMO=7.
- Verification: directed asm tests, cocotb unit tests for the PMP matcher, optional formal,
  enable the RISCOF privilege/PMP ACT subset, update Spike lock-step co-sim config.

**Out of scope (document as "not implemented")**
- S-mode and therefore **`medeleg`/`mideleg`/`sstatus`/`stvec`/`satp`/MMU** — all traps go to M.
- `mseccfg` / ePMP (Smepmp) MML/MMWP — base PMP only.
- Debug Program Buffer / system-bus PMP interaction (debug abstract GPR access is unaffected).
- `time` CSR as a real timer mirror (we add a counter shadow only if cheap; see §4.6).

---

## 2. Architecture orientation (where things live today)

| Concern | File / location | Notes |
|---|---|---|
| CSR registers, trap entry/MRET, mstatus MIE/MPIE shuffle | `rtl/core/sisCsr.sv` | Owns `mstatus`; this is where `priv`, `MPP`, `MPRV`, `TW`, `pmp*` live |
| Trap cause / EPC / enter / mret decisions | `rtl/core/sisRvCore.sv` `always_comb` "CSR control logic" (~L795–863) | Sets `trap_cause`, `trap_enter`, `mret_exec` at WB |
| EX-stage system decode (`ex_is_ecall/mret/csr_op`) | `sisRvCore.sv` ~L486–489 | Add priv-illegality here |
| Decode legality (`ex_dec_is_legal_eff`) | `sisRvCore.sv` ~L490 | Fold priv-illegal into the illegal-instruction path |
| Data address & bus request | `sisRvCore.sv` `d_req_addr = ex_mem_req_addr` (~L755), bus mux (~L755–774) | D-side PMP gate goes here, in EX before `d_req` issue |
| Fetch address & fetch error latch | `sisRvCore.sv` IF FSM, `if_id_fetch_err` (~L743–772, L1055–1072) | I-side PMP deny ORs into fetch err → cause 1 |
| mem-misalign / access-fault → trap | `sisRvCore.sv` WB trap logic (~L808–835) | PMP load/store fault reuses cause 5/7 path |
| Address map (for test design) | `rtl/bus/sisMemFabric.sv` header | ROM 0x0000_0000, RAM 0x8000_0000, CLINT 0x0200_0000, PLIC 0x0C00_0000, MMIO 0x1000_0000 |
| Core instantiation (param plumbing) | `rtl/sisPlatformTop.sv` ~L161 | Add `ENABLE_U`, `PMP_ENTRIES` |

**Key timing fact that makes this tractable:** `priv` changes **only** on trap entry and MRET,
and both cause a full pipeline redirect/flush (`ex_redirect`). So the current `priv` value is
always correct for the instruction at the head of the pipe — no per-stage privilege snapshot is
*required* for correctness, though latching `ex_priv → wb_priv` is the robust choice (see §4.4).

---

## 3. New module: `rtl/core/sisPmp.sv`

A **purely combinational** PMP matcher. One instance for the D-side; the I-side may instantiate
a second or share via a 2-way mux (recommend **two instances** — cleaner, area is tiny).

### 3.1 Interface

```systemverilog
module sisPmp #(
    parameter int PMP_ENTRIES = 8     // 0,4,8,16 supported; 0 ⇒ module hard-allows in M, denies in U
)(
    // Configuration (flattened CSR state from sisCsr)
    input  logic [PMP_ENTRIES-1:0][7:0]  pmpcfg,     // per-entry cfg byte {L,00,A[1:0],X,W,R}
    input  logic [PMP_ENTRIES-1:0][31:0] pmpaddr,    // per-entry pmpaddr (addr[33:2])

    // Access under test
    input  logic [31:0] addr,         // byte address
    input  logic [1:0]  priv,         // effective privilege for THIS access (MPRV-resolved for D)
    input  logic        req_r,        // load / LR
    input  logic        req_w,        // store / SC / AMO write half
    input  logic        req_x,        // instruction fetch

    output logic        allow         // 1 = permitted, 0 = PMP access fault
);
```

### 3.2 Matching algorithm (must implement exactly)

For each entry `i` in `0..PMP_ENTRIES-1`, compute `match[i]` from `A` field
(`pmpcfg[i][4:3]`) and the NAPOT/TOR decode below. Then:

1. **Select** the **lowest-indexed** `i` with `match[i]==1`.
2. If a match is found:
   - `perm_ok = (req_r→R) & (req_w→W) & (req_x→X)` using that entry's R/W/X bits.
   - **Locked entries (`L=1`) apply to M-mode too.** For an **unlocked** entry, **M-mode bypasses
     permission checks** (always `perm_ok=1`); U-mode obeys R/W/X. For a **locked** entry, both M and
     U obey R/W/X.
   - `allow = perm_ok`.
3. If **no** entry matches:
   - `priv==M` → `allow = 1` (M default-allow).
   - `priv==U` → `allow = 0` (U default-deny) **iff `PMP_ENTRIES>0`**. If `PMP_ENTRIES==0`,
     there is no protection and U is allowed (degenerate config; not our default).

**Address decode (PMP granularity G=0, 4-byte):**
- `OFF (A=0)`: never matches.
- `TOR (A=1)`: matches if `addr[33:2] ∈ [prev, this)` where `this = pmpaddr[i]`,
  `prev = (i==0) ? 0 : pmpaddr[i-1]`. Compare on the 32-bit `addr[33:2]` field
  (`addr_word = {2'b00, addr[31:2]}` for RV32, top bits 0). Note: for `i==0` the lower bound is 0.
- `NA4 (A=2)`: matches if `addr[33:2] == pmpaddr[i]` (single 4-byte word).
- `NAPOT (A=3)`: pmpaddr encodes base/size via trailing ones. Let `t = number of trailing 1s in
  pmpaddr[i]`. Region size = `2^(t+3)` bytes; base word = `pmpaddr[i] & ~((1<<(t+1))-1)`.
  Match if `(addr[33:2] >> (t+1)) == (pmpaddr[i] >> (t+1))`. Implement with a mask:
  `mask = ~(pmpaddr[i] ^ (pmpaddr[i]+1))` style trailing-ones expansion, then
  `match = ((addr[31:2] ^ pmpaddr[i]) & mask) == 0`. **Provide a small helper function;
  cover all-ones pmpaddr (whole-space NAPOT) and the t=0 (8-byte) case in unit tests.**

**Multi-byte access note:** the core only issues **naturally aligned** accesses (misaligned ones
trap *before* PMP, see §4.7 ordering), so each access lies within a single aligned word and cannot
straddle two PMP regions. Document this dependency in the module header.

---

## 4. Core & CSR changes (`sisCsr.sv`, `sisRvCore.sv`)

### 4.1 Parameters

- `sisCsr`: add `parameter bit ENABLE_U = 1'b1`, `parameter int PMP_ENTRIES = 8`.
- `sisRvCore`: add the same two params; pass through to `sisCsr` and to the `sisPmp` instances.
- `sisPlatformTop` (~L161): add `.ENABLE_U(1'b1)`, `.PMP_ENTRIES(8)`.
- `misa`: do **not** set a bit for U (there is no misa bit for U beyond the existing base);
  user-mode presence is reported via `misa`'s "U" bit (bit 20). **Set misa bit 20 when `ENABLE_U`.**
  Update `MISA_VALUE` and the `test_machine_counters` expected value accordingly.

### 4.2 New CSR state (in `sisCsr.sv`)

| CSR | Addr | Notes |
|---|---|---|
| `priv` (arch state, not a CSR) | — | 2-bit reg, **reset = M (2'b11)** |
| `mstatus` new fields | 0x300 | MPP[12:11], MPRV[17], TW[21]; MPIE[7]/MIE[3] already present |
| `mcounteren` | 0x306 | bits CY[0], TM[1], IR[2] |
| `pmpcfg0..3` | 0x3A0–0x3A3 | RV32: 4 bytes each; only as many as `PMP_ENTRIES` are live |
| `pmpaddr0..15` | 0x3B0–0x3BF | (extend to 0x3E0–0x3EF only if `PMP_ENTRIES>16`; we cap at 16) |
| user counter shadows (opt) | 0xC00/0xC02/0xC80/0xC82 | read-only mirrors of mcycle/minstret; gated by mcounteren+priv |

**`mstatus` WARL write mask** (replace the current unmasked `mstatus <= csr_new_val`):
- Writable bits we support: MIE[3], MPIE[7], MPRV[17], TW[21], MPP[12:11].
- **MPP is WARL to {2'b00 (U), 2'b11 (M)}**: if a write presents 2'b01/2'b10, store **2'b00**
  (U is the least-privileged supported). When `ENABLE_U==0`, MPP is read-only-zero... but we ship
  `ENABLE_U=1`, so MPP toggles U/M.
- All other bits read 0 (SD, FS, VS, XS, SPP, SIE, etc. — none supported). Build an explicit
  `MSTATUS_WMASK` and `mstatus <= (mstatus & ~WMASK) | (csr_new_val & WMASK)` then apply MPP-WARL.

### 4.3 Privilege transitions (in `sisCsr.sv` trap/mret block, ~L152–161)

**On `trap_enter`:** (in addition to existing MIE→MPIE, MIE=0, mepc/mcause/mtval)
```
mstatus.MPP <= priv;     // record interrupted privilege
priv        <= 2'b11;    // enter M
```
**On `mret_exec`:** (in addition to existing MPIE→MIE, MPIE=1)
```
priv        <= mstatus.MPP;
mstatus.MPP <= ENABLE_U ? 2'b00 : 2'b11;   // set to least-privileged supported
if (mstatus.MPP != 2'b11) mstatus.MPRV <= 1'b0;  // MRET to <M clears MPRV
```
(Evaluate `mstatus.MPP` **before** overwriting it — use a temp or order the nonblocking reads
carefully; recommend computing `next_priv = mstatus.MPP` first.)

**Outputs to add from `sisCsr`:** `priv_o[1:0]`, `mstatus_tw_o`, `mstatus_mprv_o`,
`mstatus_mpp_o[1:0]`, `mcounteren_o[2:0]`, plus the flattened `pmpcfg`/`pmpaddr` buses for the PMP.
Also export an **effective D-side privilege**:
`ls_priv = (mstatus_mprv_o && priv==M) ? mstatus_mpp_o : priv` (compute in core or CSR; core is fine).

### 4.4 Privilege available to EX/WB

Add `wb_priv[1:0]` (and optionally `ex_priv`) to the pipeline regs, latched like other EX→WB
fields, **or** simply consume `priv_o` directly in the WB trap `always_comb` since priv is stable
across the in-flight instruction (see §2). **Recommended:** latch `ex_priv <= priv_o` at
`id_to_ex_fire` and `wb_priv <= ex_priv` at `ex_to_wb_fire` for robustness and clean cosim.

### 4.5 Privileged-instruction enforcement (new illegal-instruction sources)

Compute a combinational `ex_priv_illegal` in EX and **OR it into the illegal path** that already
drives cause-2 traps (today gated by `!ex_dec_is_legal_eff`). Sources:

1. **MRET in U:** `ex_is_mret && (ex_priv != M)`.
2. **WFI in U with TW=1:** `ex_is_wfi && (ex_priv != M) && mstatus.TW`. (Need `ex_is_wfi`:
   `ex_is_system && funct3==000 && instr[31:20]==12'h105`. Today WFI is a legal NOP with no
   dedicated EX signal — add one.)
3. **CSR privilege:** for `ex_is_csr_op`, let `req_priv = ex_instr[29:28]` (csr_addr[9:8]).
   Illegal if `ex_priv < req_priv`. **Read-only CSR write:** if `ex_instr[31:30]==2'b11`
   (csr_addr[11:10]) and the op actually writes (CSRRW always; CSRRS/CSRRC with rs1≠x0) → illegal.
4. **mcounteren gating:** if `ex_is_csr_op`, `ex_priv==U`, target ∈ {0xC00,0xC02,0xC80,0xC82}
   and corresponding `mcounteren` bit == 0 → illegal. (Also applies to `time`/0xC01 if added.)

`ex_priv_illegal` must:
- Force the cause-2 illegal-instruction trap (route into the same WB branch as `!wb_dec_is_legal_eff`;
  add `wb_priv_illegal` pipeline bit or fold into `wb_dec_is_legal_eff` by ANDing legality with
  `!ex_priv_illegal` before latching). **Cleanest:** define
  `ex_legal_eff = ex_dec_is_legal_eff && !ex_priv_illegal` and latch that into `wb_dec_is_legal_eff`.
  Then `mtval` for the illegal trap is the instruction (already handled at L839).
- Be included in `ex_redirect` and `instr_retire` suppression exactly as `!ex_dec_is_legal_eff` is
  (L582, L601, L809–810) — by folding into `ex_legal_eff`/`wb_dec_is_legal_eff` you get this for free.

### 4.6 ECALL cause by mode

In WB trap logic (`sisRvCore.sv` L844–848), change:
```
end else if (wb_is_ecall) begin
    trap_enter = 1'b1;
    trap_cause = (wb_priv == 2'b11) ? 32'd11 : 32'd8;   // M=11, U=8
```
(`wb_priv` from §4.4. If not latching priv, use `priv_o` — valid because ecall flushes.)

**User counter shadows (optional, recommended for RTOS):** add read-only CSR reads for
0xC00 (cycle)=mcycle[31:0], 0xC02 (instret)=minstret[31:0], 0xC80/0xC82 high halves. Writes to
these are illegal (read-only, handled by §4.5.3). U-mode reads gated by mcounteren (§4.5.4).
M-mode reads always allowed.

### 4.7 PMP integration & fault ordering

**Instantiate two `sisPmp`:**
- `u_pmp_d`: `addr=alu_result` (D address), `priv=ls_priv`, `req_r=ex_is_load||ex_is_lr`,
  `req_w=ex_is_store||ex_is_sc||ex_is_amo_op`, `req_x=0`. AMO sets **both** r and w.
- `u_pmp_i`: `addr=<fetch address>`, `priv=priv_o` (fetch is **not** MPRV-affected),
  `req_x=1`, r/w=0.

**D-side gate (EX):** define `ex_pmp_d_fault = ex_mem_access_raw && !u_pmp_d.allow`. Then:
- **Suppress the bus request** when faulting (do not drive `d_req_valid`). Modify `ex_mem_access`
  (L548 region) so a PMP-denied access does **not** enter `EX_MEM_REQ/WAIT`; instead it completes
  to WB carrying a fault flag.
- Propagate as an access fault: extend `ex_complete_mem_err`-style signalling with a distinct
  `ex_pmp_fault` so WB sets cause **5 for loads/LR**, **7 for stores/SC/AMO**. Reuse the existing
  `wb_mem_err` cause-selection (L824–829: store?7:5) but ensure AMO/SC count as "store" and LR as
  "load". `trap_val = faulting address`.

**I-side gate (IF):** compute `pmp_fetch_deny = !u_pmp_i.allow` for the address being fetched, and
**OR it into the fetch-error latched into `if_id_fetch_err`** (L1055–1072 path; today fed by
`i_rsp_err`/`fetch_err_hold`). Result: `wb_fetch_err` → cause **1** (instruction access fault) at
L812–817, `trap_val = wb_pc`. Verify the PMP check uses the **same address** that was fetched
(handle the C-extension two-halfword fetch: deny if either halfword's word fails — simplest: check
the aligned word address of each fetch request as it is issued).

**Fault-priority ordering (define and document):**
1. Instruction-address-misaligned (control-flow target) — existing, EX.
2. **Fetch PMP / access fault** — cause 1.
3. Illegal instruction (incl. priv-illegal) — cause 2.
4. Load/store **address-misaligned** — cause 4/6 (existing, checked **before** PMP).
5. Load/store **PMP / access fault** — cause 5/7.
This matches the current WB `if/else if` order (L812–861); insert PMP load/store fault in the
**same branch** as `wb_mem_err` (after misalign), and fetch PMP via `wb_fetch_err` (already first).
**Misalign-before-PMP** is a deliberate, spec-permitted choice and keeps single-region access valid.

### 4.8 Reset & defaults

- `priv = M`, `mstatus = 0` (MPP=0, MPRV=0, TW=0), `mcounteren = 0`.
- All `pmpcfg = 0` (OFF, unlocked), all `pmpaddr = 0`. ⇒ At reset, M-mode has full access
  (no match → M default-allow); U-mode would be fully denied (correct — you must configure PMP
  before dropping to U).
- Locked entries (`L=1`) are **immutable until reset**: writes to a locked `pmpcfg` byte are
  ignored, and writes to `pmpaddr[i]` are ignored if `pmpcfg[i].L` **or** (`pmpcfg[i+1].A==TOR`
  and `pmpcfg[i+1].L`). Implement this WARL in the pmpcfg/pmpaddr write path.

---

## 5. Test plan

All directed tests live in `sw/tests/asm/` and run via `make regress` (auto-discovered, L34).
Pass = write 1 to `0x10000000`; fail = write 0 (see existing `test_atomics.S` for the harness
pattern, mtvec fail-handler, and `.align 2` requirement for trap handlers under C).

> **Build note:** privilege/PMP tests need `-march=rv32imac_zicsr`. Add a `test_priv%`/`test_pmp%`
> Makefile pattern rule mirroring the `test_atomic%` rule, **placed before the generic `%.elf`
> rule** (GNU Make 3.81 is first-match — this bit us on the atomics rule).

### 5.1 U-mode directed tests

| Test | Scenario | Expected |
|---|---|---|
| `test_umode_entry` | Set MPP=U, MEPC=user label, MRET → run user code, ECALL back | round-trips; lands in M handler |
| `test_umode_ecall_cause` | ECALL from U then (separately) from M | mcause = 8 (U), 11 (M) |
| `test_umode_mret_illegal` | Execute MRET while in U | illegal-instr trap, mcause=2, mepc=MRET pc |
| `test_umode_csr_priv` | From U: read/write `mstatus`(0x300), `mscratch`(0x340), `mtvec` | each → mcause=2 |
| `test_umode_csr_ro_write` | Write a read-only CSR (e.g. `misa` via CSRRS rs1≠0, or `mvendorid`) | mcause=2 |
| `test_umode_wfi_tw` | TW=1 + WFI in U → trap; TW=0 + WFI in U → NOP retire | trap then no-trap |
| `test_umode_mpp_warl` | Write MPP=2'b01 and 2'b10 | reads back 2'b00; MPP=11 stays 11 |
| `test_umode_mstatus_warl` | Write all-ones to mstatus | only MIE/MPIE/MPRV/TW/MPP[legal] stick; rest 0 |
| `test_umode_mprv` | M-mode MPRV=1, MPP=U, load/store to U-denied region faults; MPRV=0 ok | fault then ok |
| `test_umode_mprv_clear_on_mret` | MPRV=1, MRET to U | MPRV reads 0 after |
| `test_mcounteren` | U rdcycle/rdinstret: mcounteren bit set→ok, clear→trap | value then mcause=2 |
| `test_umode_trap_saves_mpp` | Trap from U then from M; inspect mstatus.MPP in handler | U then M |
| `test_umode_irq_to_m` | Fire MSIP/MTIP while in U | trap to M, MPP=U, handler runs, MRET resumes U |

### 5.2 PMP directed tests

| Test | Scenario | Expected |
|---|---|---|
| `test_pmp_tor_rw` | TOR region R-only over a RAM window; U load vs U store | load ok; store → mcause=7 |
| `test_pmp_napot_x` | NAPOT region without X over a code page; jump there in U | fetch fault, mcause=1 |
| `test_pmp_na4` | NA4 entry covers one word; access that word vs adjacent word (U) | covered ok; adjacent → fault |
| `test_pmp_no_match_u` | U access to addr with no matching entry | mcause = 5/7 (load/store) |
| `test_pmp_m_default_allow` | M access, no matching entry, unlocked | allowed (no trap) |
| `test_pmp_locked_in_m` | Locked entry, W=0; M-mode store into it | store fault even in M (mcause=7) |
| `test_pmp_priority` | entry0 = deny match, entry1 = allow same addr | denied (lowest index wins) |
| `test_pmp_napot_sizes` | NAPOT 8B and 4KB; in/out boundary addresses | inside ok, just-outside fault |
| `test_pmp_amo_perm` | AMO to R-only region; LR to R-only; SC to R-only | AMO fault(7), LR ok, SC fault(7) |
| `test_pmp_lock_immutable` | Set L=1, then rewrite pmpcfg byte & pmpaddr | unchanged on readback |
| `test_pmp_tor_addr_lock` | pmpcfg[i+1] TOR+L; write pmpaddr[i] | pmpaddr[i] write ignored |
| `test_pmp_causes` | Trigger fetch/load/store PMP faults | mcause 1 / 5 / 7, mtval=fault addr |

### 5.3 cocotb unit tests (`tb/cocotb/`, new `Makefile.pmp` + `test_pmp.py`)

Drive `sisPmp` directly (it's combinational — easy to exhaust):
- NAPOT decode across all `t` (sizes 8B…whole space), including all-ones pmpaddr.
- TOR boundaries: lower-inclusive / upper-exclusive; entry 0 lower bound = 0.
- NA4 exact-word match.
- Lowest-index priority with overlapping entries.
- M default-allow vs U default-deny on no-match.
- Locked-entry enforcement in M.
- R/W/X permission combinations vs req_r/req_w/req_x (incl. AMO r&w).
Add a corresponding CI step alongside the existing cocotb lanes (`make cocotb`).

### 5.4 Formal (optional but recommended)

`formal/pmp_props.sv` (SymbiYosys, bounded):
- **Priority:** if entry `j<i` matches, entry `i`'s permissions are irrelevant to `allow`.
- **Locked-in-M:** `L=1 && !perm_ok ⇒ !allow` regardless of priv.
- **No-match determinism:** `allow == (priv==M)` when all `match==0` (PMP_ENTRIES>0).

### 5.5 RISCOF (compliance)

The status doc notes **72 upstream PMP/A/privilege ACT tests currently excluded**. After this work:
- Update `verification/riscof/sisrv_isa.yaml`: add `U` to ISA string (`RV32IMACU...` / set the
  appropriate `User`/`Machine` privilege fields), declare `pmp_realized: true`, `pmp_entries: 8`,
  `pmp_granularity`, and the `mstatus`/`mcounteren` field support so riscv-config models the core.
- Enable the **privilege** and **pmp** test groups in the RISCOF suite filter; target a clean
  pass on the subset that matches our config (NAPOT/TOR/NA4, 8 entries, M+U).
- Document any tests still excluded (e.g. ePMP/Smepmp, S-mode) with reasons.

### 5.6 Spike lock-step co-sim

`verification/cosim/spike_lockstep.py` currently pins `--isa=rv32im_zicsr` (L69, L136) and builds
with `-march=rv32im_zicsr`. Update:
- Bump ISA to `rv32imac_zicsr` (atomics already landed — do this regardless) and add U-mode +
  PMP: `spike --isa=rv32imac_zicsr --priv=mu --pmpregions=8 ...`.
- Confirm the commit-log comparison still aligns; PMP faults change control flow, so a divergence
  would surface as a PC/insn mismatch — exactly what we want. Add at least one cosim seed that
  drops to U-mode and exercises a PMP fault path.
- Keep the existing min-instruction-count guard.

---

## 6. Implementation order (hard gates between steps)

| # | Step | Files | Gate |
|---|---|---|---|
| 1 | `priv` reg + mstatus MPP/MPRV/TW + WARL mask + transitions | `sisCsr.sv` | `make lint`; existing `make regress` still green (M-mode unchanged) |
| 2 | Export priv/tw/mprv/mcounteren from CSR; misa U bit; fix `test_machine_counters` | `sisCsr.sv`, `sisRvCore.sv` | lint; regress |
| 3 | ECALL cause-by-mode + priv-illegal (MRET-in-U, WFI-TW, CSR priv, RO-write) | `sisRvCore.sv` | lint; **U-mode §5.1 tests** pass |
| 4 | `mcounteren` + user counter shadows | `sisCsr.sv`, `sisRvCore.sv` | `test_mcounteren` |
| 5 | `sisPmp.sv` module + cocotb unit tests | `rtl/core/sisPmp.sv`, `tb/cocotb/` | `make cocotb` PMP lane green |
| 6 | pmpcfg/pmpaddr CSRs + WARL/lock immutability | `sisCsr.sv` | lint; readback tests |
| 7 | Wire D-side PMP gate (suppress bus, fault cause 5/7) | `sisRvCore.sv` | **PMP load/store §5.2 tests** |
| 8 | Wire I-side PMP gate (fetch fault cause 1) | `sisRvCore.sv` | `test_pmp_napot_x`, `test_pmp_causes` |
| 9 | Param plumbing `ENABLE_U`/`PMP_ENTRIES` | `sisPlatformTop.sv` | lint; full `make regress` (now ~70 tests) |
| 10 | Formal (optional) | `formal/pmp_props.sv` | `make formal` |
| 11 | RISCOF privilege/PMP subset | `verification/riscof/*` | `make riscof-act` clean on enabled subset |
| 12 | Cosim ISA bump + U/PMP seed | `verification/cosim/spike_lockstep.py` | `make cosim-lockstep` green |
| 13 | Docs | `INDUSTRY_COMPARISON.md`, `status.md`, `README.md`, `PROGRAMMERS_REFERENCE.md` | — |

**Each RTL step ends with `make lint` + `make regress RV_PREFIX=riscv64-elf-`.** The system here is
`riscv64-elf-` at `/opt/homebrew/bin/` (Makefile default prefix differs).

---

## 7. Verification checklist (acceptance)

- [ ] `make lint` clean (no IMPLICIT/UNDRIVEN from new signals — declare every helper).
- [ ] `make regress` green: all existing 46 tests **plus** new §5.1/§5.2 tests.
- [ ] `make cocotb` green incl. new PMP lane.
- [ ] M-mode-only behavior **bit-identical** to pre-change (reset boots M, no PMP configured ⇒
      full access) — confirm by running the unchanged regression.
- [ ] `test_machine_counters` updated for misa U bit (0x40001105 → 0x40101105 if bit20 set).
- [ ] RISCOF privilege/PMP subset passes; exclusions documented.
- [ ] Cosim green on `rv32imac_zicsr --priv=mu --pmpregions=8`, incl. a U-drop + PMP-fault seed.
- [ ] Docs updated: gap matrix rows **U-mode ❌→✅** and **PMP ❌→✅**; status milestone added;
      Programmer's Reference gains a "Privilege & PMP" section (CSR map, modes, fault causes).

---

## 8. Risk register & decisions to make

| Risk / decision | Guidance |
|---|---|
| **MPP read-before-write on MRET** | Latch `next_priv = mstatus.MPP` combinationally, then assign `priv` and clear MPP in the same `always_ff`. Don't read MPP after assigning it. |
| **Fetch PMP under C (two halfwords)** | Check each fetch *request* word as issued; deny if either fails. Don't try to PMP-check the assembled 32-bit instr after the fact. |
| **MPRV scope** | Affects **loads/stores only**, never fetch, and only when `priv==M`. Easy to over-apply — gate strictly. |
| **AMO permission** | AMO needs **R and W**; LR needs R; SC needs W. Faulting AMO/SC → cause 7, LR → cause 5. |
| **Misalign vs PMP order** | Misalign checked first (keeps single-region invariant). Documented, spec-permitted. |
| **Number of PMP entries** | Default 8 (meets "≥4" claim with headroom). Keep `PMP_ENTRIES` a clean param so 4/16 also build. |
| **NA4 vs granularity** | We support NA4 (G=0). If area/timing is a concern later, dropping NA4 (G≥1) is a documented option — but ship NA4 for spec completeness. |
| **WARL completeness** | mstatus, MPP, pmpcfg (reserved bits 6:5 = 0; A/L legal), pmpaddr lock — all need WARL. RISCOF will catch gaps; write the masks deliberately. |
| **Cosim divergence on CSR-only state** | Lockstep compares PC+insn (retire log), so silent CSR mismatches won't show unless they alter control flow. Lean on RISCOF for CSR-field WARL coverage. |
| **Debug interaction** | Debug abstract access touches the regfile, not memory — no PMP path. Progbuf/system-bus not implemented; note it. |

---

## 9. Reference: RV32 privilege/PMP facts the implementer needs

- **Privilege encodings:** U=00, S=01 (unused), M=11.
- **csr_addr[9:8] = minimum privilege**; `csr_addr[11:10]==11` ⇒ read-only.
- **mcause (exceptions):** 0 instr-addr-misalign, 1 instr access-fault, 2 illegal, 3 breakpoint,
  4 load-addr-misalign, 5 load access-fault, 6 store/AMO-addr-misalign, 7 store/AMO access-fault,
  8 ECALL-from-U, 11 ECALL-from-M.
- **mstatus bits:** MIE=3, MPIE=7, MPP=12:11, MPRV=17, TW=21. (SD/FS/VS/XS/SPP/SPIE/SIE = 0.)
- **pmpcfg byte:** R=0, W=1, X=2, A=4:3 (0 OFF,1 TOR,2 NA4,3 NAPOT), bits 6:5 reserved=0, L=7.
- **pmpaddr holds bits [33:2] of the address** (4-byte granularity); RV32 top bits are 0.
- **NAPOT:** size `2^(t+3)` where `t` = trailing-ones count in pmpaddr; `yyy0111`₂ ⇒ region.
- **No delegation:** without S-mode there is no medeleg/mideleg — every trap enters M.

---

*End of plan. Build it in the order of §6, gate on §7, and keep M-mode behavior identical when no
PMP is configured — that invariant is the safety net for the whole change.*
