onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /spi_slave_conf_tb/clk
add wave -noupdate -format Logic /spi_slave_conf_tb/rst
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_clk
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_mosi
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_miso
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_ss
add wave -noupdate -format Literal /spi_slave_conf_tb/dout
add wave -noupdate -format Logic /spi_slave_conf_tb/dout_valid
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /spi_slave_conf_tb/fifo_req_data
add wave -noupdate -format Literal /spi_slave_conf_tb/fifo_din
add wave -noupdate -format Logic /spi_slave_conf_tb/fifo_din_valid
add wave -noupdate -format Logic /spi_slave_conf_tb/fifo_empty
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/fifo_req_sr
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /spi_slave_conf_tb/reg_din_val
add wave -noupdate -format Literal /spi_slave_conf_tb/reg_din
add wave -noupdate -format Logic /spi_slave_conf_tb/reg_ack
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/conf_reg
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_slave_inst/cpha
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_slave_inst/cpol
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/cur_st
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/next_st
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/spi_sr_out
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_slave_inst/sr_out_data
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/spi_sr_in
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/sr_cnt_out
add wave -noupdate -format Literal /spi_slave_conf_tb/spi_slave_inst/sr_cnt_in
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_slave_inst/samp_en
add wave -noupdate -format Logic /spi_slave_conf_tb/spi_slave_inst/prop_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2112649 ps} 0}
configure wave -namecolwidth 295
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
WaveRestoreZoom {1708487 ps} {2233487 ps}
