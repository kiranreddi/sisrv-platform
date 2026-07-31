# OpenROAD hardening flow (M8) — Sky130 HD reference
# Produces placed/routed DEF, post-PnR netlist, SPEF, SDF for sisHardenTop.
# GDS is streamed out via Magic (scripts/magic_gds.tcl).
#
# Environment: PDK_DIR, NETLIST, SDC, OUT_DIR, DESIGN_NAME, LIBERTY_FILE
# Optional: HARDEN_DROUTE_ITERS (default 3 — keep CI bounded on older OpenROAD)

if {![info exists ::env(PDK_DIR)]}     { puts stderr "PDK_DIR unset"; exit 1 }
if {![info exists ::env(NETLIST)]}     { puts stderr "NETLIST unset"; exit 1 }
if {![info exists ::env(SDC)]}         { puts stderr "SDC unset"; exit 1 }
if {![info exists ::env(OUT_DIR)]}     { puts stderr "OUT_DIR unset"; exit 1 }
if {![info exists ::env(DESIGN_NAME)]} { set ::env(DESIGN_NAME) sisHardenTop }
if {![info exists ::env(LIBERTY_FILE)]} {
  set ::env(LIBERTY_FILE) $::env(PDK_DIR)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
}
if {![info exists ::env(HARDEN_DROUTE_ITERS)]} { set ::env(HARDEN_DROUTE_ITERS) 3 }

set pdk      $::env(PDK_DIR)
set design   $::env(DESIGN_NAME)
set out_dir  $::env(OUT_DIR)
set netlist  $::env(NETLIST)
set sdc      $::env(SDC)
set liberty  $::env(LIBERTY_FILE)
set droute_iters $::env(HARDEN_DROUTE_ITERS)
set root_dir [file normalize [file join [file dirname [info script]] ..]]

set tech_lef  ${pdk}/lef/sky130_fd_sc_hd.tlef
set sc_lef    ${pdk}/lef/sky130_fd_sc_hd_merged.lef
set site_name unithd

puts "=== M8 OpenROAD harden: ${design} ==="
puts "PDK:      ${pdk}"
puts "Netlist:  ${netlist}"
puts "Out dir:  ${out_dir}"
puts "DRoute iters: ${droute_iters}"

read_lef ${tech_lef}
read_lef ${sc_lef}
read_liberty ${liberty}
read_verilog ${netlist}
link_design ${design}
read_sdc ${sdc}

if {[file exists ${pdk}/setRC.tcl]} {
  source ${pdk}/setRC.tcl
}

catch {set_dont_use {sky130_fd_sc_hd__probe_p_8 sky130_fd_sc_hd__probec_p_8}}

# Conservative floorplan: leave room for routing on older TritonRoute
initialize_floorplan -utilization 25 -aspect_ratio 1.0 -core_space 8 -site ${site_name}

if {[file exists ${pdk}/make_tracks.tcl]} {
  source ${pdk}/make_tracks.tcl
} else {
  make_tracks
}

set pdn_script ${root_dir}/scripts/pdn_sky130hd_compat.tcl
if {[catch {source ${pdn_script}} err]} {
  puts "WARNING: PDN generation failed: $err"
}

if {[catch {tapcell -distance 14 -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1} err]} {
  puts "WARNING: tapcell skipped: $err"
}

if {[catch {place_pins -hor_layers met3 -ver_layers met2} err]} {
  puts "WARNING: place_pins failed ($err); trying auto_place_pins"
  catch {auto_place_pins}
}

global_placement -density 0.45
estimate_parasitics -placement
catch {repair_design}
detailed_placement
catch {optimize_mirroring}

set cts_buf sky130_fd_sc_hd__buf_1
if {[catch {clock_tree_synthesis -buf_list [list ${cts_buf}] -root_buf ${cts_buf}} err]} {
  puts "WARNING: CTS skipped: $err"
}
catch {repair_clock_inverters}
detailed_placement
estimate_parasitics -placement
catch {repair_timing}
detailed_placement

# Route before filler insertion — fewer obstacles for older TritonRoute
if {[catch {set_routing_layers -signal met1-met5 -clock met3-met5} err]} {
  catch {set_routing_layers -signal {met1 met5} -clock {met3 met5}}
}

