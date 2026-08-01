# sisrv-platform Makefile

VERILATOR ?= verilator
TOP       ?= sisPlatformTop
ROOT      := $(CURDIR)
BUILD     ?= build
HOST_JOBS ?= $(shell nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
USE_AXIL  ?= 0
AXIL_STALL_RATE ?= 0
# Keep corebus and AXI simulation binaries separate; append _stall<N> for stalled AXI runs.
AXIL_SUFFIX := $(if $(filter 1,$(USE_AXIL)),_axil,)
STALL_SUFFIX := $(if $(and $(filter 1,$(USE_AXIL)),$(filter-out 0,$(AXIL_STALL_RATE))),_stall$(AXIL_STALL_RATE),)
SIM_SUFFIX := $(AXIL_SUFFIX)$(STALL_SUFFIX)
SIM       ?= $(BUILD)/sim_$(TOP)$(SIM_SUFFIX)

# RISC-V toolchain
RV_PREFIX ?= riscv64-linux-gnu-
RV_GCC    := $(RV_PREFIX)gcc
RV_OBJCOPY := $(RV_PREFIX)objcopy
RV_OBJDUMP := $(RV_PREFIX)objdump

RV_ARCH   := rv32im_zicsr
RV_ABI    := ilp32
RV_CFLAGS := -march=$(RV_ARCH) -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none

RTL_DIRS := rtl rtl/core rtl/bus rtl/periph rtl/debug
TB_DIRS  := tb/verilator tb/models

RTL_SRCS := $(wildcard $(addsuffix /*.sv,$(RTL_DIRS)))
TB_SRCS  := $(wildcard $(addsuffix /*.sv,$(TB_DIRS)))
CPP_SRCS := tb/verilator/main.cpp
PIPELINE_DEBUG_CPP_SRCS := tb/verilator/pipeline_debug_main.cpp

# Test sources
# Cycle-count guard tests are corebus-only (AXI stalls perturb absolute cycles), so
# they are excluded from the auto-discovered regression and run via dedicated targets.
PIPELINE_THROUGHPUT_TEST := sw/tests/asm/test_pipeline_throughput.S
FETCH_THROUGHPUT_TEST    := sw/tests/asm/test_fetch_buffer_throughput.S
CYCLE_GUARD_TESTS        := $(PIPELINE_THROUGHPUT_TEST) $(FETCH_THROUGHPUT_TEST)
ASM_TESTS := $(filter-out $(CYCLE_GUARD_TESTS),$(wildcard sw/tests/asm/*.S))
ASM_HEXES := $(patsubst sw/tests/asm/%.S,$(BUILD)/tests/%.hex,$(ASM_TESTS))
# Full asm set for offline UVM/cocotb artifact packages (includes cycle-guard tests).
ALL_ASM_TESTS := $(wildcard sw/tests/asm/*.S)
ALL_ASM_HEXES := $(patsubst sw/tests/asm/%.S,$(BUILD)/tests/%.hex,$(ALL_ASM_TESTS))

.PHONY: sim lint clean wave regress regress-axil regress-axil-stall pipeline-debug pipeline-throughput fetch-throughput sw sw-all sw-artifacts sw-from-artifacts all tests cocotb formal formal-axil formal-questa \
        sim-questa sim-vcs sim-xcelium regress-questa regress-vcs regress-xcelium regress-all-sims \
        synth sta sta-sky130 cosim-lockstep cosim-lockstep-imac cosim-lockstep-imac-upmp cosim-lockstep-imac-upmp-smoke \
        coverage-unit \
        benchmark benchmark-coremark benchmark-dhrystone benchmark-smoke \
        riscof-check-tools riscof-smoke riscof-act riscof-act-full riscof-rv32i riscof-rv32im \
        fetch-sky130-pdk synth-harden openroad-harden openroad-gds openroad-drc openroad-lvs harden \
        cocotb-axil-stall-nightly


all: sim

# Build Verilator simulation binary
$(SIM): $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS)
	@mkdir -p $(BUILD)
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-SELRANGE -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET --cc --exe --build \
	  -O3 --trace-fst -DASSERT \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph -Irtl/debug -Itb/models \
	  --top-module $(TOP) \
	  -GROM_INIT_FILE='"rom.hex"' \
	  -GRAM_INIT_FILE='"ram.hex"' \
	  -GUSE_AXIL=$(USE_AXIL) \
	  -GAXIL_STALL_RATE=$(AXIL_STALL_RATE) \
	  $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS) \
	  -o sim_$(TOP)
	@mkdir -p $(BUILD)
	@cp obj_dir/sim_$(TOP) $(SIM)

# Run simulation with a specific test hex
sim: $(SIM) $(BUILD)/tests/test_pass.hex
	@touch ram.hex
	@cp $(BUILD)/tests/test_pass.hex rom.hex
	@$(SIM) && rm -f rom.hex ram.hex || (rm -f rom.hex ram.hex; exit 1)

# Lint all RTL
lint:
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-SELRANGE -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET --lint-only \
	  --top-module $(TOP) \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph -Irtl/debug -Itb/models \
	  $(RTL_SRCS)

wave:
	@echo "Open waves with: gtkwave build/wave.fst"

# Build a single assembly test: .S -> .elf -> .bin -> .hex
# Specific arch rules must come BEFORE the generic %.elf rule (Make 3.81 first-match).
$(BUILD)/tests/test_compressed%.elf: sw/tests/asm/test_compressed%.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) -march=rv32imc_zicsr -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/test_atomic%.elf: sw/tests/asm/test_atomic%.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) -march=rv32imac_zicsr -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/test_umode%.elf: sw/tests/asm/test_umode%.S sw/tests/asm/pmp_csr.inc sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) -march=rv32imac_zicsr -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none -I sw/tests/asm -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/test_pmp%.elf: sw/tests/asm/test_pmp%.S sw/tests/asm/pmp_csr.inc sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) -march=rv32imac_zicsr -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none -I sw/tests/asm -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/test_mcounteren.elf: sw/tests/asm/test_mcounteren.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) -march=rv32imac_zicsr -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/test_fetch_buffer%.elf: sw/tests/asm/test_fetch_buffer%.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) -march=rv32imac_zicsr -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/%.elf: sw/tests/asm/%.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) $(RV_CFLAGS) -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/%.bin: $(BUILD)/tests/%.elf
	$(RV_OBJCOPY) -O binary $< $@

$(BUILD)/tests/%.hex: $(BUILD)/tests/%.bin
	python3 -c "import pathlib,sys; d=pathlib.Path(sys.argv[1]).read_bytes(); \
	  print('\n'.join(f'{int.from_bytes(d[i:i+4],\"little\"):08x}' for i in range(0,len(d),4)))" $< > $@

$(BUILD)/tests/%.objdump: $(BUILD)/tests/%.elf
	$(RV_OBJDUMP) -d -M no-aliases $< > $@

# Build all test hex files
sw: $(ASM_HEXES)
	@echo "Built $(words $(ASM_HEXES)) test hex files."

# Build every asm image, including cycle-guard tests (for artifact packaging / UVM).
sw-all: $(ALL_ASM_HEXES)
	@echo "Built $(words $(ALL_ASM_HEXES)) asm images (full set)."

# Package prebuilt ELF/BIN/HEX for hosts without a RISC-V toolchain.
# CI uploads build/sw-artifacts/sisrv-sw-artifacts.tar.gz
SW_ARTIFACTS_OUT ?= $(BUILD)/sw-artifacts
SW_ARTIFACTS_TGZ ?= $(SW_ARTIFACTS_OUT)/sisrv-sw-artifacts.tar.gz
sw-artifacts:
	@bash scripts/package_sw_artifacts.sh

# Install a downloaded artifact tarball into build/tests/ (no local toolchain required).
# Example:
#   gh run download <run-id> -n sisrv-sw-artifacts -D /tmp/sw-art
#   make sw-from-artifacts SW_ARTIFACTS_TGZ=/tmp/sw-art/sisrv-sw-artifacts.tar.gz
sw-from-artifacts:
	@test -n "$(SW_ARTIFACTS_TGZ)" || (echo "Set SW_ARTIFACTS_TGZ=path/to/sisrv-sw-artifacts.tar.gz"; exit 2)
	@test -s "$(SW_ARTIFACTS_TGZ)" || (echo "Missing $(SW_ARTIFACTS_TGZ)"; exit 2)
	@mkdir -p $(BUILD)/tests
	@tmpdir=$$(mktemp -d); \
	  tar -xzf "$(SW_ARTIFACTS_TGZ)" -C "$$tmpdir"; \
	  if [ -d "$$tmpdir/tests" ]; then src="$$tmpdir/tests"; \
	  elif [ -d "$$tmpdir/staging/tests" ]; then src="$$tmpdir/staging/tests"; \
	  else echo "No tests/ directory in archive"; rm -rf "$$tmpdir"; exit 2; fi; \
	  cp -f "$$src"/* $(BUILD)/tests/; \
	  if [ -f "$$tmpdir/ram.hex" ]; then cp -f "$$tmpdir/ram.hex" $(BUILD)/ram.hex; fi; \
	  if [ -f "$$tmpdir/manifest.json" ]; then cp -f "$$tmpdir/manifest.json" $(BUILD)/sw-artifacts-manifest.json; fi; \
	  rm -rf "$$tmpdir"
	@echo "Installed $$(ls $(BUILD)/tests/*.hex 2>/dev/null | wc -l) hex images into $(BUILD)/tests"
	@echo "Use: make run-TESTNAME   or   cp build/tests/TESTNAME.hex rom.hex for UVM/commercial sim"

# Run regression: build all tests, run each through sim
regress: $(SIM) $(ASM_HEXES)
	@echo "=== Running regression tests ==="
	@pass=0; fail=0; total=0; \
	for hex in $(ASM_HEXES); do \
	  name=$$(basename $$hex .hex); \
	  total=$$((total + 1)); \
	  cp $$hex rom.hex; \
	  touch ram.hex; \
	  if $(SIM) > $(BUILD)/tests/$$name.log 2>&1; then \
	    echo "  PASS: $$name"; \
	    pass=$$((pass + 1)); \
	  else \
	    echo "  FAIL: $$name (exit=$$?)"; \
	    echo "  --- $$name.log ---"; \
	    tail -120 $(BUILD)/tests/$$name.log || true; \
	    echo "  --- end $$name.log ---"; \
	    fail=$$((fail + 1)); \
	  fi; \
	  rm -f rom.hex ram.hex; \
	done; \
	echo "=== Results: $$pass/$$total passed, $$fail failed ==="; \
	[ $$fail -eq 0 ]

# Run the full assembly regression through the AXI4-Lite bridge path.
regress-axil:
	@$(MAKE) regress USE_AXIL=1

# Run the AXI4-Lite bridge path with deterministic slave stalls enabled.
regress-axil-stall:
	@$(MAKE) regress USE_AXIL=1 AXIL_STALL_RATE=25

# Commercial simulator bring-up. Each tool invocation runs inside LSF.
SIM_TEST ?= test_pass
SIM_RESULTS ?= $(BUILD)/multisim
FORMAL_RESULTS ?= $(BUILD)/formal-questa
LSF_QUEUE ?= regress

sim-questa: $(BUILD)/tests/$(SIM_TEST).hex
	@mkdir -p $(SIM_RESULTS)
	bsub -q $(LSF_QUEUE) -J sisrv_questa -o $(SIM_RESULTS)/questa.out -e $(SIM_RESULTS)/questa.err \
	  "$(ROOT)/verification/sim/run_questa.sh $(SIM_TEST) $(SIM_RESULTS)/questa/$(SIM_TEST)"

sim-vcs: $(BUILD)/tests/$(SIM_TEST).hex
	@mkdir -p $(SIM_RESULTS)
	bsub -q $(LSF_QUEUE) -J sisrv_vcs -o $(SIM_RESULTS)/vcs.out -e $(SIM_RESULTS)/vcs.err \
	  "$(ROOT)/verification/sim/run_vcs.sh $(SIM_TEST) $(SIM_RESULTS)/vcs/$(SIM_TEST)"

sim-xcelium: $(BUILD)/tests/$(SIM_TEST).hex
	@mkdir -p $(SIM_RESULTS)
	bsub -q $(LSF_QUEUE) -J sisrv_xcelium -o $(SIM_RESULTS)/xcelium.out -e $(SIM_RESULTS)/xcelium.err \
	  "$(ROOT)/verification/sim/run_xcelium.sh $(SIM_TEST) $(SIM_RESULTS)/xcelium/$(SIM_TEST)"

regress-questa:
	$(ROOT)/verification/sim/run_regress_lsf.sh questa $(SIM_RESULTS)/questa

regress-vcs:
	$(ROOT)/verification/sim/run_regress_lsf.sh vcs $(SIM_RESULTS)/vcs

regress-xcelium:
	$(ROOT)/verification/sim/run_regress_lsf.sh xcelium $(SIM_RESULTS)/xcelium

regress-all-sims:
	@$(MAKE) regress-questa SIM_RESULTS=$(SIM_RESULTS)
	@$(MAKE) regress-vcs SIM_RESULTS=$(SIM_RESULTS)
	@$(MAKE) regress-xcelium SIM_RESULTS=$(SIM_RESULTS)
	@printf '%-32s | %-8s | %-8s | %-8s\n' TEST QUESTA VCS XCELIUM
	@printf '%-32s-+-%-8s-+-%-8s-+-%-8s\n' '--------------------------------' '--------' '--------' '--------'
	@status=0; for hex in $(ASM_HEXES); do \
	  name=$$(basename $$hex .hex); \
	  row="$$name"; \
	  for tool in questa vcs xcelium; do \
	    log="$(SIM_RESULTS)/$$tool/logs/$$name/sim.log"; \
	    if grep -q '\*\*\* PASS \*\*\*' "$$log" 2>/dev/null; then result=PASS; \
	    elif grep -q '\*\*\* TIMEOUT \*\*\*' "$$log" 2>/dev/null; then result=TIMEOUT; status=1; \
	    else result=FAIL; status=1; fi; \
	    row="$$row|$$result"; \
	  done; \
	  printf '%-32s | %-8s | %-8s | %-8s\n' $$(echo "$$row" | tr '|' ' '); \
	done; exit $$status

# Run a single test
run-%: $(SIM) $(BUILD)/tests/%.hex
	@touch ram.hex
	@cp $(BUILD)/tests/$*.hex rom.hex
	@$(SIM) && rm -f rom.hex ram.hex || (rm -f rom.hex ram.hex; exit 1)

PIPELINE_DEBUG_TOP := sisPipelineDebugTb
PIPELINE_DEBUG_SIM := $(BUILD)/sim_$(PIPELINE_DEBUG_TOP)
PIPELINE_DEBUG_OBJ := obj_dir_pipeline_debug

$(PIPELINE_DEBUG_SIM): $(RTL_SRCS) $(TB_SRCS) $(PIPELINE_DEBUG_CPP_SRCS)
	@mkdir -p $(BUILD)
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-SELRANGE -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET --cc --exe --build \
	  -O3 \
	  --Mdir $(PIPELINE_DEBUG_OBJ) \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph -Irtl/debug -Itb/models \
	  --top-module $(PIPELINE_DEBUG_TOP) \
	  -GROM_INIT_FILE='"rom.hex"' \
	  $(RTL_SRCS) $(TB_SRCS) $(PIPELINE_DEBUG_CPP_SRCS) \
	  -o sim_$(PIPELINE_DEBUG_TOP)
	@cp $(PIPELINE_DEBUG_OBJ)/sim_$(PIPELINE_DEBUG_TOP) $(PIPELINE_DEBUG_SIM)

pipeline-debug: $(PIPELINE_DEBUG_SIM) $(BUILD)/tests/test_pipeline_debug_step.hex
	@touch ram.hex
	@cp $(BUILD)/tests/test_pipeline_debug_step.hex rom.hex
	@$(PIPELINE_DEBUG_SIM) && rm -f rom.hex ram.hex || (rm -f rom.hex ram.hex; exit 1)

pipeline-throughput: $(SIM) $(BUILD)/tests/test_pipeline_throughput.hex
	@touch ram.hex
	@cp $(BUILD)/tests/test_pipeline_throughput.hex rom.hex
	@$(SIM) && rm -f rom.hex ram.hex || (rm -f rom.hex ram.hex; exit 1)

# M9 fetch-buffer throughput guard (corebus only). Trips if the buffer regresses
# back to per-halfword re-fetch on dense compressed code.
fetch-throughput: $(SIM) $(BUILD)/tests/test_fetch_buffer_throughput.hex
	@touch ram.hex
	@cp $(BUILD)/tests/test_fetch_buffer_throughput.hex rom.hex
	@$(SIM) && rm -f rom.hex ram.hex || (rm -f rom.hex ram.hex; exit 1)

BENCH_ISAS ?= rv32imc_zicsr rv32im_zicsr
BENCH_TIMEOUT ?= 60000000

benchmark-coremark: $(SIM)
	python3 scripts/run_benchmarks.py --benchmark coremark --sim $(SIM) --rv-prefix $(RV_PREFIX) --isas "$(BENCH_ISAS)" --timeout-cycles $(BENCH_TIMEOUT)

benchmark-dhrystone: $(SIM)
	python3 scripts/run_benchmarks.py --benchmark dhrystone --sim $(SIM) --rv-prefix $(RV_PREFIX) --isas "$(BENCH_ISAS)" --timeout-cycles $(BENCH_TIMEOUT)

benchmark: $(SIM)
	python3 scripts/run_benchmarks.py --benchmark all --sim $(SIM) --rv-prefix $(RV_PREFIX) --isas "$(BENCH_ISAS)" --timeout-cycles $(BENCH_TIMEOUT)

benchmark-smoke: $(SIM)
	python3 scripts/run_benchmarks.py --benchmark all --sim $(SIM) --rv-prefix $(RV_PREFIX) --isas "rv32imc_zicsr" --timeout-cycles 1000000 --smoke

clean:
	rm -rf $(BUILD) obj_dir obj_dir_pipeline_debug rom.hex ram.hex

# cocotb tests (requires cocotb 2.x + verilator 5.050+)
cocotb:
	@echo "=== Running cocotb ALU tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.alu SIM=verilator
	@echo "=== Running cocotb RegFile tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.regfile SIM=verilator
	@echo "=== Running cocotb Decode tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.decode SIM=verilator
	@echo "=== Running cocotb Decompress tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.decompress SIM=verilator
	@echo "=== Running cocotb CSR tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.csr SIM=verilator
	@echo "=== Running cocotb AXI-Lite bridge tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.axil SIM=verilator
	@echo "=== Running cocotb PMP tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.pmp SIM=verilator
	@echo "=== cocotb tests PASSED ==="

# Informational unit coverage (Verilator --coverage). Floors come later.
coverage-unit:
	@bash scripts/ci/run_coverage_unit.sh

cosim-lockstep-imac-upmp-smoke:
	$(MAKE) cosim-lockstep COSIM_PROFILE=rv32imac-u-pmp COSIM_SEEDS=$(or $(COSIM_SMOKE_SEEDS),64)

# M3 stretch: 1000-seed AXI-Lite random stall stress (nightly / optional)
AXIL_STALL_SEEDS ?= 1000
AXIL_STALL_TXNS ?= 100
cocotb-axil-stall-nightly:
	@echo "=== AXI-Lite random stall stress ($(AXIL_STALL_SEEDS) seeds × $(AXIL_STALL_TXNS) txns) ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && \
	  AXIL_STALL_SEEDS=$(AXIL_STALL_SEEDS) AXIL_STALL_TXNS=$(AXIL_STALL_TXNS) \
	  $(MAKE) -f Makefile.axil SIM=verilator
	@echo "=== AXI-Lite stall nightly PASSED ==="

# Formal verification (requires SymbiYosys + yosys + z3)
formal:
	@echo "=== Running formal proofs ==="
	@cd formal && sby -f regfile_x0.sby
	@cd formal && yosys -s alu_prove.ys
	@cd formal && sby -f decode_legal.sby
	@echo "=== Formal proofs PASSED ==="

# Optional AXI-Lite bridge formal safety check. This is intentionally kept
# out of required CI because smtbmc runtime is solver/version sensitive.
formal-axil:
	@echo "=== Running optional AXI-Lite formal check ==="
	@cd formal && sby -f axil_master.sby
	@echo "=== AXI-Lite formal check PASSED ==="

formal-questa:
	@verification/formal/questa/run_lsf.sh $(FORMAL_RESULTS) autocheck
	@verification/formal/questa/run_lsf.sh $(FORMAL_RESULTS) propcheck

# Yosys synthesis (requires yosys)
synth:
	@echo "=== Running Yosys synthesis ==="
	@mkdir -p $(BUILD)
	yosys -s scripts/yosys_synth.tcl
	@echo "=== Synthesis complete ==="

sta: synth
	@echo "=== STA reference (OpenSTA when LIBERTY_FILE set) ==="
	@if command -v sta >/dev/null 2>&1 && [ -n "$$LIBERTY_FILE" ]; then \
	  LIBERTY_FILE=$$LIBERTY_FILE NETLIST_FILE=$(BUILD)/sisPlatformTop_syn.v \
	    sta -no_splash scripts/sta_opensta.tcl; \
	else \
	  echo "OpenSTA/Liberty not configured; SDC at scripts/constraints.sdc"; \
	  echo "See docs/PPA_DATASHEET.md"; \
	fi

SKY130_LIB ?= third_party/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib

sta-sky130:
	@echo "=== Sky130 HD STA (OpenSTA) ==="
	@bash scripts/fetch_sky130_lib.sh
	@mkdir -p $(BUILD)
	@sed "s|@LIBERTY_FILE@|$(SKY130_LIB)|g" scripts/yosys_synth_sky130.tcl > $(BUILD)/yosys_synth_sky130.ys
	@yosys -s $(BUILD)/yosys_synth_sky130.ys
	@command -v sta >/dev/null || (echo "OpenSTA not installed"; exit 1)
	@sed -e "s|@LIBERTY_FILE@|$(SKY130_LIB)|g" \
	     -e "s|@NETLIST_FILE@|$(BUILD)/sisRegFile_sky130.v|g" \
	     -e "s|@REPORT_FILE@|$(BUILD)/sta_sky130_report.txt|g" \
	     scripts/sta_sky130.tcl > $(BUILD)/sta_sky130_run.tcl
	@sta -no_splash $(BUILD)/sta_sky130_run.tcl
	@test -s $(BUILD)/sta_sky130_report.txt
	@cat $(BUILD)/sta_sky130_report.txt

# ---------------------------------------------------------------------------
# Milestone 8 — OpenROAD Sky130 hardening (sisHardenTop)
# Requires: yosys (SV-capable), openroad, magic; klayout optional for DRC/LVS
# ---------------------------------------------------------------------------
SKY130_PDK_DIR ?= third_party/sky130hd
SKY130_HARDEN_LIB ?= $(SKY130_PDK_DIR)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
HARDEN_TOP ?= sisHardenTop
HARDEN_OUT ?= $(BUILD)/openroad
HARDEN_NETLIST ?= $(HARDEN_OUT)/$(HARDEN_TOP)_synth.v
HARDEN_STAT ?= $(HARDEN_OUT)/$(HARDEN_TOP)_synth_stat.txt

fetch-sky130-pdk:
	@bash scripts/fetch_sky130_pdk.sh
	@# Keep the STA liberty cache in sync when the full PDK is present.
	@mkdir -p third_party/sky130
	@if [ -s "$(SKY130_HARDEN_LIB)" ]; then \
	  cp -f "$(SKY130_HARDEN_LIB)" third_party/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib; \
	fi

synth-harden: fetch-sky130-pdk
	@echo "=== Yosys Sky130 synth ($(HARDEN_TOP)) ==="
	@mkdir -p $(HARDEN_OUT)
	@command -v yosys >/dev/null || (echo "yosys not installed"; exit 1)
	@sed -e "s|@LIBERTY_FILE@|$(SKY130_HARDEN_LIB)|g" \
	     -e "s|@OUT_NETLIST@|$(HARDEN_NETLIST)|g" \
	     -e "s|@OUT_STAT@|$(HARDEN_STAT)|g" \
	     scripts/yosys_synth_harden.tcl > $(HARDEN_OUT)/yosys_synth_harden.ys
	@yosys -s $(HARDEN_OUT)/yosys_synth_harden.ys
	@test -s $(HARDEN_NETLIST)
	@test -s $(HARDEN_STAT)
	@echo "Netlist: $(HARDEN_NETLIST)"
	@tail -20 $(HARDEN_STAT)

# Default 0: skip detailed_route in CI (older TritonRoute is multi-hour on this
# slice). Set HARDEN_DROUTE_ITERS=3+ locally for a deeper route attempt.
HARDEN_DROUTE_ITERS ?= 0

openroad-harden: synth-harden
	@echo "=== OpenROAD PnR ($(HARDEN_TOP)) ==="
	@command -v openroad >/dev/null || (echo "openroad not installed — see docs/HARDENING.md"; exit 1)
	@mkdir -p $(HARDEN_OUT)
	@PDK_DIR=$(abspath $(SKY130_PDK_DIR)) \
	 NETLIST=$(abspath $(HARDEN_NETLIST)) \
	 SDC=$(abspath scripts/constraints_sisHardenTop.sdc) \
	 OUT_DIR=$(abspath $(HARDEN_OUT)) \
	 DESIGN_NAME=$(HARDEN_TOP) \
	 LIBERTY_FILE=$(abspath $(SKY130_HARDEN_LIB)) \
	 HARDEN_DROUTE_ITERS=$(HARDEN_DROUTE_ITERS) \
	 openroad -no_init -exit scripts/openroad_flow.tcl
	@test -s $(HARDEN_OUT)/$(HARDEN_TOP).def
	@test -s $(HARDEN_OUT)/$(HARDEN_TOP)_pnr.v
	@echo "PnR report:"; cat $(HARDEN_OUT)/$(HARDEN_TOP)_pnr_report.txt

MAGIC_TECH ?= $(SKY130_PDK_DIR)/magic/sky130gds.tech

openroad-gds: openroad-harden
	@echo "=== Magic GDS stream-out ==="
	@command -v magic >/dev/null || (echo "magic not installed — see docs/HARDENING.md"; exit 1)
	@test -s $(MAGIC_TECH) || (echo "Missing Magic tech $(MAGIC_TECH) — run make fetch-sky130-pdk"; exit 1)
	@PDK_DIR=$(abspath $(SKY130_PDK_DIR)) \
	 OUT_DIR=$(abspath $(HARDEN_OUT)) \
	 DESIGN_NAME=$(HARDEN_TOP) \
	 magic -T $(MAGIC_TECH) -noconsole -dnull scripts/magic_gds.tcl
	@test -s $(HARDEN_OUT)/$(HARDEN_TOP).gds
	@ls -lh $(HARDEN_OUT)/$(HARDEN_TOP).gds

openroad-drc: openroad-gds
	@echo "=== Magic DRC ==="
	@PDK_DIR=$(abspath $(SKY130_PDK_DIR)) \
	 OUT_DIR=$(abspath $(HARDEN_OUT)) \
	 DESIGN_NAME=$(HARDEN_TOP) \
	 magic -T $(MAGIC_TECH) -noconsole -dnull scripts/magic_drc.tcl
	@test -s $(HARDEN_OUT)/$(HARDEN_TOP)_magic_drc.rpt
	@head -20 $(HARDEN_OUT)/$(HARDEN_TOP)_magic_drc.rpt
	@PDK_DIR=$(abspath $(SKY130_PDK_DIR)) \
	 OUT_DIR=$(abspath $(HARDEN_OUT)) \
	 DESIGN_NAME=$(HARDEN_TOP) \
	 bash scripts/run_klayout_drc_lvs.sh

openroad-lvs: openroad-drc
	@echo "=== LVS summary (KLayout when available) ==="
	@if [ -f $(HARDEN_OUT)/$(HARDEN_TOP)_klayout_lvs.lvsdb ]; then \
	  ls -lh $(HARDEN_OUT)/$(HARDEN_TOP)_klayout_lvs.lvsdb; \
	else \
	  echo "KLayout LVS skipped or unavailable; see docs/HARDENING.md deltas"; \
	fi

# Full M8 exit path: synth → PnR → GDS → DRC (+ optional LVS)
harden: openroad-drc
	@echo "=== M8 harden artifacts ==="
	@ls -lh $(HARDEN_OUT)/$(HARDEN_TOP).gds \
	        $(HARDEN_OUT)/$(HARDEN_TOP).def \
	        $(HARDEN_OUT)/$(HARDEN_TOP)_pnr.v \
	        $(HARDEN_OUT)/$(HARDEN_TOP).sdf \
	        $(HARDEN_OUT)/$(HARDEN_TOP).spef \
	        $(HARDEN_OUT)/$(HARDEN_TOP)_pnr_report.txt \
	        $(HARDEN_OUT)/$(HARDEN_TOP)_magic_drc.rpt \
	        $(HARDEN_OUT)/$(HARDEN_TOP)_power.rpt
	@cp -f $(HARDEN_OUT)/$(HARDEN_TOP)_pnr_report.txt $(BUILD)/harden_pnr_report.txt
	@cp -f $(HARDEN_OUT)/$(HARDEN_TOP)_power.rpt $(BUILD)/harden_power.rpt
	@cp -f $(HARDEN_OUT)/$(HARDEN_TOP)_magic_drc.rpt $(BUILD)/harden_drc.rpt
	@echo "M8 harden complete — see docs/HARDENING.md"

COSIM_SEEDS ?= 10000
COSIM_INSNS ?= 12
COSIM_PROFILE ?= rv32im
COSIM_ARGS ?=

COSIM_SIM_BIN = obj_dir/sim_cosim_$(TOP)
COSIM_STAMP   = $(BUILD)/.cosim_sim_built

$(COSIM_STAMP): $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS)
	@mkdir -p $(BUILD)
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-SELRANGE -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET --cc --exe --build \
	  -O3 --trace-fst -DASSERT \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph -Irtl/debug -Itb/models \
	  --top-module $(TOP) \
	  -GROM_INIT_FILE='"rom.hex"' \
	  -GRAM_INIT_FILE='"ram.hex"' \
	  -GUSE_AXIL=0 \
	  -GAXIL_STALL_RATE=0 \
	  -GRESET_VECTOR=32\'h0000_2000 \
	  $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS) \
	  -o sim_cosim_$(TOP)
	@test -x $(COSIM_SIM_BIN)
	@touch $(COSIM_STAMP)

cosim-lockstep: $(COSIM_STAMP)
	COSIM_SIM=$(abspath $(COSIM_SIM_BIN)) python3 verification/cosim/spike_lockstep.py --seeds $(COSIM_SEEDS) --insns $(COSIM_INSNS) --profile $(COSIM_PROFILE) --jobs $(HOST_JOBS) $(COSIM_ARGS)

cosim-lockstep-imac:
	$(MAKE) cosim-lockstep COSIM_PROFILE=rv32imac

cosim-lockstep-imac-upmp:
	$(MAKE) cosim-lockstep COSIM_PROFILE=rv32imac-u-pmp

# ---------------------------------------------------------------------------
# RISCOF architectural compliance (optional; requires external tools)
# ---------------------------------------------------------------------------
RISCOF_DIR        ?= verification/riscof
RISCOF_VENV       ?= .venv-riscof
RISCOF_CONFIG     ?= $(RISCOF_DIR)/config.ini
RISCOF_WORK       ?= $(RISCOF_DIR)/work
ARCH_TEST_REPO    ?= https://github.com/riscv-non-isa/riscv-arch-test.git
ARCH_TEST_TAG     ?= 59075f8f
ARCH_TEST_ROOT    ?= $(RISCOF_DIR)/riscv-arch-test
ARCH_TEST_SUITE   ?= $(ARCH_TEST_ROOT)/riscv-test-suite
ARCH_TEST_ENV     ?= $(ARCH_TEST_ROOT)/riscv-test-suite/env
RISCOF_SMOKE_TEST ?= add-01

$(ARCH_TEST_ROOT):
	@echo "=== Cloning riscv-arch-test ($(ARCH_TEST_TAG)) ==="
	git clone https://github.com/riscv-non-isa/riscv-arch-test.git $(ARCH_TEST_ROOT)
	cd $(ARCH_TEST_ROOT) && git checkout $(ARCH_TEST_TAG)

$(RISCOF_VENV)/bin/activate:
	python3 -m venv $(RISCOF_VENV)
	. $(RISCOF_VENV)/bin/activate && pip install -r $(RISCOF_DIR)/requirements.txt

riscof-check-tools: $(RISCOF_VENV)/bin/activate
	@. $(RISCOF_VENV)/bin/activate && riscof --version
	@command -v spike >/dev/null || (echo "SKIP: spike not found (reference model)"; exit 1)
	@command -v $(RV_PREFIX)gcc >/dev/null || (echo "SKIP: $(RV_PREFIX)gcc not found"; exit 1)
	@test -x $(SIM) || $(MAKE) build/sim_sisPlatformTop USE_AXIL=0
	@echo "RISCOF prerequisites OK"

$(RISCOF_WORK)/smoke.testlist: $(ARCH_TEST_ROOT) $(RISCOF_VENV)/bin/activate
	@mkdir -p $(RISCOF_WORK)
	@. $(RISCOF_VENV)/bin/activate && \
	  riscof testlist --config $(RISCOF_CONFIG) \
	    --suite $(ARCH_TEST_SUITE) --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK)
	@python3 $(RISCOF_DIR)/scripts/filter_testlist.py \
	  $(RISCOF_WORK)/test_list.yaml $(RISCOF_SMOKE_TEST) > $(RISCOF_WORK)/smoke.testlist

riscof-smoke: $(RISCOF_WORK)/smoke.testlist build/sim_sisPlatformTop
	@. $(RISCOF_VENV)/bin/activate && \
	  RISCOF_TOOLCHAIN_PREFIX=$(RV_PREFIX) \
	  riscof run --config $(RISCOF_CONFIG) --no-browser \
	    --suite $(ARCH_TEST_SUITE) --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK) --testfile $(RISCOF_WORK)/smoke.testlist

$(RISCOF_WORK)/act.testlist: $(ARCH_TEST_ROOT) $(RISCOF_VENV)/bin/activate
	@mkdir -p $(RISCOF_WORK)
	@. $(RISCOF_VENV)/bin/activate && \
	  riscof testlist --config $(RISCOF_CONFIG) \
	    --suite $(ARCH_TEST_SUITE) --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK)
	@python3 $(RISCOF_DIR)/scripts/filter_act_testlist.py \
	  $(RISCOF_WORK)/test_list.yaml $(RISCOF_WORK)/act.testlist

riscof-act: $(RISCOF_WORK)/act.testlist build/sim_sisPlatformTop
	@. $(RISCOF_VENV)/bin/activate && \
	  RISCOF_TOOLCHAIN_PREFIX=$(RV_PREFIX) \
	  riscof run --config $(RISCOF_CONFIG) --no-browser \
	    --suite $(ARCH_TEST_SUITE) --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK) --testfile $(RISCOF_WORK)/act.testlist

# Full ACT including PMP/privilege/A (local only — DUT timeouts + 3h+ runtime; not CI)
$(RISCOF_WORK)/act-full.testlist: $(ARCH_TEST_ROOT) $(RISCOF_VENV)/bin/activate
	@mkdir -p $(RISCOF_WORK)
	@. $(RISCOF_VENV)/bin/activate && \
	  riscof testlist --config $(RISCOF_CONFIG) \
	    --suite $(ARCH_TEST_SUITE) --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK)
	@python3 $(RISCOF_DIR)/scripts/filter_act_testlist.py \
	  --full $(RISCOF_WORK)/test_list.yaml $(RISCOF_WORK)/act-full.testlist

riscof-act-full: $(RISCOF_WORK)/act-full.testlist build/sim_sisPlatformTop
	@. $(RISCOF_VENV)/bin/activate && \
	  RISCOF_TOOLCHAIN_PREFIX=$(RV_PREFIX) \
	  riscof run --config $(RISCOF_CONFIG) --no-browser \
	    --suite $(ARCH_TEST_SUITE) --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK) --testfile $(RISCOF_WORK)/act-full.testlist

riscof-rv32i: $(ARCH_TEST_ROOT) build/sim_sisPlatformTop $(RISCOF_VENV)/bin/activate
	@. $(RISCOF_VENV)/bin/activate && \
	  RISCOF_TOOLCHAIN_PREFIX=$(RV_PREFIX) \
	  riscof run --config $(RISCOF_CONFIG) --no-browser \
	    --suite $(ARCH_TEST_SUITE)/rv32i_m/I --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK)/rv32i

riscof-rv32im: $(ARCH_TEST_ROOT) build/sim_sisPlatformTop $(RISCOF_VENV)/bin/activate
	@. $(RISCOF_VENV)/bin/activate && \
	  RISCOF_TOOLCHAIN_PREFIX=$(RV_PREFIX) \
	  riscof run --config $(RISCOF_CONFIG) --no-browser \
	    --suite $(ARCH_TEST_SUITE)/rv32i_m --env $(ARCH_TEST_ENV) \
	    --work-dir $(RISCOF_WORK)/rv32im
