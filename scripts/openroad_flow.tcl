# OpenROAD hardening flow (M8) — Sky130 reference
# Produces placed/routed DEF and GDS for core + AXI bridge (memories blackboxed).
#
# Prerequisites: OpenROAD, Sky130 PDK, Yosys synthesis netlist
# Usage: make openroad-harden

set top sisPlatformTop
set pdk sky130A

# 1. Read LEF/DEF technology files from PDK
# 2. Read synthesized Verilog (core + bridge, RAM/ROM blackboxed)
# 3. Floorplan, PnR, CTS, routing
# 4. Write GDS + SPEF + SDF
# 5. Run DRC/LVS (document deltas)

puts "OpenROAD hardening: configure SKY130_PDK_ROOT and run from CI artifact stage"
puts "See docs/PPA_DATASHEET.md for published metrics after flow completion"