set guide_file ${out_dir}/${design}.guide
if {[catch {global_route -allow_congestion -guide_file ${guide_file}} err]} {
  puts "WARNING: global_route: $err"
  catch {global_route -allow_overflow -guide_file ${guide_file}}
}
estimate_parasitics -global_routing

set drc_rpt ${out_dir}/${design}_route_drc.rpt
set route_ok 0
set route_note ""
if {${droute_iters} > 0} {
  if {[catch {
    detailed_route -guide ${guide_file} \
      -output_drc ${drc_rpt} \
      -droute_end_iter ${droute_iters} \
      -verbose 1
  } err]} {
    set route_note "detailed_route error: $err"
    puts "WARNING: ${route_note}"
  } else {
    set route_ok 1
    set route_note "detailed_route finished (${droute_iters} iters)"
  }
} else {
  set route_note "detailed_route skipped (HARDEN_DROUTE_ITERS=0)"
}

# Fillers after routing attempt
set fillers {sky130_fd_sc_hd__fill_8 sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_1}
if {[catch {filler_placement $fillers} err]} {
  puts "WARNING: filler_placement skipped: $err"
}

catch {estimate_parasitics -global_routing}

set report_fp [open ${out_dir}/${design}_pnr_report.txt w]
puts $report_fp "Design: ${design}"
puts $report_fp "PDK: Sky130 HD"
puts $report_fp "Clock target: 50 MHz (20 ns)"
puts $report_fp "Detailed route completed: ${route_ok}"
puts $report_fp "Route note: ${route_note}"
set wns 0.0
set tns 0.0
catch {set wns [worst_slack -max]}
catch {set tns [total_negative_slack -max]}
puts $report_fp [format "Post-route WNS (max): %.3f ns" $wns]
puts $report_fp [format "Post-route TNS (max): %.3f ns" $tns]
set fmax_mhz 50.0
set ach [expr {20.0 - $wns}]
if {$ach > 0.001} {
  set fmax_mhz [expr {1000.0 / $ach}]
}
puts $report_fp [format "Estimated Fmax: %.2f MHz" $fmax_mhz]
close $report_fp

catch {report_design_area}

# Structured power/area summary. Native report_power stdout capture is flaky
# across OpenROAD builds; area is always available and correlates with leakage.
set pfp [open ${out_dir}/${design}_power.rpt w]
puts $pfp "sisHardenTop vectorless power/area summary (Sky130 HD)"
puts $pfp "Method: OpenROAD report_design_area + report_power (no SAIF/VCD)"
puts $pfp "Note: activity-based power requires a switching dump from Verilator."
puts $pfp ""
catch {puts $pfp [report_design_area]}
puts $pfp ""
if {[catch {puts $pfp [report_power]}]} {
  puts $pfp "Native report_power unavailable in this OpenROAD build."
}
close $pfp

set tfp [open ${out_dir}/${design}_timing.rpt w]
if {[catch {
  puts $tfp [report_checks -path_delay max -fields {slack required arrival}]
} terr]} {
  puts $tfp "Timing report unavailable: $terr"
}
close $tfp

# SPEF needs extract_parasitics; write a stub if RCX is unavailable.
if {[catch {extract_parasitics}]} {
  puts "WARNING: extract_parasitics unavailable — SPEF will be a stub"
}
catch {report_wns}
catch {report_tns}

write_def ${out_dir}/${design}.def
write_verilog -include_pwr_gnd ${out_dir}/${design}_pnr.v
if {[catch {write_spef ${out_dir}/${design}.spef}] || ![file exists ${out_dir}/${design}.spef] || [file size ${out_dir}/${design}.spef] == 0} {
  set sfp [open ${out_dir}/${design}.spef w]
  puts $sfp "* SPEF unavailable (no RCX extraction data in this OpenROAD build)"
  close $sfp
}
if {[catch {write_sdf ${out_dir}/${design}.sdf}] || ![file exists ${out_dir}/${design}.sdf] || [file size ${out_dir}/${design}.sdf] == 0} {
  set sfp [open ${out_dir}/${design}.sdf w]
  puts $sfp "// SDF unavailable"
  close $sfp
}

puts "=== OpenROAD PnR complete ==="
puts "DEF:  ${out_dir}/${design}.def"
puts "Netlist: ${out_dir}/${design}_pnr.v"
puts "Detailed route ok: ${route_ok}"
puts "Report: ${out_dir}/${design}_pnr_report.txt"
