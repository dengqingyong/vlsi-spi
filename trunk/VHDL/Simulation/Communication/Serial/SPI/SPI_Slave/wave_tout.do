onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /spi_slave_tout_tb/clk
add wave -noupdate -format Logic /spi_slave_tout_tb/rst
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_clk
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_mosi
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_miso
add wave -noupdate -color Brown -format Logic -itemcolor Brown /spi_slave_tout_tb/spi_ss
add wave -noupdate -format Logic /spi_slave_tout_tb/fifo_req_data
add wave -noupdate -format Literal /spi_slave_tout_tb/fifo_din
add wave -noupdate -format Logic /spi_slave_tout_tb/fifo_din_valid
add wave -noupdate -format Logic /spi_slave_tout_tb/fifo_empty
add wave -noupdate -divider {New Divider}
add wave -noupdate -color Coral -format Logic -itemcolor Coral /spi_slave_tout_tb/timeout
add wave -noupdate -color Turquoise -format Literal -itemcolor Turquoise -radix unsigned /spi_slave_tout_tb/spi_slave_inst/spi_tout_cnt
add wave -noupdate -divider {New Divider}
add wave -noupdate -color {Cadet Blue} -format Logic -itemcolor {Cadet Blue} /spi_slave_tout_tb/spi_slave_inst/spi_clk_i
add wave -noupdate -color Khaki -format Logic -itemcolor Khaki /spi_slave_tout_tb/spi_slave_inst/spi_clk_reg
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Literal /spi_slave_tout_tb/dout
add wave -noupdate -format Logic /spi_slave_tout_tb/dout_valid
add wave -noupdate -format Literal /spi_slave_tout_tb/spi_slave_inst/cur_st
add wave -noupdate -format Literal /spi_slave_tout_tb/spi_slave_inst/spi_sr_out
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_slave_inst/sr_out_data
add wave -noupdate -format Literal /spi_slave_tout_tb/spi_slave_inst/spi_sr_in
add wave -noupdate -format Literal /spi_slave_tout_tb/spi_slave_inst/sr_cnt_out
add wave -noupdate -format Literal /spi_slave_tout_tb/spi_slave_inst/sr_cnt_in
add wave -noupdate -format Literal /spi_slave_tout_tb/spi_slave_inst/fifo_req_sr
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_slave_inst/spi_sr_proc/prop_en
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_slave_inst/spi_sr_proc/samp_en
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_slave_inst/cpol
add wave -noupdate -format Logic /spi_slave_tout_tb/spi_slave_inst/cpha
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1128015 ps} 0}
configure wave -namecolwidth 319
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
WaveRestoreZoom {1011250 ps} {5736250 ps}
