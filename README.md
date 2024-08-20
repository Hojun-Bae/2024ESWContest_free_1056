// File tree
SW                        // SNN algorithm C implementation
ㅏ inf.c                   // inference code (after learn)
ㅏ Makefile                // Makefile
ㅏ snn.c                   // learn code
ㄴ snn.h                   // header file

HW                        // Verilog HDL RTL code
ㅏ controller.v            // system controller module
ㅏ dpbram.v                // true dual port bram code
ㅏ findMax.v               // finding max module
ㅏ hojun.v                 // top hierarchy
ㅏ lfsr.v                  // linear feedback shift register (pseudo random gen)
ㅏ myip_v1_0.v             // AXI4-lite slave wrapper
ㅏ myip_v1_0_S00_AXI.v     // AXI4-lite slave ip
ㅏ postBuffer.v            // post spike buffer
ㅏ preBuffer.v             // pre spike buffer
ㅏ snnTop.v                // snn top module including controller
ㅏ spbram.v                // single port bram code
ㅏ stdp.v                  // stdp 
ㅏ sub_top.v               // single core
ㅏ synapse.v               // synaptic accumulation
ㅏ top.v                   // snn top module not including controller
ㄴ updateNeuron.v          // neuron core

VERIFY                    // RTL verification code
ㅏ hojun_sim.srcs          // total system verification           
ㅣ ㅏ sim_1
ㅣ ㅣ ㄴ new
ㅣ ㅣ ㅣ ㅏ mnist.txt         // mnist data
ㅣ ㅣ ㅣ ㄴ top_tb.v          // testbench
ㅣ ㄴ sources_1
ㅣ ㅣ ㄴ HW                  // RTL code
ㅣ ㅣ ㅣ ㅏ controller.v
ㅣ ㅣ ㅣ ㅏ dpbram.v
ㅣ ㅣ ㅣ ㅏ findMax.v
ㅣ ㅣ ㅣ ㅏ lfsr.v
ㅣ ㅣ ㅣ ㅏ postBuffer.v
ㅣ ㅣ ㅣ ㅏ preBuffer.v
ㅣ ㅣ ㅣ ㅏ spbram.v
ㅣ ㅣ ㅣ ㅏ stdp.v
ㅣ ㅣ ㅣ ㅏ sub_top.v
ㅣ ㅣ ㅣ ㅏ synapse.v
ㅣ ㅣ ㅣ ㅏ top.v
ㅣ ㅣ ㅣ ㄴ updateNeuron.v
ㅏ preBuffer               // pre spike buffer verification
ㅣ ㅏ ref_c                 // golden reference
ㅣ ㅣ ㅏ input_spike.txt
ㅣ ㅣ ㅏ lfsr.txt
ㅣ ㅣ ㅏ Makefile
ㅣ ㅣ ㅏ mnist.txt
ㅣ ㅣ ㅏ pixel.txt
ㅣ ㅣ ㅏ test.c              // golden reference SW code
ㅣ ㅣ ㅏ test.o
ㅣ ㅣ ㅏ test.out
ㅣ ㅣ ㄴ x_trace.txt
ㅣ ㅏ build                 // vivado RTL sim build
ㅣ ㅏ clean
ㅣ ㅏ dpbram.v
ㅣ ㅏ input_spike.txt
ㅣ ㅏ lfsr.txt
ㅣ ㅏ lfsr.v
ㅣ ㅏ Makefile
ㅣ ㅏ preBuffer.v
ㅣ ㅏ preBuffer_tb.v        // testbench
ㅣ ㄴ spbram.v
ㅏ stdp                    // stdp verification
ㅣ ㅏ golden_ref            // golden reference
ㅣ ㅣ ㅏ Makefile            // Makefile
ㅣ ㅣ ㅏ test
ㅣ ㅣ ㄴ test.c              // golden reference SW code
ㅣ ㅏ build
ㅣ ㅏ clean
ㅣ ㅏ dpbram.v
ㅣ ㅏ stdp.v
ㅣ ㅏ stdp_tb.v             // testbench
ㅣ ㄴ v_result.txt
ㅏ sub_top                 // single core verification
ㅣ ㅏ build
ㅣ ㅏ clean
ㅣ ㅏ controller.v
ㅣ ㅏ dpbram.v
ㅣ ㅏ exc_conductance.csv
ㅣ ㅏ exc_membrane.csv
ㅣ ㅏ exc_threshold.csv
ㅣ ㅏ findMax.v
ㅣ ㅏ inh_conductance.csv
ㅣ ㅏ input_spike.csv
ㅣ ㅏ lfsr.v
ㅣ ㅏ mnist.txt
ㅣ ㅏ postBuffer.v
ㅣ ㅏ preBuffer.v
ㅣ ㅏ spbram.v
ㅣ ㅏ stdp.v
ㅣ ㅏ sub_top.v
ㅣ ㅏ sub_top_tb.v          // testbench
ㅣ ㅏ synapse.v
ㅣ ㅏ top.v
ㅣ ㅏ top_tb.v
ㅣ ㄴ updateNeuron.v
ㅏ synapse                 // synaptic accumulation verification
ㅣ ㅏ golden_ref            // golden reference
ㅣ ㅣ ㅏ Makefile
ㅣ ㅣ ㅏ ref_c_rand_input_node.txt
ㅣ ㅣ ㅏ ref_c_rand_input_wegt.txt
ㅣ ㅣ ㅏ ref_c_result.txt
ㅣ ㅣ ㅏ test
ㅣ ㅣ ㅏ test.c              // golden reference SW code
ㅣ ㅣ ㄴ test2.c
ㅣ ㅏ build
ㅣ ㅏ clean
ㅣ ㅏ init_weight.txt
ㅣ ㅏ Makefile
ㅣ ㅏ spbram.v
ㅣ ㅏ synapse.v
ㅣ ㄴ synapse_tb.v          // testbench
ㄴ updateNeuron            // neuron core verification
ㅣ ㅏ data
ㅣ ㅣ ㅏ exc_conductance.csv
ㅣ ㅣ ㅏ exc_membrane.csv
ㅣ ㅣ ㅏ exc_threshold.csv
ㅣ ㅣ ㅏ inh_conductance.csv
ㅣ ㅣ ㅏ y1_trace.csv
ㅣ ㅣ ㅏ y2_trace.csv
ㅣ ㅣ ㄴ y2_trace_buf.csv
ㅣ ㅏ build
ㅣ ㅏ clean
ㅣ ㅏ Makefile
ㅣ ㅏ postBuffer.v
ㅣ ㅏ spbram.v
ㅣ ㅏ updateNeuron.v
ㅣ ㄴ updateNeuron_tb.v     // testbench

// RTL hierarchy
hojun.v
ㅏ myip_v1_0.v     
ㅣ ㄴ myip_v1_0_S00_AXI.v  
ㅏ snnTop.v  
ㅣ ㅏ controller.v 
ㅣ ㄴ top.v
ㅣ ㅣ ㅏ findMax.v 
ㅣ ㅣ ㅏ lfsr.v 
ㅣ ㅣ ㅏ preBuffer.v  
ㅣ ㅣ ㅏ sub_top.v 
ㅣ ㅣ ㅣ ㅏ postBuffer.v
ㅣ ㅣ ㅣ ㅏ synapse.v 
ㅣ ㅣ ㅣ ㅏ updateNeuron.v    
ㄴ ㄴ ㄴ ㄴ stdp.v 
