onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /spi_slave_tb_2/clk
add wave -noupdate -format Logic /spi_slave_tb_2/rst
add wave -noupdate -format Logic /spi_slave_tb_2/spi_clk
add wave -noupdate -format Logic /spi_slave_tb_2/spi_mosi
add wave -noupdate -format Logic /spi_slave_tb_2/spi_miso
add wave -noupdate -format Logic /spi_slave_tb_2/spi_ss
add wave -noupdate -format Logic /spi_slave_tb_2/fifo_req_data
add wave -noupdate -format Literal /spi_slave_tb_2/fifo_din
add wave -noupdate -format Logic /spi_slave_tb_2/fifo_din_valid
add wave -noupdate -format Logic /spi_slave_tb_2/fifo_empty
add wave -noupdate -format Literal /spi_slave_tb_2/reg_din
add wave -noupdate -format Logic /spi_slave_tb_2/reg_din_val
add wave -noupdate -format Logic /spi_slave_tb_2/reg_ack
add wave -noupdate -format Logic /spi_slave_tb_2/reg_err
add wave -noupdate -format Logic /spi_slave_tb_2/busy
add wave -noupdate -format Logic /spi_slave_tb_2/interrupt
add wave -noupdate -format Literal /spi_slave_tb_2/dout
add wave -noupdate -format Logic /spi_slave_tb_2/dout_valid
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/cur_st
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/next_st
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/spi_sr_out
add wave -noupdate -format Logic /spi_slave_tb_2/spi_slave_inst/sr_out_data
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/spi_sr_in
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/sr_cnt_out
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/sr_cnt_in
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/fifo_req_sr
add wave -noupdate -format Literal /spi_slave_tb_2/spi_slave_inst/conf_reg
add wave -noupdate -format Logic /spi_slave_tb_2/spi_slave_inst/samp_en
add wave -noupdate -format Logic /spi_slave_tb_2/spi_slave_inst/prop_en
add wave -noupdate -format Logic /spi_slave_tb_2/spi_slave_inst/cpol
add wave -noupdate -format Logic /spi_slave_tb_2/spi_slave_inst/cpha
add wave -noupdate -format Logic /spi_slave_tb_2/spi_slave_inst/spi_clk_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3135203 ps} 0}
configure wave -namecolwidth 264
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
WaveRestoreZoom {2776063 ps} {3222313 ps}