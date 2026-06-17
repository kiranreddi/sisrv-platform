# Yosys synthesis script for sisrv-platform
# Run: yosys -s scripts/yosys_synth.tcl
#
# sisRvCore is excluded: CSR/PMP use SystemVerilog unpacked arrays that
# Yosys 0.33 cannot parse. Submodules are synthesized individually.

read -define SYNTHESIS
read -sv rtl/core/sisAlu.sv
hierarchy -top sisAlu
proc; opt; check -assert; flatten; opt -full
synth -top sisAlu -flatten
tee -o build/ppa_synth_report.txt stat
write_verilog -noattr build/sisAlu_synth.v

design -reset
read -define SYNTHESIS
read -sv rtl/core/sisDecode.sv
hierarchy -top sisDecode
proc; opt; check -assert; flatten; opt -full
synth -top sisDecode -flatten
tee -a build/ppa_synth_report.txt stat
write_verilog -noattr build/sisDecode_synth.v

design -reset
read -define SYNTHESIS
read -sv rtl/core/sisRegFile.sv
hierarchy -top sisRegFile
proc; opt; check -assert; flatten; opt -full
synth -top sisRegFile -flatten
tee -a build/ppa_synth_report.txt stat
write_verilog -noattr build/sisRegFile_synth.v

design -reset
read -define SYNTHESIS
read -sv rtl/bus/sisAxiLiteM.sv
hierarchy -top sisAxiLiteM
proc; opt; check -assert; flatten; opt -full
synth -top sisAxiLiteM -flatten
tee -a build/ppa_synth_report.txt stat
write_verilog -noattr build/sisAxiLiteM_synth.v
