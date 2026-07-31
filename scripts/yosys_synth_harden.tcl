# Yosys Sky130 synthesis for sisHardenTop (M8)
# Paths substituted by Makefile: @LIBERTY_FILE@ @OUT_NETLIST@ @OUT_STAT@

read_verilog -sv -D SYNTHESIS \
  rtl/core/sisAlu.sv \
  rtl/core/sisDecode.sv \
  rtl/core/sisRegFile.sv \
  rtl/core/sisDecompress.sv \
  rtl/bus/sisAxiLiteM.sv \
  rtl/asic/sisHardenTop.sv

hierarchy -check -top sisHardenTop
proc; opt; flatten; opt -full

# Map constants to Sky130 tie cell before ABC
synth -top sisHardenTop -flatten
dfflibmap -liberty @LIBERTY_FILE@

# Exclude probe / multi-rail lpflow cells that confuse open educational flows
abc -liberty @LIBERTY_FILE@ -D 20000 \
  -dont_use sky130_fd_sc_hd__probe_p_8 \
  -dont_use sky130_fd_sc_hd__probec_p_8 \
  -dont_use sky130_fd_sc_hd__lpflow_*

hilomap -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO
setundef -zero
opt_clean -purge

tee -o @OUT_STAT@ stat -liberty @LIBERTY_FILE@
write_verilog -noattr -noexpr -nohex -nodec @OUT_NETLIST@
