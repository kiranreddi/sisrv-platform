# Yosys synthesis mapped to Sky130 HD standard cells
# Produces build/sisRvCore_sky130.v for OpenSTA

set lib_file $::env(LIBERTY_FILE)

read -define SYNTHESIS
read -sv rtl/core/sisAlu.sv
read -sv rtl/core/sisDecode.sv
read -sv rtl/core/sisRegFile.sv
read -sv rtl/core/sisCsr.sv
read -sv rtl/core/sisDecompress.sv
read -sv rtl/core/sisRvCore.sv

hierarchy -top sisRvCore
proc; opt; flatten; opt -full

synth -top sisRvCore -flatten
dfflibmap -liberty ${lib_file}
abc -liberty ${lib_file}
clean
stat -liberty ${lib_file}

check -assert
write_verilog -noattr -nohex build/sisRvCore_sky130.v
