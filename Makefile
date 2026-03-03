# Minimal scaffolding Makefile (extend as implementation progresses)

VERILATOR ?= verilator
TOP ?= sisPlatformTop
BUILD ?= build
SIM ?= $(BUILD)/sim_$(TOP)

RTL_DIRS := rtl rtl/core rtl/bus rtl/periph
TB_DIRS  := tb/verilator tb/models

RTL_SRCS := $(wildcard $(addsuffix /*.sv,$(RTL_DIRS)))
TB_SRCS  := $(wildcard $(addsuffix /*.sv,$(TB_DIRS)))

CPP_SRCS := $(wildcard tb/verilator/*.cpp)

.PHONY: sim lint clean wave regress sw

sim: $(SIM)
	@$(SIM)

$(SIM): $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS)
	@mkdir -p $(BUILD)
	$(VERILATOR) -Wall --cc --exe --build \
	  -O3 --trace-fst \
	  -Irtl -Irtl/core -Irtl/bus -Irtl/periph -Itb/models \
	  --top-module $(TOP) \
	  $(RTL_SRCS) $(TB_SRCS) $(CPP_SRCS) \
	  -o sim_$(TOP)
	@mv obj_dir/sim_$(TOP) $(SIM)

lint:
	$(VERILATOR) -Wall --lint-only -Irtl -Irtl/core -Irtl/bus -Irtl/periph $(RTL_SRCS)

wave:
	@echo "Open waves with: gtkwave build/wave.fst"

regress: sim
	@echo "TODO: run Tier-1 tests list"

sw:
	@echo "TODO: build software tests (riscv toolchain)"
