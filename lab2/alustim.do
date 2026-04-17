onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal /alustim/A
add wave -noupdate -radix decimal /alustim/B
add wave -noupdate -radix hexadecimal /alustim/cntrl
add wave -noupdate /alustim/carry_out
add wave -noupdate /alustim/negative
add wave -noupdate /alustim/overflow
add wave -noupdate /alustim/zero
add wave -noupdate -radix decimal /alustim/result
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10238976265 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 231
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
configure wave -timelineunits ps
update
WaveRestoreZoom {9966339410 ps} {10324359297 ps}
