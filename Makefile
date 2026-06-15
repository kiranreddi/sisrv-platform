# sisrv-platform Makefile

VERILATOR ?= verilator
TOP       ?= sisPlatformTop
BUILD     ?= build
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
ASM_TESTS := $(wildcard sw/tests/asm/*.S)
ASM_HEXES := $(patsubst sw/tests/asm/%.S,$(BUILD)/tests/%.hex,$(ASM_TESTS))

.PHONY: sim lint clean wave regress regress-axil regress-axil-stall pipeline-debug sw all tests cocotb formal formal-axil synth sta sta-sky130 cosim-lockstep \
        riscof-check-tools riscof-smoke riscof-act riscof-rv32i riscof-rv32im


all: sim

# Build Verilator simulation binary
$(SIM): $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS)
	@mkdir -p $(BUILD)
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-SELRANGE -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET --cc --exe --build \
	  -O3 --trace-fst \
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
$(BUILD)/tests/%.elf: sw/tests/asm/%.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) $(RV_CFLAGS) -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/test_compressed.elf: sw/tests/asm/test_compressed.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) -march=rv32imc_zicsr -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -O2 -Wl,--build-id=none -T sw/bsp/link.ld -o $@ $<

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

clean:
	rm -rf $(BUILD) obj_dir obj_dir_pipeline_debug rom.hex ram.hex

# cocotb tests (requires cocotb + verilator 5.038+)
cocotb:
	@echo "=== Running cocotb ALU tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.alu SIM=verilator
	@echo "=== Running cocotb RegFile tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.regfile SIM=verilator
	@echo "=== Running cocotb Decode tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.decode SIM=verilator
	@echo "=== Running cocotb CSR tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.csr SIM=verilator
	@echo "=== Running cocotb AXI-Lite bridge tests ==="
	@cd tb/cocotb && rm -rf sim_build results.xml && $(MAKE) -f Makefile.axil SIM=verilator
	@echo "=== cocotb tests PASSED ==="

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
	     -e "s|@NETLIST_FILE@|$(BUILD)/sisRvCore_sky130.v|g" \
	     -e "s|@REPORT_FILE@|$(BUILD)/sta_sky130_report.txt|g" \
	     scripts/sta_sky130.tcl > $(BUILD)/sta_sky130_run.tcl
	@sta -no_splash $(BUILD)/sta_sky130_run.tcl
	@test -s $(BUILD)/sta_sky130_report.txt
	@cat $(BUILD)/sta_sky130_report.txt

COSIM_SEEDS ?= 10000

COSIM_SIM_BIN = obj_dir/sim_cosim_$(TOP)
COSIM_STAMP   = $(BUILD)/.cosim_sim_built

$(COSIM_STAMP): $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS)
	@mkdir -p $(BUILD)
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-SELRANGE -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET --cc --exe --build \
	  -O3 --trace-fst \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph -Irtl/debug -Itb/models \
	  --top-module $(TOP) \
	  -GROM_INIT_FILE='"rom.hex"' \
	  -GRAM_INIT_FILE='"ram.hex"' \
	  -GUSE_AXIL=0 \
	  -GAXIL_STALL_RATE=0 \
	  -GRESET_VECTOR=32\'h8000_0000 \
	  $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS) \
	  -o sim_cosim_$(TOP)
	@test -x $(COSIM_SIM_BIN)
	@touch $(COSIM_STAMP)

cosim-lockstep: $(COSIM_STAMP)
	COSIM_SIM=$(abspath $(COSIM_SIM_BIN)) python3 verification/cosim/spike_lockstep.py --seeds $(COSIM_SEEDS) --jobs $$(nproc)

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
