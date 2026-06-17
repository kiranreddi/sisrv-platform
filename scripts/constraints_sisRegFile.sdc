# sisRegFile timing constraints (Sky130 STA smoke flow)
# Target: 50 MHz (20 ns period)

create_clock -name clk -period 20.0 [get_ports clk]

set_input_delay  2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]

set_max_fanout 32 [current_design]
set_max_transition 1.0 [current_design]
