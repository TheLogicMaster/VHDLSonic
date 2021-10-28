onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_test/clock
add wave -noupdate /cpu_test/reset
add wave -noupdate -radix hexadecimal /cpu_test/address
add wave -noupdate /cpu_test/data_mask
add wave -noupdate /cpu_test/write_en
add wave -noupdate -radix hexadecimal /cpu_test/rom
add wave -noupdate -radix hexadecimal -childformat {{/cpu_test/ram(0) -radix hexadecimal} {/cpu_test/ram(1) -radix hexadecimal} {/cpu_test/ram(2) -radix hexadecimal} {/cpu_test/ram(3) -radix hexadecimal} {/cpu_test/ram(4) -radix hexadecimal} {/cpu_test/ram(5) -radix hexadecimal} {/cpu_test/ram(6) -radix hexadecimal} {/cpu_test/ram(7) -radix hexadecimal} {/cpu_test/ram(8) -radix hexadecimal} {/cpu_test/ram(9) -radix hexadecimal} {/cpu_test/ram(10) -radix hexadecimal} {/cpu_test/ram(11) -radix hexadecimal} {/cpu_test/ram(12) -radix hexadecimal} {/cpu_test/ram(13) -radix hexadecimal} {/cpu_test/ram(14) -radix hexadecimal} {/cpu_test/ram(15) -radix hexadecimal}} -subitemconfig {/cpu_test/ram(0) {-height 17 -radix hexadecimal} /cpu_test/ram(1) {-height 17 -radix hexadecimal} /cpu_test/ram(2) {-height 17 -radix hexadecimal} /cpu_test/ram(3) {-height 17 -radix hexadecimal} /cpu_test/ram(4) {-height 17 -radix hexadecimal} /cpu_test/ram(5) {-height 17 -radix hexadecimal} /cpu_test/ram(6) {-height 17 -radix hexadecimal} /cpu_test/ram(7) {-height 17 -radix hexadecimal} /cpu_test/ram(8) {-height 17 -radix hexadecimal} /cpu_test/ram(9) {-height 17 -radix hexadecimal} /cpu_test/ram(10) {-height 17 -radix hexadecimal} /cpu_test/ram(11) {-height 17 -radix hexadecimal} /cpu_test/ram(12) {-height 17 -radix hexadecimal} /cpu_test/ram(13) {-height 17 -radix hexadecimal} /cpu_test/ram(14) {-height 17 -radix hexadecimal} /cpu_test/ram(15) {-height 17 -radix hexadecimal}} /cpu_test/ram
add wave -noupdate -radix hexadecimal /cpu_test/data_in
add wave -noupdate -radix hexadecimal /cpu_test/data_out
add wave -noupdate -radix hexadecimal /cpu_test/mask
add wave -noupdate -radix binary /cpu_test/reset_int
add wave -noupdate /cpu_test/prcoessor/state
add wave -noupdate -radix hexadecimal -childformat {{/cpu_test/prcoessor/reg_file(0) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(1) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(2) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(3) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(4) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(5) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(6) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(7) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(8) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(9) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(10) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(11) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(12) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(13) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(14) -radix hexadecimal} {/cpu_test/prcoessor/reg_file(15) -radix hexadecimal}} -subitemconfig {/cpu_test/prcoessor/reg_file(0) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(1) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(2) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(3) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(4) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(5) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(6) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(7) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(8) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(9) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(10) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(11) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(12) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(13) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(14) {-height 17 -radix hexadecimal} /cpu_test/prcoessor/reg_file(15) {-height 17 -radix hexadecimal}} /cpu_test/prcoessor/reg_file
add wave -noupdate -radix hexadecimal /cpu_test/prcoessor/instr
add wave -noupdate -radix hexadecimal /cpu_test/prcoessor/pc
add wave -noupdate /cpu_test/prcoessor/status
add wave -noupdate -radix hexadecimal /cpu_test/prcoessor/cache
add wave -noupdate -radix binary /cpu_test/prcoessor/interrupt_enable
add wave -noupdate -radix binary /cpu_test/prcoessor/interrupt_flags
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 161
configure wave -valuecolwidth 73
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
WaveRestoreZoom {0 ps} {424253 ps}
