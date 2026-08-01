# PDN + global power connect for older OpenROAD (no global_connect command)
# Used by scripts/openroad_flow.tcl

# Create supply nets
catch {make_net VDD}
catch {make_net VSS}

# Attach standard-cell power pins (Sky130 HD naming)
add_global_connection -net VDD -inst_pattern .* -pin_pattern VPWR -power
add_global_connection -net VDD -inst_pattern .* -pin_pattern VPB
add_global_connection -net VSS -inst_pattern .* -pin_pattern VGND -ground
add_global_connection -net VSS -inst_pattern .* -pin_pattern VNB

set_voltage_domain -name CORE -power VDD -ground VSS

define_pdn_grid -name grid -voltage_domains CORE -pins met5
add_pdn_stripe -grid grid -layer met1 -width 0.48 -pitch 5.44 -offset 0 -followpins
add_pdn_stripe -grid grid -layer met4 -width 1.600 -pitch 27.140 -offset 13.570
add_pdn_stripe -grid grid -layer met5 -width 1.600 -pitch 27.200 -offset 13.600
add_pdn_connect -grid grid -layers {met1 met4}
add_pdn_connect -grid grid -layers {met4 met5}

pdngen
