# sisHardenTop timing constraints — Sky130 HD reference (M8)
# Target: 50 MHz (20 ns)

create_clock -name clk -period 20.0 [get_ports clk]

# Older OpenSTA: all_inputs includes clk; false-path clk self-delay via separate call.
set_input_delay  2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]
set_false_path -from [get_ports rst_n]
# Ignore the clk port's own input-delay relative to itself.
set_false_path -from [get_ports clk]

set_max_fanout 32 [current_design]
set_max_transition 1.0 [current_design]
