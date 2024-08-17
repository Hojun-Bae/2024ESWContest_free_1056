`timescale 1ns/1ps

module updateNeuron_tb;

reg clk;
reg reset_n;

reg i_run;
reg i_init;
reg i_cnt_clr;

reg signed [24:0] exc_current;
reg signed [24:0] inh_current;

wire s_init;
wire spike;
wire valid;
wire [4:0] neuron_idx;

wire [17:0] spike_buffer;
wire [287:0] y1_trace;
wire [287:0] y2_trace_buf;
wire [4:0] o_inhbt;
wire [125:0] o_post_cnt;
wire cnt_valid;

// CONDUCTANCE/REFRACTORY BRAM I/F
wire [49:0] d_c;
wire [4:0] addr_c;
wire ce_c;
wire we_c;
wire [49:0] q_c;

// MEMBRANE POTENTIAL/THRESHOLD/REFRACTORY BRAM I/F
wire [54:0] d_m;
wire [4:0] addr_m;
wire ce_m;
wire we_m;
wire [54:0] q_m;


// clk gen
always
    #5 clk = ~clk;

integer i, j, f_vm, f_vt, f_ge, f_gi, f_y1, f_y2;

initial begin
	f_vm = $fopen("./data/exc_membrane.csv", "wb");
	f_vt = $fopen("./data/exc_threshold.csv", "wb");
	f_ge = $fopen("./data/exc_conductance.csv", "wb");
	f_gi = $fopen("./data/inh_conductance.csv", "wb");
	f_y1 = $fopen("./data/y1_trace.csv", "wb");
	f_y2 = $fopen("./data/y2_trace_buf.csv", "wb");
end

initial begin
	reset_n = 1;
	clk = 0;
	i_run = 0;
	i_cnt_clr = 0;

	exc_current = 25'd0;
	inh_current = 25'd0;

	// reset_n gen
	$display("Reset! [%0d]", $time);
# 100
    reset_n = 0;
# 10
    reset_n = 1;
# 10
	@(posedge clk);

$display("Step 1. Mem write to BRAM [%0d]", $time);
	i_init <= 1;
	@(posedge clk);
	i_init <= 0;
for(i=0; i<20; i=i+1) begin
	@(posedge clk);
end

	i_cnt_clr <= 1;
	@(posedge clk);
	i_cnt_clr <= 0;
	
$display("Step 2. Start! [%0d]", $time);
for(i=0; i<800; i=i+1) begin
	for(j=0; j<18; j=j+1) begin
		i_run <= 1;
		if(i%30 == 4) begin
			exc_current <= 25'd2000 + j*2000;
			inh_current <= 25'd0;
		end else if(i%300 == 102) begin
			exc_current <= 25'd0;
			inh_current <= 25'd2000 + j*1800;
		end else begin
			exc_current <= 25'd0;
			inh_current <= 25'd0;
		end
		@(posedge clk);
		i_run <= 0;
		@(posedge clk);
		wait(valid);
		$fwrite(f_vm, "%0d, ", u_TDPBRAM_1.ram[j][49:25]);
		$fwrite(f_vt, "%0d, ", u_TDPBRAM_1.ram[j][24:0]);
		$fwrite(f_ge, "%0d, ", u_TDPBRAM_0.ram[j][49:25]);
		$fwrite(f_gi, "%0d, ", u_TDPBRAM_0.ram[j][24:0]);
		@(posedge clk);
		@(posedge clk);
	end
	@(posedge clk);
	@(posedge clk);
	for(j=0; j<18; j=j+1) begin
		$fwrite(f_y1, "%0d, ", y1_trace[j*16 +: 16]);
		$fwrite(f_y2, "%0d, ", y2_trace_buf[j*16 +: 16]);
	end
	$fwrite(f_vm, "\n");
	$fwrite(f_vt, "\n");
	$fwrite(f_ge, "\n");
	$fwrite(f_gi, "\n");
	$fwrite(f_y1, "\n");
	$fwrite(f_y2, "\n");
end

$display("Step 5. Read Result [%0d]", $time);

for(i=0; i<10; i=i+1) begin
	@(posedge clk);
end
	i_cnt_clr <= 1;
	@(posedge clk);
	i_cnt_clr <= 0;

$fclose(f_vm);
$fclose(f_vt);
$fclose(f_ge);
$fclose(f_gi);
$fclose(f_y1);
$fclose(f_y2);

// TODO Check to compare result
# 100
$display("Success Simulation!! [%0d]", $time);
$finish;
end

// Call DUT
updateNeuron dut_updateNeuron
(
	.clk (clk),
	.reset_n (reset_n),
	.i_run (i_run),
	.i_init (i_init),
	.o_s_init (s_init),

	.exc_current (exc_current),
	.inh_current (inh_current),

	.o_spike (spike),
	.o_valid (valid),
	.o_neuron_idx (neuron_idx),

	// BRAM I/F
	.d_c (d_c),
	.addr_c (addr_c),
	.ce_c (ce_c),
	.we_c (we_c),
	.q_c (q_c),

	.d_m (d_m),
	.addr_m (addr_m),
	.ce_m (ce_m),
	.we_m (we_m),
	.q_m (q_m)
);

postBuffer dut_postBuffer
(
	.clk (clk),
	.reset_n (reset_n),
	.i_valid (valid),
	.i_spike (spike),
	.i_cnt_clr (i_cnt_clr),
	.i_s_init (s_init),
	.i_neuron_idx (neuron_idx),

	.o_spike_buffer (spike_buffer),
	.o_y1_trace (y1_trace),
	.o_y2_trace_buf (y2_trace_buf),
	.o_inhbt (o_inhbt),
	.o_post_cnt (o_post_cnt),
	.o_valid (cnt_valid)
);

spbram
#(	
	.DWIDTH (50),
	.AWIDTH (5),
	.MEM_SIZE (18)
)
u_TDPBRAM_0(
	.clk		(clk),

	.addr		(addr_c),
	.en		(ce_c),
	.we		(we_c),
	.q			(q_c),
	.d			(d_c) 
);

spbram
#(	
	.DWIDTH (55),
	.AWIDTH (5),
	.MEM_SIZE (18)
)
u_TDPBRAM_1(
	.clk		(clk),

	.addr		(addr_m),
	.en		(ce_m),
	.we		(we_m),
	.q			(q_m),
	.d			(d_m)
);

endmodule
