`timescale 1ns/1ps

module preBuffer_tb;

///////////////////////////////
// LFSR
reg clk;
reg reset_n;
reg i_init;
reg i_run;
reg i_rest_run;
wire [3:0] spike;
wire w_run;
wire valid;

// Image BRAM I/F
wire [31:0] d;
wire [7:0] addr;
wire ce;
wire we;
wire [31:0] q;
///////////////////////////////

///////////////////////////////
// PREBUFFER
reg stdp_run;
wire [23:0] o_spike_bundle;
wire o_valid;
wire o_syn_run;
wire [383:0] o_trace;
wire o_done;
///////////////////////////////

integer file, f_rand, f_pix, x_trace, sout, i, j, k, status;

reg [7:0] pix;
reg [31:0] img;

// Clock generation
always 
	#5 clk = ~clk;

initial begin
    file = $fopen("ref_c/mnist.txt", "rb");
    f_rand = $fopen("lfsr.txt", "wb");
    f_pix = $fopen("pixel.txt", "wb");
    x_trace = $fopen("x_trace.txt", "wb");
    sout = $fopen("input_spike.txt", "wb");
end

initial begin
    reset_n = 1;
	clk = 0;
	i_init = 0;
	i_run = 0;
	i_rest_run = 0;
	stdp_run = 0;

status = $fscanf(file, "%d, ", pix);
	// reset_n gen
	$display("Reset! [%0d]", $time);
# 100
	reset_n = 0;
# 10
	reset_n = 1;
# 10
	@(posedge clk);

$display("Step 1. Mem write to BRAM [%0d]", $time);
	for(i=0; i<144; i=i+1) begin
		for(j=0; j<4; j=j+1) begin
			status = $fscanf(file, "%d, ", pix);
			img[j*8 +: 8] = pix;
		end
		u_SPBRAM.ram[i] = img;
	end

	i_init <= 1;
	@(posedge clk)
	i_init <= 0;
	wait(o_done);

	for(i=0; i<10; i=i+1) begin
		@(posedge clk);
	end

$display("Step 2. Start! [%0d]", $time);
for(i=0; i<800; i=i+1) begin
	i_run <= 1;
	@(posedge clk);
	i_run <= 0;
	
	for(j=0; j<144; j=j+1) begin
		@(posedge clk);
		for(k=0; k<4; k=k+1) begin
			$fwrite(f_pix, "%0d, ", u_LFSR.pixel[k*16 +: 16]);
			$fwrite(f_rand, "%0d, ", u_LFSR.rand[k*16 +: 16]);
		end
		$fwrite(f_pix, "\n");
		$fwrite(f_rand, "\n");
	end
	wait(o_done);
	@(posedge clk);
$display("Step 2. Valid! [%0d]", $time);
	stdp_run <= 1;
	@(posedge clk);
	stdp_run <= 0;

	wait(o_valid);
	@(posedge clk);
	for(j=0; j<24; j=j+1) begin
		for(k=0; k<24; k=k+1) begin
			$fwrite(sout, "%0d, ", o_spike_bundle[k]);
			$fwrite(x_trace, "%0d, ", o_trace[k*16 +: 16]);
		end
		@(posedge clk);
	end
	$fwrite(x_trace, "\n");
	$fwrite(sout, "\n");
	wait(o_done);
	@(posedge clk);
end
/*
for(i=0; i<500; i=i+1) begin
	i_rest_run = 1;
	@(posedge clk);
	i_rest_run = 0;

	wait(o_done);
	
	@(posedge clk);

	stdp_run = 1;
	@(posedge clk);
	stdp_run = 0;
	@(posedge clk);

	for(j=0; j<24; j=j+1) begin
		for(k=0; k<24; k=k+1) begin
			$fwrite(sout, "%0d, ", o_spike_bundle[k]);
			$fwrite(x_trace, "%0d, ", o_trace[k*16 +: 16]);
		end
		@(posedge clk);
	end
	$fwrite(x_trace, "\n");
	$fwrite(sout, "\n");
	
	wait(o_done);
	@(posedge clk);
end
*/



$fclose(file);
$fclose(f_pix);
$fclose(f_rand);
$fclose(x_trace);
$fclose(sout);

# 100
$display("Finish! [%0d]", $time);
$finish;
end

// Instantiate the LFSR module
lfsr u_LFSR (
    .clk (clk),
    .reset_n (reset_n),
    .i_run (i_run),
    .i_rest_run (i_rest_run),
	.o_spike (spike),
	.o_w_run (w_run),
	.o_valid (valid),

	.d (d),
	.addr (addr),
	.ce (ce),
	.we (we),
	.q (q)
);

preBuffer u_PREBUFFER (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_spike (spike),
	.i_b_run (w_run),
	.i_valid (valid),
	.i_stdp_run (stdp_run),
	.o_spike_bundle (o_spike_bundle),
	.o_valid (o_valid),
	.o_syn_run (o_syn_run),
	.o_trace (o_trace),
	.o_done (o_done)
);

spbram
#(
	.DWIDTH (32),
	.AWIDTH (8),
	.MEM_SIZE (144)
)
u_SPBRAM (
	.clk (clk),
	.addr (addr),
	.ce (ce),
	.we (we),
	.q (q),
	.d (d)
);

endmodule

