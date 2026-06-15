# sisRvCore-only timing constraints (Sky130 STA flow)
# Target: 50 MHz (20 ns period)

create_clock -name clk -period 20.0 [get_ports clk]

set_input_delay  2.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 2.0 -clock clk [all_outputs]

set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports ext_msip]
set_false_path -from [get_ports ext_mtip]
set_false_path -from [get_ports ext_meip]
set_false_path -from [get_ports dbg_halt_req]
set_false_path -from [get_ports dbg_resume_req]
set_false_path -from [get_ports dbg_single_step]
set_false_path -from [get_ports dbg_abs_valid]
set_false_path -from [get_ports dbg_abs_write]
set_false_path -from [get_ports dbg_abs_regaddr]
set_false_path -from [get_ports dbg_abs_wdata]

set_max_fanout 32 [current_design]
set_max_transition 1.0 [current_design]
