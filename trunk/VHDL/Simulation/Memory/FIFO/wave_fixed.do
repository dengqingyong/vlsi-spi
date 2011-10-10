onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /general_fifo_tb/clk
add wave -noupdate -format Logic /general_fifo_tb/rst
add wave -noupdate -format Literal /general_fifo_tb/din
add wave -noupdate -format Logic /general_fifo_tb/wr_en
add wave -noupdate -format Logic /general_fifo_tb/rd_en
add wave -noupdate -format Logic /general_fifo_tb/flush
add wave -noupdate -format Literal /general_fifo_tb/dout
add wave -noupdate -format Logic /general_fifo_tb/dout_valid
add wave -noupdate -format Logic /general_fifo_tb/afull
add wave -noupdate -format Logic /general_fifo_tb/full
add wave -noupdate -format Logic /general_fifo_tb/aempty
add wave -noupdate -format Logic /general_fifo_tb/empty
add wave -noupdate -format Literal /general_fifo_tb/used
add wave -noupdate -format Literal -radix decimal /general_fifo_tb/general_fifo_inst/mem
add wave -noupdate -format Literal /general_fifo_tb/general_fifo_inst/write_addr
add wave -noupdate -format Literal /general_fifo_tb/general_fifo_inst/read_addr
add wave -noupdate -format Literal /general_fifo_tb/general_fifo_inst/read_addr_dup
add wave -noupdate -format Literal /general_fifo_tb/general_fifo_inst/count
add wave -noupdate -format Logic /general_fifo_tb/general_fifo_inst/ifull
add wave -noupdate -format Logic /general_fifo_tb/general_fifo_inst/iempty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {988073 ps} 0}
configure wave -namecolwidth 298
configure wave -valuecolwidth 125
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
WaveRestoreZoom {501500 ps} {1131500 ps}
