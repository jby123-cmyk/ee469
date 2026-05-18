onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_tb/clk
add wave -noupdate /cpu_tb/reset
add wave -noupdate -radix decimal /cpu_tb/dut/pc_r
add wave -noupdate -radix decimal /cpu_tb/dut/pc_n
add wave -noupdate /cpu_tb/dut/negative_r
add wave -noupdate /cpu_tb/dut/overflow_r
add wave -noupdate /cpu_tb/dut/zero_r
add wave -noupdate /cpu_tb/dut/carry_out_r
add wave -noupdate /cpu_tb/dut/data_memory/mem
add wave -noupdate -radix decimal /cpu_tb/dut/registers/registers
add wave -noupdate /cpu_tb/dut/addi_imm
add wave -noupdate /cpu_tb/dut/instruction
add wave -noupdate /cpu_tb/dut/opcode
add wave -noupdate /cpu_tb/dut/branch_imm_sel
add wave -noupdate /cpu_tb/dut/data_memory/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {77425530 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {2556416 ps}
