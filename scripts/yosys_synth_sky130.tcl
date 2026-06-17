# Yosys synthesis mapped to Sky130 HD standard cells.
# Produces build/sisRegFile_sky130.v for OpenSTA.
#
# Full sisRvCore is excluded: CSR/PMP use SystemVerilog unpacked arrays that
# Yosys 0.33 cannot parse. Submodule STA smoke uses sisRegFile as top.
# Liberty path substituted by Makefile via @LIBERTY_FILE@

read -define SYNTHESIS
read -sv rtl/core/sisRegFile.sv

hierarchy -top sisRegFile
proc; opt; flatten; opt -full

synth -top sisRegFile -flatten
dfflibmap -liberty @LIBERTY_FILE@
abc -liberty @LIBERTY_FILE@
clean
stat -liberty @LIBERTY_FILE@

check
hierarchy -top sisRegFile
select -module sisRegFile
write_verilog -noattr -noexpr -nohex -selected build/sisRegFile_sky130.v
