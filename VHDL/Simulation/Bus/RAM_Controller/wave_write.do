onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /ram_controller_tb_2/clk
add wave -noupdate -format Logic /ram_controller_tb_2/rst
add wave -noupdate -format Literal /ram_controller_tb_2/dout
add wave -noupdate -format Logic /ram_controller_tb_2/dout_valid
add wave -noupdate -format Literal /ram_controller_tb_2/dout_addr
add wave -noupdate -format Logic /ram_controller_tb_2/finish
add wave -noupdate -format Logic /ram_controller_tb_2/overflow_int
add wave -noupdate -format Logic /ram_controller_tb_2/mp_done
add wave -noupdate -format Literal /ram_controller_tb_2/type_reg
add wave -noupdate -format Literal /ram_controller_tb_2/addr_reg
add wave -noupdate -format Literal /ram_controller_tb_2/len_reg
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb_2/addr
add wave -noupdate -format Logic /ram_controller_tb_2/addr_valid
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb_2/data_in
add wave -noupdate -format Logic /ram_controller_tb_2/din_valid
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb_2/wr_addr
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb_2/wr_data
add wave -noupdate -format Logic /ram_controller_tb_2/wr_valid
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb_2/int_wr_addr
add wave -noupdate -format Literal -radix unsigned /ram_controller_tb_2/int_wr_data
add wave -noupdate -format Logic /ram_controller_tb_2/int_wr_valid
add wave -noupdate -format Literal /ram_controller_tb_2/ram_controller_inst/base_addr
add wave -noupdate -format Literal /ram_controller_tb_2/ram_controller_inst/cur_st
add wave -noupdate -format Literal /ram_controller_tb_2/ram_controller_inst/burst_size
add wave -noupdate -format Literal /ram_controller_tb_2/ram_controller_inst/count_ext
add wave -noupdate -format Literal /ram_controller_tb_2/ram_controller_inst/count_int
add wave -noupdate -format Logic /ram_controller_tb_2/ram_controller_inst/burst_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1104 ns} 0}
configure wave -namecolwidth 303
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
WaveRestoreZoom {0 ns} {2100 ns}
