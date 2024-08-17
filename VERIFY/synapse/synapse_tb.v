`timescale 1ns/1ps

module synapse_tb;

`define BRAM_W_DATA_WIDTH 64
`define BRAM_W_ADDR_WIDTH 9
`define BRAM_W_MEM_DEPTH 432
`define WEIGHT_WIDTH 16

reg clk;
reg reset_n;
reg i_run;
reg i_wegt_rst;
wire [24:0] o_current;
wire o_valid;
wire o_done;
wire o_is_single_done;

wire [383:0] d;
wire [53:0] addr;
wire [5:0] ce;
wire [5:0] we;
wire [383:0] q;

reg [31:0] spike[0:431];
reg [23:0] i_spike_bundle;
reg  i_valid;

reg [383:0] a;
reg [23:0] b;
reg [15:0] tmp;
reg tmp2;

// clk gen
always
    #5 clk = ~clk;

integer i, j, f_in_node, f_in_wegt, status, f_ot_wegt;

initial
  begin
    f_in_node = $fopen("./golden_ref/ref_c_rand_input_node.txt","rb");
    f_in_wegt = $fopen("./golden_ref/ref_c_rand_input_wegt.txt","rb");
    f_ot_wegt = $fopen("./init_weight.txt","wb");
  end

initial begin
	reset_n = 1;
	clk = 0;
	i_run = 0;
	i_wegt_rst = 0;
	i_spike_bundle = 24'd0;
	i_valid = 0;

	// reset_n gen
	$display("Reset! [%0d]", $time);
# 100
    reset_n = 0;
# 10
    reset_n = 1;
# 10
	@(posedge clk);

$display("Step 1. Mem write to BRAM0 [%0d]", $time);
	for(i = 0; i < `BRAM_W_MEM_DEPTH; i = i + 1) begin
		for(j=0; j<24; j=j+1) begin
			status = $fscanf(f_in_wegt, "%d", tmp);
			a[16*j +: 16] = tmp;
		end
		u_TDPBRAM_0.ram[i] = a[64*0 +: 64];
		u_TDPBRAM_1.ram[i] = a[64*1 +: 64];
		u_TDPBRAM_2.ram[i] = a[64*2 +: 64];
		u_TDPBRAM_3.ram[i] = a[64*3 +: 64];
		u_TDPBRAM_4.ram[i] = a[64*4 +: 64];
		u_TDPBRAM_5.ram[i] = a[64*5 +: 64];
	end
	for(i=0; i<`BRAM_W_MEM_DEPTH; i=i+1) begin
		for(j=0; j<24; j=j+1) begin
			status = $fscanf(f_in_node,"%d", tmp2);
			b[j] = tmp2;
		end
		spike[i] = b;	
	end
	

$display("Step 3. Start! Synapse [%0d]", $time);
	i_run <= 1;
@(posedge clk);
	i_run <= 0;
@(posedge clk);
	i_valid = 1;
for(i = 0; i < 432; i = i + 1) begin
	for(j=0; j<6; j=j+1) begin
		i_spike_bundle[4*j +: 4] <= {spike[i][4*j+3], spike[i][4*j+2], spike[i][4*j+1], spike[i][4*j+0]};
	end
	@(posedge clk);
end

	i_valid <= 0;

$display("Step 4. Wait Done [%0d]", $time);
	wait(o_done);

for(i=0; i<10; i=i+1) begin
	@(posedge clk);
end

$display("Step 5. Weight reset [%0d]", $time);
	i_wegt_rst <= 1;
@(posedge clk);
	i_wegt_rst <= 0;
@(posedge clk);

$display("Step 6. Wait Done [%0d]", $time);
	wait(o_done);

for(i=0; i<432; i=i+1) begin
	for(j=0; j<4; j=j+1) begin
		$fwrite(f_ot_wegt, "%0d\n", u_TDPBRAM_0.ram[i][j*16 +: 16]);
	end
	for(j=0; j<4; j=j+1) begin
		$fwrite(f_ot_wegt, "%0d\n", u_TDPBRAM_1.ram[i][j*16 +: 16]);
	end
	for(j=0; j<4; j=j+1) begin
		$fwrite(f_ot_wegt, "%0d\n", u_TDPBRAM_2.ram[i][j*16 +: 16]);
	end
	for(j=0; j<4; j=j+1) begin
		$fwrite(f_ot_wegt, "%0d\n", u_TDPBRAM_3.ram[i][j*16 +: 16]);
	end
	for(j=0; j<4; j=j+1) begin
		$fwrite(f_ot_wegt, "%0d\n", u_TDPBRAM_4.ram[i][j*16 +: 16]);
	end
	for(j=0; j<4; j=j+1) begin
		$fwrite(f_ot_wegt, "%0d\n", u_TDPBRAM_5.ram[i][j*16 +: 16]);
	end
end

$fclose(f_in_node);
$fclose(f_in_wegt);
$fclose(f_ot_wegt);
# 100
$display("Success Simulation!! [%0d]", $time);
$finish;
end

// Call DUT
synapse dut_synapse (
	.clk (clk),
	.reset_n (reset_n),
	.i_run (i_run),
	.i_wegt_rst (i_wegt_rst),
	.o_current (o_current),
	.o_valid (o_valid),
	.o_is_single_done (o_is_single_done),
	.o_done (o_done),

	// BRAM I/F
	.d (d),
	.addr (addr),
	.ce (ce),
	.we (we),
	.q (q),

	.i_spike_bundle (i_spike_bundle),
	.i_valid (i_valid)
);

spbram
#(	
	.DWIDTH (`BRAM_W_DATA_WIDTH),
	.AWIDTH (`BRAM_W_ADDR_WIDTH),
	.MEM_SIZE (`BRAM_W_MEM_DEPTH)
)
u_TDPBRAM_0(
	.clk		(clk),

	.addr		(addr[8:0]),
	.en			(ce[0]),
	.we			(we[0]),
	.q			(q[63:0]),
	.d			(d[63:0]) 
);

