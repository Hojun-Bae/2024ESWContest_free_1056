# SNN Algorithm Implementation and RTL Code

This README provides an overview of the directory structure and RTL hierarchy for the SNN algorithm implementation and verification process. Each module is organized under specific directories, with a clear distinction between the C implementation, Verilog HDL code, and verification code.

## Directory Structure

### SW (C Implementation of SNN Algorithm)
- **inf.c**: Inference code (after learning).
- **Makefile**: Makefile for building the project.
- **snn.c**: Learning code.
- **snn.h**: Header file.

### HW (Verilog HDL RTL Code)
- **controller.v**: System controller module.
- **dpbram.v**: True dual port BRAM code.
- **findMax.v**: Module for finding maximum value.
- **hojun.v**: Top-level hierarchy module.
- **lfsr.v**: Linear feedback shift register (pseudo-random generator).
- **myip_v1_0.v**: AXI4-Lite slave wrapper.
- **myip_v1_0_S00_AXI.v**: AXI4-Lite slave IP.
- **postBuffer.v**: Post-spike buffer.
- **preBuffer.v**: Pre-spike buffer.
- **snnTop.v**: SNN top module including the controller.
- **spbram.v**: Single port BRAM code.
- **stdp.v**: STDP (Spike-Timing-Dependent Plasticity) module.
- **sub_top.v**: Single core module.
- **synapse.v**: Synaptic accumulation module.
- **top.v**: SNN top module excluding the controller.
- **updateNeuron.v**: Neuron core module.

### VERIFY (RTL Verification Code)
- **hojun_sim.srcs**: Total system verification.
  - **sim_1/new/mnist.txt**: MNIST data.
  - **sim_1/new/top_tb.v**: Testbench.
  - **sources_1/HW/**: RTL code.
    - **controller.v**
    - **dpbram.v**
    - **findMax.v**
    - **lfsr.v**
    - **postBuffer.v**
    - **preBuffer.v**
    - **spbram.v**
    - **stdp.v**
    - **sub_top.v**
    - **synapse.v**
    - **top.v**
    - **updateNeuron.v**

#### Verification Modules
- **preBuffer**: Pre-spike buffer verification.
  - **ref_c/**: Golden reference.
    - **input_spike.txt**
    - **lfsr.txt**
    - **Makefile**
    - **mnist.txt**
    - **pixel.txt**
    - **test.c**: Golden reference SW code.
    - **x_trace.txt**
  - **preBuffer_tb.v**: Testbench for preBuffer.
  - **Other Files**: RTL files and build scripts.

- **stdp**: STDP verification.
  - **golden_ref/**: Golden reference.
    - **Makefile**
    - **test.c**: Golden reference SW code.
  - **stdp_tb.v**: Testbench for STDP.
  - **v_result.txt**: Verification results.

- **sub_top**: Single core verification.
  - **sub_top_tb.v**: Testbench for single core.
  - **Various CSV files**: Data files for verification.

- **synapse**: Synaptic accumulation verification.
  - **golden_ref/**: Golden reference.
    - **Makefile**
    - **test.c**: Golden reference SW code.
  - **synapse_tb.v**: Testbench for synaptic accumulation.

- **updateNeuron**: Neuron core verification.
  - **data/**: Data files for verification.
  - **updateNeuron_tb.v**: Testbench for neuron core.

## RTL Hierarchy
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

