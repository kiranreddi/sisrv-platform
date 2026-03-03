# Yosys synthesis script for sisrv-platform
# Run: yosys -s scripts/yosys_synth.tcl
# Purpose: Validate synthesizability, check for latches, generate area report
#
# Constraints:
#   - Target clock period: 20ns (50 MHz, conservative for educational design)
#   - IO assumptions: single clock domain, async active-low reset

# Read RTL sources
read -define SYNTHESIS
read -sv rtl/core/sisAlu.sv
read -sv rtl/core/sisDecode.sv
read -sv rtl/core/sisRegFile.sv
read -sv rtl/core/sisCsr.sv
read -sv rtl/core/sisRvCore.sv
read -sv rtl/bus/sisMemFabric.sv
read -sv rtl/bus/sisAxiLiteM.sv
read -sv rtl/periph/sisTimer.sv
read -sv rtl/periph/sisTohost.sv

# Elaborate and synthesize core + bridge (not memories, not platform top)
# Memories will use blackbox macros in real ASIC flow
hierarchy -top sisRvCore
proc
opt

# Check for issues
check -assert

# Flatten
flatten
opt -full

# Map to generic gate library (abstract)
synth -top sisRvCore -flatten

# Report area and cell counts
stat

# Write netlist
write_verilog -noattr build/sisRvCore_synth.v

# Also synthesize the AXI bridge
design -reset
read -define SYNTHESIS
read -sv rtl/bus/sisAxiLiteM.sv
hierarchy -top sisAxiLiteM
proc; opt; flatten; opt -full
synth -top sisAxiLiteM -flatten
stat
write_verilog -noattr build/sisAxiLiteM_synth.v
