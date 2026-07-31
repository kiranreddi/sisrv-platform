# Magic GDS stream-out for sisHardenTop (M8)
# Invoked as:
#   magic -T $MAGIC_TECH -noconsole -dnull scripts/magic_gds.tcl
# Environment: PDK_DIR OUT_DIR DESIGN_NAME

if {![info exists env(PDK_DIR)]} { puts stderr "PDK_DIR unset"; exit 1 }
if {![info exists env(OUT_DIR)]} { puts stderr "OUT_DIR unset"; exit 1 }
if {![info exists env(DESIGN_NAME)]} { set env(DESIGN_NAME) sisHardenTop }

set pdk    $env(PDK_DIR)
set out    $env(OUT_DIR)
set design $env(DESIGN_NAME)

set tech_lef ${pdk}/lef/sky130_fd_sc_hd.tlef
set sc_lef   ${pdk}/lef/sky130_fd_sc_hd_merged.lef
set cell_gds ${pdk}/gds/sky130_fd_sc_hd.gds
set def_in   ${out}/${design}.def
set gds_out  ${out}/${design}.gds

drc off
lef read $tech_lef
lef read $sc_lef

if {![file exists $def_in]} {
  puts stderr "Missing DEF: $def_in"
  exit 1
}
def read $def_in

gds readonly true
gds rescale false
if {[file exists $cell_gds]} {
  gds merge true
  gds read $cell_gds
}

load $design
select top cell
expand
cif *hier write disable
cif *array write disable
gds write $gds_out

if {![file exists $gds_out] || [file size $gds_out] < 100} {
  puts stderr "GDS write failed or produced empty file: $gds_out"
  exit 1
}

puts "Wrote GDS: $gds_out ([file size $gds_out] bytes)"
quit -noprompt
