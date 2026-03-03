# sisrv-platform Makefile

VERILATOR ?= verilator
TOP       ?= sisPlatformTop
BUILD     ?= build
SIM       ?= $(BUILD)/sim_$(TOP)

# RISC-V toolchain
RV_PREFIX ?= riscv64-linux-gnu-
RV_GCC    := $(RV_PREFIX)gcc
RV_OBJCOPY := $(RV_PREFIX)objcopy
RV_OBJDUMP := $(RV_PREFIX)objdump

RV_ARCH   := rv32i_zicsr
RV_ABI    := ilp32
RV_CFLAGS := -march=$(RV_ARCH) -mabi=$(RV_ABI) -nostdlib -nostartfiles -ffreestanding -static -O2 -Wl,--build-id=none

RTL_DIRS := rtl rtl/core rtl/bus rtl/periph
TB_DIRS  := tb/verilator tb/models

RTL_SRCS := $(wildcard $(addsuffix /*.sv,$(RTL_DIRS)))
TB_SRCS  := $(wildcard $(addsuffix /*.sv,$(TB_DIRS)))
CPP_SRCS := $(wildcard tb/verilator/*.cpp)

# Test sources
ASM_TESTS := $(wildcard sw/tests/asm/*.S)
ASM_HEXES := $(patsubst sw/tests/asm/%.S,$(BUILD)/tests/%.hex,$(ASM_TESTS))

.PHONY: sim lint clean wave regress sw all tests cocotb formal

all: sim

# Build Verilator simulation binary
$(SIM): $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS)
	@mkdir -p $(BUILD)
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL --cc --exe --build \
	  -O3 --trace-fst \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph -Itb/models \
	  --top-module $(TOP) \
	  -GROM_INIT_FILE='"rom.hex"' \
	  $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS) \
	  -o sim_$(TOP)
	@mkdir -p $(BUILD)
	@cp obj_dir/sim_$(TOP) $(SIM)

# Run simulation with a specific test hex
sim: $(SIM) $(BUILD)/tests/test_pass.hex
	@cp $(BUILD)/tests/test_pass.hex rom.hex
	@$(SIM) && rm -f rom.hex || (rm -f rom.hex; exit 1)

# Lint all RTL
lint:
	$(VERILATOR) -Wall -Wno-UNUSEDSIGNAL --lint-only \
	  --top-module $(TOP) \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph \
	  $(RTL_SRCS)

wave:
	@echo "Open waves with: gtkwave build/wave.fst"

# Build a single assembly test: .S -> .elf -> .bin -> .hex
$(BUILD)/tests/%.elf: sw/tests/asm/%.S sw/bsp/link.ld
	@mkdir -p $(BUILD)/tests
	$(RV_GCC) $(RV_CFLAGS) -T sw/bsp/link.ld -o $@ $<

$(BUILD)/tests/%.bin: $(BUILD)/tests/%.elf
	$(RV_OBJCOPY) -O binary $< $@

$(BUILD)/tests/%.hex: $(BUILD)/tests/%.bin
	od -An -tx4 -w4 -v $< | sed 's/^ *//' > $@

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
	  if $(SIM) > $(BUILD)/tests/$$name.log 2>&1; then \
	    echo "  PASS: $$name"; \
	    pass=$$((pass + 1)); \
	  else \
	    echo "  FAIL: $$name (exit=$$?)"; \
	    fail=$$((fail + 1)); \
	  fi; \
	  rm -f rom.hex; \
	done; \
	echo "=== Results: $$pass/$$total passed, $$fail failed ==="; \
	[ $$fail -eq 0 ]

# Run a single test
run-%: $(SIM) $(BUILD)/tests/%.hex
	@cp $(BUILD)/tests/$*.hex rom.hex
	@$(SIM) && rm -f rom.hex || (rm -f rom.hex; exit 1)

clean:
	rm -rf $(BUILD) obj_dir rom.hex

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
	@echo "=== cocotb tests PASSED ==="

# Formal verification (requires SymbiYosys + yosys + z3)
formal:
	@echo "=== Running formal proofs ==="
	@cd formal && sby -f regfile_x0.sby
	@cd formal && yosys -s alu_prove.ys
	@cd formal && yosys -s decode_prove.ys
	@echo "=== Formal proofs PASSED ==="
