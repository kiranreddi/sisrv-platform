# OpenSTA timing analysis on Sky130-mapped sisRvCore netlist
# Paths substituted by Makefile: @LIBERTY_FILE@ @NETLIST_FILE@ @REPORT_FILE@

read_liberty @LIBERTY_FILE@
read_verilog @NETLIST_FILE@

set linked 0
foreach top {sisRvCore {\sisRvCore}} {
  if {!$linked} {
    if {![catch {link_design $top} err]} {
      if {![catch {current_design} _]} {
        set linked 1
      }
    }
  }
}
if {!$linked} {
  puts stderr "link_design failed for sisRvCore"
  exit 1
}

read_sdc scripts/constraints_sisRvCore.sdc
check_setup

set wns [sta::worst_slack max]
set tns [sta::total_negative_slack max]
set fmax_mhz 50.0
if {$wns < 1e29} {
  set fmax_mhz [expr 1000.0 / (20.0 - $wns)]
}

set report_fp [open @REPORT_FILE@ w]
puts $report_fp "PDK: Sky130 HD (sky130_fd_sc_hd__tt_025C_1v80)"
puts $report_fp "Top: sisRvCore"
puts $report_fp "Clock target: 50 MHz (20 ns)"
puts $report_fp [format "WNS (max): %.3f ns" $wns]
puts $report_fp [format "TNS (max): %.3f ns" $tns]
puts $report_fp [format "Estimated Fmax: %.2f MHz" $fmax_mhz]
close $report_fp

puts "=== Sky130 STA Report ==="
puts [exec cat @REPORT_FILE@]
report_checks -path_delay max -fields {slack required arrival}
report_tns
report_wns
