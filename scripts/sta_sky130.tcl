# OpenSTA timing analysis on Sky130-mapped sisRvCore netlist
# Env: LIBERTY_FILE, NETLIST_FILE, REPORT_FILE

read_liberty $env(LIBERTY_FILE)
read_verilog $env(NETLIST_FILE)
read_sdc scripts/constraints_sisRvCore.sdc

link_design sisRvCore
check_setup

set wns [sta::worst_slack max]
set tns [sta::total_negative_slack max]
set fmax_mhz 50.0
if {$wns < 1e29} {
  set fmax_mhz [expr 1000.0 / (20.0 - $wns)]
}

set report_fp [open $env(REPORT_FILE) w]
puts $report_fp "PDK: Sky130 HD (sky130_fd_sc_hd__tt_025C_1v80)"
puts $report_fp "Top: sisRvCore"
puts $report_fp "Clock target: 50 MHz (20 ns)"
puts $report_fp [format "WNS (max): %.3f ns" $wns]
puts $report_fp [format "TNS (max): %.3f ns" $tns]
puts $report_fp [format "Estimated Fmax: %.2f MHz" $fmax_mhz]
close $report_fp

puts "=== Sky130 STA Report ==="
puts [exec cat $env(REPORT_FILE)]
report_checks -path_delay max -fields {slack required arrival}
report_tns
report_wns
