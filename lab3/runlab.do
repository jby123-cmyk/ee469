# Create work library
vlib work

# Compile Verilog
#     All Verilog files that are part of this design should have
#     their own "vlog" line below.
vlog "./decoders.sv"
vlog "./muxes.sv"
vlog "./dff.sv"
vlog "./regfile.sv"
vlog "./regstim.sv"
vlog "./cpu.sv"
vlog "./cpu_tb.sv"
vlog "./instructmem.sv"
vlog "./datamem.sv"
vlog "./control.sv"
vlog "./adders.sv"
vlog "./alu_bitslice.sv"
vlog "./alu.sv"

# Call vsim to invoke simulator
#     Make sure the last item on the line is the name of the
#     testbench module you want to execute.
vsim -voptargs="+acc" -t 1ps -lib work cpu_tb

# Source the wave do file
#     This should be the file that sets up the signal window for
#     the module you are testing.
do cpu_tb.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all

# End
