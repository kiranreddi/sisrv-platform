set root [file normalize [file join [file dirname [info script]] ../../..]]
set result_dir [file join $root build formal-questa]
file mkdir $result_dir
set rtl [list \
  [file join $root rtl core sisAlu.sv] \
  [file join $root rtl core sisCsr.sv] \
  [file join $root rtl core sisDecode.sv] \
  [file join $root rtl core sisDecompress.sv] \
  [file join $root rtl core sisPmp.sv] \
  [file join $root rtl core sisRegFile.sv] \
  [file join $root rtl core sisRvCore.sv]]
foreach source $rtl { vlog -sv +define+QUESTA $source }
formal compile -top sisRvCore
formal autocheck -level basic
formal report -file [file join $result_dir autocheck.rpt]
quit -f
