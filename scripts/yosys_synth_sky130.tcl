# Yosys synthesis mapped to Sky130 HD standard cells.
# Produces build/sisRvCore_sky130.v for OpenSTA
# Liberty path substituted by Makefile via @LIBERTY_FILE@

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
dfflibmap -liberty @LIBERTY_FILE@
abc -liberty @LIBERTY_FILE@
clean
stat -liberty @LIBERTY_FILE@

check
select -module sisRvCore
write_verilog -noattr -noexpr -nohex -selected build/sisRvCore_sky130.v
