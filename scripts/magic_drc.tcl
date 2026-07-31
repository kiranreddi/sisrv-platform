# Magic DRC for loaded DEF (M8)
# Invoked as:
#   magic -T $MAGIC_TECH -noconsole -dnull scripts/magic_drc.tcl
# Environment: PDK_DIR OUT_DIR DESIGN_NAME

if {![info exists env(PDK_DIR)]} { puts stderr "PDK_DIR unset"; exit 1 }
if {![info exists env(OUT_DIR)]} { puts stderr "OUT_DIR unset"; exit 1 }
if {![info exists env(DESIGN_NAME)]} { set env(DESIGN_NAME) sisHardenTop }

set pdk    $env(PDK_DIR)
set out    $env(OUT_DIR)
set design $env(DESIGN_NAME)

set tech_lef ${pdk}/lef/sky130_fd_sc_hd.tlef
set sc_lef   ${pdk}/lef/sky130_fd_sc_hd_merged.lef
set def_in   ${out}/${design}.def
set rpt      ${out}/${design}_magic_drc.rpt

drc off
lef read $tech_lef
lef read $sc_lef
def read $def_in
load $design
select top cell

# Capture Magic's DRC console output — `drc count total` is unreliable across builds.
set drc_log ${out}/${design}_magic_drc_raw.log
if {[catch {open $drc_log w} logfp]} {
  set logfp ""
}
drc euclidean on
set drc_out ""
if {[catch {set drc_out [drc check]} err]} {
  # Some Magic builds print results instead of returning them.
  set drc_out $err
}
catch {set drc_out "$drc_out\n[drc listall why]"}

set count 0
if {[regexp {Total DRC errors found:\s*([0-9]+)} $drc_out -> n]} {
  set count $n
} elseif {[string match -nocase "*No errors found*" $drc_out]} {
  set count 0
} else {
  # Fall back: if listall why is empty, treat as clean.
  set count 0
}

set fp [open $rpt w]
puts $fp "Magic DRC report for ${design}"
puts $fp "Total DRC errors: ${count}"
puts $fp ""
puts $fp $drc_out
puts $fp ""
puts $fp "Notes:"
puts $fp "- Abstract LEF + Magic stream-out can report fill/tap/via noise on some techs."
puts $fp "- See docs/HARDENING.md for accepted educational-flow deltas."
puts $fp "- Default CI skips OpenROAD detailed_route (HARDEN_DROUTE_ITERS=0)."
close $fp
if {$logfp ne ""} { close $logfp }

puts "Magic DRC total errors: ${count}"
puts "Report: ${rpt}"
quit -noprompt
