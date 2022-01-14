# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 20 {Milestone2 signals}
add wave -noupdate /TB/UUT/Milestone2_unit/m2_state
add wave -unsigned /TB/UUT/Milestone2_unit/step_counter
add wave -dec /TB/UUT/Milestone2_unit/SRAM_write_addr

add wave -divider -height 10 {SRAM signals}
#add wave -hex /TB/UUT/Milestone2_unit/write_data_S_a
#add wave -dec /TB/UUT/Milestone2_unit/address_S_a
#add wave -dec /TB/UUT/Milestone2_unit/write_enable_S_a
add wave -hex UUT/SRAM_write_data
add wave -dec UUT/SRAM_address
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

#add wave -divider -height 20 {S port address signals}
#add wave -dec /TB/UUT/Milestone2_unit/address_S_a
#add wave -hex /TB/UUT/Milestone2_unit/read_data_S_a
#add wave -hex /TB/UUT/Milestone2_unit/write_data_S_a
#add wave -bin /TB/UUT/Milestone2_unit/write_enable_S_a
#add wave -dec /TB/UUT/Milestone2_unit/S_addr_ref_a
#add wave -unsigned /TB/UUT/Milestone2_unit/address_S_b
#add wave -hex /TB/UUT/Milestone2_unit/S0_result
#add wave -hex /TB/UUT/Milestone2_unit/S1_result
#add wave -hex /TB/UUT/Milestone2_unit/S0_finish
#add wave -hex /TB/UUT/Milestone2_unit/S1_finish
#add wave -hex /TB/UUT/Milestone2_unit/S1_finish_buf
#add wave -hex /TB/UUT/Milestone2_unit/read_data_S_b
#add wave -hex /TB/UUT/Milestone2_unit/write_data_S_b
#add wave -bin /TB/UUT/Milestone2_unit/write_enable_S_b
#add wave -hex /TB/UUT/Milestone2_unit/S_write_buf
#add wave -hex UUT/SRAM_write_data
#add wave -dec UUT/SRAM_address
#add wave -dec /TB/UUT/Milestone2_unit/S_addr_ref_b



#add wave -divider -height 20 {port C address signals}
#add wave -dec /TB/UUT/Milestone2_unit/address_C_a
#add wave -hex /TB/UUT/Milestone2_unit/read_data_C_a
#add wave -bin /TB/UUT/Milestone2_unit/write_enable_C_a
#add wave -dec /TB/UUT/Milestone2_unit/C_addr_ref_a

#add wave -divider -height 20 {port C_b address signals}
#add wave -dec /TB/UUT/Milestone2_unit/address_C_b
#add wave -hex /TB/UUT/Milestone2_unit/read_data_C_b
#add wave -bin /TB/UUT/Milestone2_unit/write_enable_C_b
#add wave -dec /TB/UUT/Milestone2_unit/C_addr_ref_b


#add wave -divider -height 20 {T address signals}
#add wave -unsigned /TB/UUT/Milestone2_unit/address_T_a
#add wave -dec /TB/UUT/Milestone2_unit/write_enable_T_a
#add wave -hex /TB/UUT/Milestone2_unit/read_data_T_a
#add wave -hex /TB/UUT/Milestone2_unit/write_data_T_a
#add wave -hex /TB/UUT/Milestone2_unit/op5
#add wave -hex /TB/UUT/Milestone2_unit/op6
#add wave -hex /TB/UUT/Milestone2_unit/op7
#add wave -hex /TB/UUT/Milestone2_unit/op8
#add wave -hex /TB/UUT/Milestone2_unit/m1
#add wave -hex /TB/UUT/Milestone2_unit/m2
#add wave -hex /TB/UUT/Milestone2_unit/T0_result
#add wave -unsigned /TB/UUT/Milestone2_unit/T_addr_ref_a
#add wave -unsigned /TB/UUT/Milestone2_unit/address_T_b
#add wave -bin /TB/UUT/Milestone2_unit/write_enable_T_b
#add wave -hex /TB/UUT/Milestone2_unit/read_data_T_b
#add wave -hex /TB/UUT/Milestone2_unit/write_data_T_b
#add wave -hex /TB/UUT/Milestone2_unit/m3
#add wave -hex /TB/UUT/Milestone2_unit/m4
#add wave -hex /TB/UUT/Milestone2_unit/T1_result
#add wave -unsigned /TB/UUT/Milestone2_unit/T_addr_ref_b


#add wave -divider -height 20 {C address signals}
#add wave -dec /TB/UUT/Milestone2_unit/address_C_a
#add wave -dec /TB/UUT/Milestone2_unit/write_enable_C_a
#add wave -dec /TB/UUT/Milestone2_unit/C_addr_ref_a
#add wave -dec /TB/UUT/Milestone2_unit/address_C_b
#add wave -dec /TB/UUT/Milestone2_unit/write_enable_C_b
#add wave -dec /TB/UUT/Milestone2_unit/C_addr_ref_b


#add wave -divider -height 20 {T_b address signals}
#add wave -dec /TB/UUT/Milestone2_unit/address_T_b
#add wave -dec /TB/UUT/Milestone2_unit/write_enable_T_b
#add wave -dec /TB/UUT/Milestone2_unit/T_addr_ref_b
#add wave -hex /TB/UUT/Milestone2_unit/write_data_S_a
#add wave -bin /TB/UUT/Milestone2_unit/write_enable_S_a






