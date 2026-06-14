# Yosys synthesis mapped to Sky130 HD standard cells.
# Produces build/sisRvCore_sky130.v for OpenSTA

read_verilog -sv -DSYNTHESIS rtl/core/sisAlu.sv
read_verilog -sv -DSYNTHESIS rtl/core/sisDecode.sv
read_verilog -sv -DSYNTHESIS rtl/core/sisRegFile.sv
read_verilog -sv -DSYNTHESIS rtl/core/sisCsr.sv
read_verilog -sv -DSYNTHESIS rtl/core/sisDecompress.sv
read_verilog -sv -DSYNTHESIS rtl/core/sisRvCore.sv

hierarchy -top sisRvCore
proc; opt; flatten; opt -full

synth -top sisRvCore -flatten
dfflibmap -liberty @LIBERTY_FILE@
abc -liberty @LIBERTY_FILE@
clean
stat -liberty @LIBERTY_FILE@

check -assert
write_verilog -noattr -nohex build/sisRvCore_sky130.v
