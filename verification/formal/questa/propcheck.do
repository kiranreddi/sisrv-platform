set root [file normalize [file join [file dirname [info script]] ../../..]]
set result_dir [file join $root build formal-questa]
file mkdir $result_dir
set sources [list \
  [file join $root rtl core sisAlu.sv] \
  [file join $root rtl core sisRegFile.sv] \
  [file join $root rtl core sisDecode.sv] \
  [file join $root rtl bus sisAxiLiteM.sv] \
  [file join $root formal alu_add.sv] \
  [file join $root formal regfile_x0.sv] \
  [file join $root formal decode_legal.sv] \
  [file join $root formal axil_master.sv]]
foreach source $sources { vlog -sv +define+QUESTA $source }
foreach top {alu_add_wrapper regfile_x0_wrapper decode_legal_wrapper axil_master_formal} {
  formal compile -top $top
  formal verify
  formal report -file [file join $result_dir ${top}.rpt]
}
quit -f
