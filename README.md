// File tree
SW                        // SNN algorithm C implementation
┣ inf.c                   // inference code (after learn)
┣ Makefile                // Makefile
┣ snn.c                   // learn code
┗ snn.h                   // header file

HW                        // Verilog HDL RTL code
┣ controller.v            // system controller module
┣ dpbram.v                // true dual port bram code
┣ findMax.v               // finding max module
┣ hojun.v                 // top hierarchy
┣ lfsr.v                  // linear feedback shift register (pseudo random gen)
┣ myip_v1_0.v             // AXI4-lite slave wrapper
┣ myip_v1_0_S00_AXI.v     // AXI4-lite slave ip
┣ postBuffer.v            // post spike buffer
┣ preBuffer.v             // pre spike buffer
┣ snnTop.v                // snn top module including controller
┣ spbram.v                // single port bram code
┣ stdp.v                  // stdp 
┣ sub_top.v               // single core
┣ synapse.v               // synaptic accumulation
┣ top.v                   // snn top module not including controller
┗ updateNeuron.v          // neuron core

VERIFY                    // RTL verification code
┣ hojun_sim.srcs          // total system verification           
┃ ┣ sim_1
┃ ┃ ┗ new
┃ ┃ ┃ ┣ mnist.txt         // mnist data
┃ ┃ ┃ ┗ top_tb.v          // testbench
┃ ┗ sources_1
┃ ┃ ┗ HW                  // RTL code
┃ ┃ ┃ ┣ controller.v
┃ ┃ ┃ ┣ dpbram.v
┃ ┃ ┃ ┣ findMax.v
┃ ┃ ┃ ┣ lfsr.v
┃ ┃ ┃ ┣ postBuffer.v
┃ ┃ ┃ ┣ preBuffer.v
┃ ┃ ┃ ┣ spbram.v
┃ ┃ ┃ ┣ stdp.v
┃ ┃ ┃ ┣ sub_top.v
┃ ┃ ┃ ┣ synapse.v
┃ ┃ ┃ ┣ top.v
┃ ┃ ┃ ┗ updateNeuron.v
┣ preBuffer               // pre spike buffer verification
┃ ┣ ref_c                 // golden reference
┃ ┃ ┣ input_spike.txt
┃ ┃ ┣ lfsr.txt
┃ ┃ ┣ Makefile
┃ ┃ ┣ mnist.txt
┃ ┃ ┣ pixel.txt
┃ ┃ ┣ test.c              // golden reference SW code
┃ ┃ ┣ test.o
┃ ┃ ┣ test.out
┃ ┃ ┗ x_trace.txt
┃ ┣ build                 // vivado RTL sim build
┃ ┣ clean
┃ ┣ dpbram.v
┃ ┣ input_spike.txt
┃ ┣ lfsr.txt
┃ ┣ lfsr.v
┃ ┣ Makefile
┃ ┣ preBuffer.v
┃ ┣ preBuffer_tb.v        // testbench
┃ ┗ spbram.v
┣ stdp                    // stdp verification
┃ ┣ golden_ref            // golden reference
┃ ┃ ┣ Makefile            // Makefile
┃ ┃ ┣ test
┃ ┃ ┗ test.c              // golden reference SW code
┃ ┣ build
┃ ┣ clean
┃ ┣ dpbram.v
┃ ┣ stdp.v
┃ ┣ stdp_tb.v             // testbench
┃ ┗ v_result.txt
┣ sub_top                 // single core verification
┃ ┣ build
┃ ┣ clean
┃ ┣ controller.v
┃ ┣ dpbram.v
┃ ┣ exc_conductance.csv
┃ ┣ exc_membrane.csv
┃ ┣ exc_threshold.csv
┃ ┣ findMax.v
┃ ┣ inh_conductance.csv
┃ ┣ input_spike.csv
┃ ┣ lfsr.v
┃ ┣ mnist.txt
┃ ┣ postBuffer.v
┃ ┣ preBuffer.v
┃ ┣ spbram.v
┃ ┣ stdp.v
┃ ┣ sub_top.v
┃ ┣ sub_top_tb.v          // testbench
┃ ┣ synapse.v
┃ ┣ top.v
┃ ┣ top_tb.v
┃ ┗ updateNeuron.v
┣ synapse                 // synaptic accumulation verification
┃ ┣ golden_ref            // golden reference
┃ ┃ ┣ Makefile
┃ ┃ ┣ ref_c_rand_input_node.txt
┃ ┃ ┣ ref_c_rand_input_wegt.txt
┃ ┃ ┣ ref_c_result.txt
┃ ┃ ┣ test
┃ ┃ ┣ test.c              // golden reference SW code
┃ ┃ ┗ test2.c
┃ ┣ build
┃ ┣ clean
┃ ┣ init_weight.txt
┃ ┣ Makefile
┃ ┣ spbram.v
┃ ┣ synapse.v
┃ ┗ synapse_tb.v          // testbench
┗ updateNeuron            // neuron core verification
┃ ┣ data
┃ ┃ ┣ exc_conductance.csv
┃ ┃ ┣ exc_membrane.csv
┃ ┃ ┣ exc_threshold.csv
┃ ┃ ┣ inh_conductance.csv
┃ ┃ ┣ y1_trace.csv
┃ ┃ ┣ y2_trace.csv
┃ ┃ ┗ y2_trace_buf.csv
┃ ┣ build
┃ ┣ clean
┃ ┣ Makefile
┃ ┣ postBuffer.v
┃ ┣ spbram.v
┃ ┣ updateNeuron.v
┃ ┗ updateNeuron_tb.v     // testbench

// RTL hierarchy
hojun.v
┣ myip_v1_0.v     
┃ ┗ myip_v1_0_S00_AXI.v  
┣ snnTop.v  
┃ ┣ controller.v 
┃ ┗ top.v
┃ ┃ ┣ findMax.v 
┃ ┃ ┣ lfsr.v 
┃ ┃ ┣ preBuffer.v  
┃ ┃ ┣ sub_top.v 
┃ ┃ ┃ ┣ postBuffer.v
┃ ┃ ┃ ┣ synapse.v 
┃ ┃ ┃ ┣ updateNeuron.v    
┗ ┗ ┗ ┗ stdp.v 
