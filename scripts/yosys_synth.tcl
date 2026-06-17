# Yosys synthesis script for sisrv-platform
# Run: yosys -s scripts/yosys_synth.tcl
# Purpose: Validate synthesizability, check for latches, generate area report
#
# sisRvCore is excluded: CSR/PMP use SystemVerilog unpacked arrays that
# Yosys 0.33 cannot parse. Submodules are synthesized individually instead.

proc synth_module {top} {
  hierarchy -top $top
  proc
  opt
  check -assert
  flatten
  opt -full
  synth -top $top -flatten
  stat
  write_verilog -noattr build/${top}_synth.v
}

read -define SYNTHESIS
read -sv rtl/core/sisAlu.sv
read -sv rtl/core/sisDecode.sv
read -sv rtl/core/sisRegFile.sv
read -sv rtl/core/sisDecompress.sv

tee -o build/ppa_synth_report.txt echo "=== sisAlu ==="
synth_module sisAlu

design -reset
read -define SYNTHESIS
read -sv rtl/core/sisDecode.sv
tee -a build/ppa_synth_report.txt echo "=== sisDecode ==="
synth_module sisDecode

design -reset
read -define SYNTHESIS
read -sv rtl/core/sisRegFile.sv
tee -a build/ppa_synth_report.txt echo "=== sisRegFile ==="
synth_module sisRegFile

design -reset
read -define SYNTHESIS
read -sv rtl/bus/sisAxiLiteM.sv
tee -a build/ppa_synth_report.txt echo "=== sisAxiLiteM ==="
synth_module sisAxiLiteM
