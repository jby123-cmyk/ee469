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
add wave -noupdate -radix decimal -childformat {{{/cpu_tb/dut/registers/registers[31]} -radix decimal} {{/cpu_tb/dut/registers/registers[30]} -radix decimal} {{/cpu_tb/dut/registers/registers[29]} -radix decimal} {{/cpu_tb/dut/registers/registers[28]} -radix decimal} {{/cpu_tb/dut/registers/registers[27]} -radix decimal} {{/cpu_tb/dut/registers/registers[26]} -radix decimal} {{/cpu_tb/dut/registers/registers[25]} -radix decimal} {{/cpu_tb/dut/registers/registers[24]} -radix decimal} {{/cpu_tb/dut/registers/registers[23]} -radix decimal} {{/cpu_tb/dut/registers/registers[22]} -radix decimal} {{/cpu_tb/dut/registers/registers[21]} -radix decimal} {{/cpu_tb/dut/registers/registers[20]} -radix decimal} {{/cpu_tb/dut/registers/registers[19]} -radix decimal} {{/cpu_tb/dut/registers/registers[18]} -radix decimal} {{/cpu_tb/dut/registers/registers[17]} -radix decimal} {{/cpu_tb/dut/registers/registers[16]} -radix decimal} {{/cpu_tb/dut/registers/registers[15]} -radix decimal} {{/cpu_tb/dut/registers/registers[14]} -radix decimal} {{/cpu_tb/dut/registers/registers[13]} -radix decimal} {{/cpu_tb/dut/registers/registers[12]} -radix decimal} {{/cpu_tb/dut/registers/registers[11]} -radix decimal} {{/cpu_tb/dut/registers/registers[10]} -radix decimal} {{/cpu_tb/dut/registers/registers[9]} -radix decimal} {{/cpu_tb/dut/registers/registers[8]} -radix decimal} {{/cpu_tb/dut/registers/registers[7]} -radix decimal} {{/cpu_tb/dut/registers/registers[6]} -radix decimal} {{/cpu_tb/dut/registers/registers[5]} -radix decimal} {{/cpu_tb/dut/registers/registers[4]} -radix decimal} {{/cpu_tb/dut/registers/registers[3]} -radix decimal} {{/cpu_tb/dut/registers/registers[2]} -radix decimal} {{/cpu_tb/dut/registers/registers[1]} -radix decimal} {{/cpu_tb/dut/registers/registers[0]} -radix decimal}} -subitemconfig {{/cpu_tb/dut/registers/registers[31]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[30]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[29]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[28]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[27]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[26]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[25]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[24]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[23]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[22]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[21]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[20]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[19]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[18]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[17]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[16]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[15]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[14]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[13]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[12]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[11]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[10]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[9]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[8]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[7]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[6]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[5]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[4]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[3]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[2]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[1]} {-height 15 -radix decimal} {/cpu_tb/dut/registers/registers[0]} {-height 15 -radix decimal}} /cpu_tb/dut/registers/registers
add wave -noupdate /cpu_tb/dut/addi_imm
add wave -noupdate /cpu_tb/dut/instruction
add wave -noupdate /cpu_tb/dut/opcode
add wave -noupdate /cpu_tb/dut/data_memory/mem
add wave -noupdate /cpu_tb/dut/forward_alu_A
add wave -noupdate /cpu_tb/dut/forward_alu_B
add wave -noupdate /cpu_tb/dut/ex_mem_fwd_data
add wave -noupdate /cpu_tb/dut/ldur_en_m
add wave -noupdate /cpu_tb/dut/hzd_unit/stall_hazard
add wave -noupdate /cpu_tb/dut/subs_in_mem
add wave -noupdate /cpu_tb/dut/branch_lt_cond_id
add wave -noupdate /cpu_tb/dut/branch_taken_id
add wave -noupdate /cpu_tb/dut/negative_eval_m
add wave -noupdate /cpu_tb/dut/negative_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {424391209 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {423071555 ps} {425515237 ps}
