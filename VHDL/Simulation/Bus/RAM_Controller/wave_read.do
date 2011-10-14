onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /ram_controller_tb/clk
add wave -noupdate -format Logic /ram_controller_tb/rst
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb/dout
add wave -noupdate -format Logic /ram_controller_tb/dout_valid
add wave -noupdate -format Logic /ram_controller_tb/finish
add wave -noupdate -format Logic /ram_controller_tb/overflow_int
add wave -noupdate -format Logic /ram_controller_tb/mp_done
add wave -noupdate -format Literal /ram_controller_tb/type_reg
add wave -noupdate -format Literal /ram_controller_tb/addr_reg
add wave -noupdate -format Literal /ram_controller_tb/len_reg
add wave -noupdate -format Literal /ram_controller_tb/addr
add wave -noupdate -format Logic /ram_controller_tb/addr_valid
add wave -noupdate -format Literal /ram_controller_tb/data_in
add wave -noupdate -format Logic /ram_controller_tb/din_valid
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb/rd_addr
add wave -noupdate -format Logic /ram_controller_tb/rd_valid
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb/ram_data
add wave -noupdate -format Logic /ram_controller_tb/ram_valid
add wave -noupdate -format Literal /ram_controller_tb/ext_wr_addr
add wave -noupdate -format Literal /ram_controller_tb/ext_wr_data
add wave -noupdate -format Logic /ram_controller_tb/ext_wr_valid
add wave -noupdate -format Literal /ram_controller_tb/int_wr_addr
add wave -noupdate -format Literal /ram_controller_tb/int_wr_data
add wave -noupdate -format Logic /ram_controller_tb/int_wr_valid
add wave -noupdate -format Literal /ram_controller_tb/ram_controller_inst/base_addr
add wave -noupdate -format Literal /ram_controller_tb/ram_controller_inst/cur_st
add wave -noupdate -format Literal /ram_controller_tb/ram_controller_inst/burst_size
add wave -noupdate -format Literal /ram_controller_tb/ram_controller_inst/count_ext
add wave -noupdate -format Literal /ram_controller_tb/ram_controller_inst/count_int
add wave -noupdate -format Literal /ram_controller_tb/ram_controller_inst/count_val
add wave -noupdate -format Logic /ram_controller_tb/ram_controller_inst/burst_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1672 ns} 0}
configure wave -namecolwidth 283
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000000
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {1068 ns} {1944 ns}
