# set up input/output constraints on the 100 MHz clock generated by the PLL

# set_false_path -from clock_50 -to {SRAM_unit|Clock_100_PLL_inst|altpll_component|auto_generated|pll1|clk[0]}
# set_false_path -from {SRAM_unit|Clock_100_PLL_inst|altpll_component|auto_generated|pll1|clk[0]} -to clock_50

set_output_delay -clock {SRAM_unit|Clock_100_PLL_inst|altpll_component|auto_generated|pll1|clk[0]} -max 3 {SRAM_UB_N_O} -add_delay
set_output_delay -clock {SRAM_unit|Clock_100_PLL_inst|altpll_component|auto_generated|pll1|clk[0]} -max 3 {SRAM_LB_N_O} -add_delay

set_output_delay -clock {SRAM_unit|Clock_100_PLL_inst|altpll_component|auto_generated|pll1|clk[0]} -min 2 {SRAM_UB_N_O} -add_delay
set_output_delay -clock {SRAM_unit|Clock_100_PLL_inst|altpll_component|auto_generated|pll1|clk[0]} -min 2 {SRAM_LB_N_O} -add_delay

set_false_path -from [get_ports {SWITCH_I[17]}]
set_false_path -to {SRAM_UB_N_O}
set_false_path -from {SRAM_UB_N_O}
set_false_path -to {SRAM_LB_N_O}
set_false_path -from {SRAM_LB_N_O}