spbram
#(	
	.DWIDTH (`BRAM_W_DATA_WIDTH),
	.AWIDTH (`BRAM_W_ADDR_WIDTH),
	.MEM_SIZE (`BRAM_W_MEM_DEPTH)
)
u_TDPBRAM_1(
	.clk		(clk),

	.addr		(addr[17:9]),
	.en			(ce[1]),
	.we			(we[1]),
	.q			(q[127:64]),
	.d			(d[127:64]) 
);

spbram
#(	
	.DWIDTH (`BRAM_W_DATA_WIDTH),
	.AWIDTH (`BRAM_W_ADDR_WIDTH),
	.MEM_SIZE (`BRAM_W_MEM_DEPTH)
)
u_TDPBRAM_2(
	.clk		(clk),

	.addr		(addr[26:18]),
	.en			(ce[2]),
	.we			(we[2]),
	.q			(q[191:128]),
	.d			(d[191:128]) 
);

spbram
#(	
	.DWIDTH (`BRAM_W_DATA_WIDTH),
	.AWIDTH (`BRAM_W_ADDR_WIDTH),
	.MEM_SIZE (`BRAM_W_MEM_DEPTH)
)
u_TDPBRAM_3(
	.clk		(clk),

	.addr		(addr[35:27]),
	.en			(ce[3]),
	.we			(we[3]),
	.q			(q[255:192]),
	.d			(d[255:192]) 
);

spbram
#(	
	.DWIDTH (`BRAM_W_DATA_WIDTH),
	.AWIDTH (`BRAM_W_ADDR_WIDTH),
	.MEM_SIZE (`BRAM_W_MEM_DEPTH)
)
u_TDPBRAM_4(
	.clk		(clk),

	.addr		(addr[44:36]),
	.en			(ce[4]),
	.we			(we[4]),
	.q			(q[319:256]),
	.d			(d[319:256]) 
);

spbram
#(	
	.DWIDTH (`BRAM_W_DATA_WIDTH),
	.AWIDTH (`BRAM_W_ADDR_WIDTH),
	.MEM_SIZE (`BRAM_W_MEM_DEPTH)
)
u_TDPBRAM_5(
	.clk		(clk),

	.addr		(addr[53:45]),
	.en			(ce[5]),
	.we			(we[5]),
	.q			(q[383:320]),
	.d			(d[383:320]) 
);

endmodule
