onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock and Reset}
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/clk
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/rst
add wave -noupdate -divider {SPI Interface}
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/spi_clk
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/spi_mosi
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/spi_miso
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/spi_ss
add wave -noupdate -divider {FIFO Interface}
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/fifo_req_data
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/fifo_din
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/fifo_din_valid
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/fifo_empty
add wave -noupdate -divider {Registers Interface}
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/reg_addr
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/reg_din
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/reg_din_val
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/reg_ack
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/reg_err
add wave -noupdate -divider {Output Data}
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/dout
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/dout_valid
add wave -noupdate -divider {Misc. Ports}
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/spi_slave_addr
add wave -noupdate -divider {Internal Registers}
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/cur_st
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/spi_sr_out
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/spi_sr_in
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/sr_cnt_out
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/sr_cnt_in
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/sr_cnt_in_d1
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/fifo_req_sr
add wave -noupdate -format Literal /spi_master_tb/spi_master_inst/int_spi_ss
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/div_reg
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/conf_reg
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/spi_clk_i
add wave -noupdate -format Literal -radix hexadecimal /spi_master_tb/spi_master_inst/clk_cnt
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/spi_clk_en
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/int_rst
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/samp_en
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/prop_en
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/cpol
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/cpha
add wave -noupdate -format Logic /spi_master_tb/spi_master_inst/spi_event
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2052132 ps} 0}
configure wave -namecolwidth 388
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {3465 ns}
