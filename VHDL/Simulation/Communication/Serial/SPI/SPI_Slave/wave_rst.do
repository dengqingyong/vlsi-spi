onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /spi_slave_rst_tb/clk
add wave -noupdate -color Gold -format Logic -itemcolor Gold /spi_slave_rst_tb/rst
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_clk
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_mosi
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_miso
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_ss
add wave -noupdate -format Logic /spi_slave_rst_tb/fifo_req_data
add wave -noupdate -format Literal /spi_slave_rst_tb/fifo_din
add wave -noupdate -format Logic /spi_slave_rst_tb/fifo_din_valid
add wave -noupdate -format Logic /spi_slave_rst_tb/fifo_empty
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Literal /spi_slave_rst_tb/reg_din
add wave -noupdate -format Logic /spi_slave_rst_tb/reg_din_val
add wave -noupdate -format Logic /spi_slave_rst_tb/reg_ack
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/conf_reg
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/cpha
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/cpol
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /spi_slave_rst_tb/busy
add wave -noupdate -format Logic /spi_slave_rst_tb/interrupt
add wave -noupdate -format Logic /spi_slave_rst_tb/timeout
add wave -noupdate -format Literal /spi_slave_rst_tb/dout
add wave -noupdate -format Logic /spi_slave_rst_tb/dout_valid
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/cur_st
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/spi_sr_out
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/sr_out_data
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/spi_sr_in
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/sr_cnt_out
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/sr_cnt_in
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/fifo_req_sr
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/spi_ss_in
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/spi_miso_i
add wave -noupdate -format Literal /spi_slave_rst_tb/spi_slave_inst/spi_tout_cnt
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/spi_clk_i
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/spi_clk_reg
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/spi_sr_proc/samp_en
add wave -noupdate -format Logic /spi_slave_rst_tb/spi_slave_inst/spi_sr_proc/prop_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3230000 ps} 0}
configure wave -namecolwidth 308
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
WaveRestoreZoom {2781250 ps} {4093750 ps}
