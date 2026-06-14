# OpenSTA timing analysis script for sisRvCore post-synthesis netlist
# Usage: make sta (requires yosys netlist + OpenSTA)

read_liberty -min -max ${LIBERTY_FILE}
read_verilog ${NETLIST_FILE}
read_sdc scripts/constraints.sdc

link_design sisPlatformTop

report_checks -path_delay min_max -format full_clock_expanded
report_tns
report_wns

set fmax_mhz [expr 1000.0 / [get_property [lindex [get_timing_paths -max_paths 1] 0] slack] / 20.0 * 50.0]
puts "Estimated Fmax (extrapolated): ${fmax_mhz} MHz"
