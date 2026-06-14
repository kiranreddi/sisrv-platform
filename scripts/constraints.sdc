# sisRvCore timing constraints (Sky130 / generic ASIC reference flow)
# Target: 50 MHz (20 ns period) — conservative for multi-cycle FSM

create_clock -name clk -period 20.0 [get_ports clk]

set_input_delay  2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]

set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports jtag_*]
set_false_path -from [get_ports plic_irq*]
set_false_path -from [get_ports gpio_in*]

set_max_fanout 32 [current_design]
set_max_transition 1.0 [current_design]
