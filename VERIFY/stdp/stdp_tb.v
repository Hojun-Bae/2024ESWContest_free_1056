`timescale 1ns/1ps

module stdp_tb;

reg clk;
reg reset_n;
reg i_run;
reg i_sub;
reg [17:0] i_post_spike;
reg [23:0] i_pre_spike;

reg [287:0] i_y1_trace;
reg [287:0] i_y2_trace_buf;
reg [383:0] i_x_trace;

wire o_done;

wire [383:0] d_r;
wire [53:0] addr_r;
wire [5:0] ce_r;
wire [5:0] we_r;
wire [383:0] q_r;

wire [383:0] d_w;
wire [53:0] addr_w;
wire [5:0] ce_w;
wire [5:0] we_w;
wire [383:0] q_w;

reg [9215:0] x1;
reg [575:0] pre;
reg [383:0] a;
reg [15:0] tmp;
reg tmp2;

reg check;

// clk gen
always
    #5 clk = ~clk;

integer t, i, j, k, r, f_in_pre, f_in_post, f_in_wegt, f_in_x1, f_in_y1, f_in_y2_buf, status, f_ot_wegt;

initial
  begin
    f_in_pre = $fopen("./golden_ref/ref_c_rand_input_pre.txt","rb");
    f_in_post = $fopen("./golden_ref/ref_c_rand_input_post.txt","rb");
    f_in_wegt = $fopen("./golden_ref/ref_c_rand_input_wegt.txt","rb");
    f_in_x1 = $fopen("./golden_ref/ref_c_rand_input_x1.txt","rb");
    f_in_y1 = $fopen("./golden_ref/ref_c_rand_input_y1.txt","rb");
    f_in_y2_buf = $fopen("./golden_ref/ref_c_rand_input_y2_buf.txt","rb");
    f_ot_wegt = $fopen("./v_result.txt","wb");
  end

initial begin
	reset_n = 1;
	clk = 0;
	i_run = 0;
	i_sub = 0;
	i_post_spike = 0;
	i_pre_spike = 0;

	i_y1_trace = 0;
	i_y2_trace_buf= 0;
	i_x_trace = 0;
	
	check = 0;

	// reset_n gen
	$display("Reset! [%0d]", $time);
# 100
    reset_n = 0;
# 10
    reset_n = 1;
# 10
	@(posedge clk);

$display("Step 1. Mem write to BRAM0 [%0d]", $time);
	for(i=0; i<432; i=i+1) begin
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


$display("Step 3. Start! Synapse [%0d]", $time);
for(t=0; t<50; t=t+1) begin
	for(i=0; i<18; i=i+1) begin
		status = $fscanf(f_in_post, "%d", tmp2);
		i_post_spike[i] <= tmp2;
		status = $fscanf(f_in_y1, "%d", tmp);
		i_y1_trace[16*i +: 16] <= tmp;
		status = $fscanf(f_in_y2_buf, "%d", tmp);
		i_y2_trace_buf[16*i +: 16] <= tmp;
	end

	for(i=0; i<576; i=i+1) begin
		status = $fscanf(f_in_pre, "%d", tmp2);
		pre[i] <= tmp2;
		status = $fscanf(f_in_x1, "%d", tmp);
		x1[16*i +: 16] <= tmp;
	end
	@(posedge clk);
	@(posedge clk);
	i_run <= 1;
	if(t%10 == 9)
		i_sub <= 1;
	@(posedge clk);
	i_run <= 0;
	i_sub <= 0;
	@(posedge clk);
	
	for(i=0; i<18; i=i+1) begin
		for(j=0; j<24; j=j+1) begin
			i_pre_spike <= pre[24*j +: 24];
			i_x_trace <= x1[384*j +: 384];
			check <= 1;	
			@(posedge clk);
		end
	end
	check <= 0;	

	wait(o_done);
	@(posedge clk);

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
end

for(i=0; i<10; i=i+1) begin
	@(posedge clk);
end

$fclose(f_in_pre);
$fclose(f_in_post);
$fclose(f_in_y1);
$fclose(f_in_y2_buf);
$fclose(f_in_x1);
$fclose(f_in_wegt);
$fclose(f_ot_wegt);
# 100
$display("Success Simulation!! [%0d]", $time);
$finish;
end

// Call DUT
stdp dut_stdp (
	.clk (clk),
	.reset_n (reset_n),
	.i_run (i_run),
	.i_sub (i_sub),
	.i_post_spike (i_post_spike),
	.i_pre_spike (i_pre_spike),
	
	.i_y1_trace (i_y1_trace),
	.i_y2_trace_buf (i_y2_trace_buf),
	.i_x_trace (i_x_trace),
	
	.o_done (o_done),

	// BRAM I/F
	.d_r (d_r),
	.addr_r (addr_r),
	.ce_r (ce_r),
	.we_r (we_r),
	.q_r (q_r),

	.d_w (d_w),
	.addr_w (addr_w),
	.ce_w (ce_w),
	.we_w (we_w),
	.q_w (q_w)
);

dpbram
#(	
	.DWIDTH (64),
	.AWIDTH (9),
	.MEM_SIZE (432)
)
u_TDPBRAM_0(
	.clk		(clk),

	.addr0		(addr_r[8:0]),
	.ce0		(ce_r[0]),
	.we0		(we_r[0]),
	.q0			(q_r[63:0]),
	.d0			(d_r[63:0]), 
	
	.addr1		(addr_w[8:0]),
	.ce1		(ce_w[0]),
	.we1		(we_w[0]),
	.q1			(q_w[63:0]),
	.d1			(d_w[63:0]) 
);

dpbram
#(	
	.DWIDTH (64),
	.AWIDTH (9),
	.MEM_SIZE (432)
)
u_TDPBRAM_1(
	.clk		(clk),

	.addr0		(addr_r[17:9]),
	.ce0		(ce_r[1]),
	.we0		(we_r[1]),
	.q0			(q_r[127:64]),
	.d0			(d_r[127:64]), 
	
	.addr1		(addr_w[17:9]),
	.ce1		(ce_w[1]),
	.we1		(we_w[1]),
	.q1			(q_w[127:64]),
	.d1			(d_w[127:64]) 
);

dpbram
#(	
	.DWIDTH (64),
	.AWIDTH (9),
	.MEM_SIZE (432)
)
u_TDPBRAM_2(
	.clk		(clk),

	.addr0		(addr_r[26:18]),
	.ce0		(ce_r[2]),
	.we0		(we_r[2]),
	.q0			(q_r[191:128]),
	.d0			(d_r[191:128]), 
	
	.addr1		(addr_w[26:18]),
	.ce1		(ce_w[2]),
	.we1		(we_w[2]),
	.q1			(q_w[191:128]),
	.d1			(d_w[191:128]) 
);

dpbram
#(	
	.DWIDTH (64),
	.AWIDTH (9),
	.MEM_SIZE (432)
)
u_TDPBRAM_3(
	.clk		(clk),

	.addr0		(addr_r[35:27]),
	.ce0		(ce_r[3]),
	.we0		(we_r[3]),
	.q0			(q_r[255:192]),
	.d0			(d_r[255:192]), 
	
	.addr1		(addr_w[35:27]),
	.ce1		(ce_w[3]),
	.we1		(we_w[3]),
	.q1			(q_w[255:192]),
	.d1			(d_w[255:192]) 
);

dpbram
#(	
	.DWIDTH (64),
	.AWIDTH (9),
	.MEM_SIZE (432)
)
u_TDPBRAM_4(
	.clk		(clk),

	.addr0		(addr_r[44:36]),
	.ce0		(ce_r[4]),
	.we0		(we_r[4]),
	.q0			(q_r[319:256]),
	.d0			(d_r[319:256]), 
	
	.addr1		(addr_w[44:36]),
	.ce1		(ce_w[4]),
	.we1		(we_w[4]),
	.q1			(q_w[319:256]),
	.d1			(d_w[319:256]) 
);

dpbram
#(	
	.DWIDTH (64),
	.AWIDTH (9),
	.MEM_SIZE (432)
)
u_TDPBRAM_5(
	.clk		(clk),

	.addr0		(addr_r[53:45]),
	.ce0		(ce_r[5]),
	.we0		(we_r[5]),
	.q0			(q_r[383:320]),
	.d0			(d_r[383:320]), 
	
	.addr1		(addr_w[53:45]),
	.ce1		(ce_w[5]),
	.we1		(we_w[5]),
	.q1			(q_w[383:320]),
	.d1			(d_w[383:320]) 
);


endmodule
