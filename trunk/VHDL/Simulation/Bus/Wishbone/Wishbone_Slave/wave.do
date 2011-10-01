onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /tb_wbs_spi/clk_i
add wave -noupdate -format Logic /tb_wbs_spi/rst
add wave -noupdate -format Logic /tb_wbs_spi/wbs_cyc_i
add wave -noupdate -format Logic /tb_wbs_spi/wbs_stb_i
add wave -noupdate -format Logic /tb_wbs_spi/wbs_we_i
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/wbs_adr_i
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/wbs_tga_i
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/wbs_dat_i
add wave -noupdate -format Logic /tb_wbs_spi/wbs_tgc_i
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/wbs_dat_o
add wave -noupdate -format Logic /tb_wbs_spi/wbs_stall_o
add wave -noupdate -format Logic /tb_wbs_spi/wbs_ack_o
add wave -noupdate -format Logic /tb_wbs_spi/wbs_err_o
add wave -noupdate -format Logic /tb_wbs_spi/mp_enc_done
add wave -noupdate -format Logic /tb_wbs_spi/mp_enc_reg_ready
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/mp_enc_type_reg
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/mp_enc_addr_reg
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/mp_enc_len_reg
add wave -noupdate -format Logic /tb_wbs_spi/mp_dec_done
add wave -noupdate -format Logic /tb_wbs_spi/mp_dec_eof_err
add wave -noupdate -format Logic /tb_wbs_spi/mp_dec_crc_err
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/mp_dec_type_reg
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/mp_dec_addr_reg
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/mp_dec_len_reg
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/ram_enc_addr
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/ram_enc_din
add wave -noupdate -format Logic /tb_wbs_spi/ram_enc_din_val
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/ram_dec_dout
add wave -noupdate -format Logic /tb_wbs_spi/ram_dec_dout_val
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/ram_dec_addr
add wave -noupdate -format Logic /tb_wbs_spi/ram_dec_aout_val
add wave -noupdate -format Logic /tb_wbs_spi/spi_we
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/spi_reg_addr
add wave -noupdate -format Literal -radix hexadecimal /tb_wbs_spi/spi_reg_din
add wave -noupdate -format Logic /tb_wbs_spi/spi_reg_din_val
add wave -noupdate -format Logic /tb_wbs_spi/spi_reg_ack
add wave -noupdate -format Logic /tb_wbs_spi/spi_reg_err
add wave -noupdate -format Literal /tb_wbs_spi/wbs_inst/cur_st
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {305056 ps} 0}
configure wave -namecolwidth 290
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
WaveRestoreZoom {0 ps} {424736 ps}
