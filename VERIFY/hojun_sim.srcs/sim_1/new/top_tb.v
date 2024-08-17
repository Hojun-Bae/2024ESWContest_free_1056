`timescale 1ns/1ps

module top_tb;

reg clk;
reg reset_n;
reg i_init;
reg i_lern;
reg i_infr;

wire o_run;
wire o_init;
wire o_rest_run;
wire o_stdp_run;
wire o_cnt_en;
wire o_cnt_clr;
wire o_s_lern;
wire o_s_infr;
wire o_sub;
wire o_s_stdp;
wire o_s_idle;
wire o_s_running;
wire o_s_done;

wire [7:0] o_syn_done;
wire [7:0] o_inh_valid;
wire [7:0] o_stdp_done;
wire [7:0] o_winner;

wire [31:0] d;
wire [7:0] addr;
wire ce;
wire we;
wire [31:0] q;
//////////////////////////////

integer file, x_trace, sout, f_vm, f_vt, f_ge, f_gi, f_y1, f_y2, f_acc, i, j, k, n, status;

reg [7:0] pix;
reg [31:0] img;
reg [25*18-1:0] acc_reg [7:0];
// Clock generation
always 
	#5 clk = ~clk;

initial begin
    file = $fopen("mnist.txt", "rb");
    x_trace = $fopen("x_trace.csv", "wb");
    sout = $fopen("input_spike.csv", "wb");
	f_vm = $fopen("exc_membrane.csv", "wb");
	f_vt = $fopen("exc_threshold.csv", "wb");
	f_ge = $fopen("exc_conductance.csv", "wb");
	f_gi = $fopen("inh_conductance.csv", "wb");
	f_y1 = $fopen("y1_trace.csv", "wb");
	f_y2 = $fopen("y2_trace_buf.csv", "wb");
	f_acc = $fopen("acc.csv", "wb");
end

initial begin
    reset_n = 1;
	clk = 0;
	i_init = 0;
	i_lern = 0;
	i_infr = 0;

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
	wait(o_syn_done);

	
	for(i=0; i<10; i=i+1) begin
		@(posedge clk);
	end

$display("Step 2. Start! [%0d]", $time);
for(n=0; n<30; n=n+1) begin
	status = $fscanf(file, "%d, ", pix);
	for(i=0; i<144; i=i+1) begin
		for(j=0; j<4; j=j+1) begin
			status = $fscanf(file, "%d, ", pix);
			img[j*8 +: 8] = pix;
		end
		u_img.ram[i] = img;
	end
		
		for(i=0; i<10; i=i+1) begin
			@(posedge clk);
		end
	
		i_lern <= 1;
		@(posedge clk);
		i_lern <= 0;
	for(i=0; i<1300; i=i+1) begin
		wait(o_inh_valid);
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_0.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_0.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_0.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_0.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_0.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_0.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[0][k*25 +: 25]);
		end
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_1.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_1.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_1.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_1.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_1.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_1.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[1][k*25 +: 25]);
		end
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_2.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_2.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_2.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_2.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_2.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_2.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[2][k*25 +: 25]);
		end
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_3.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_3.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_3.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_3.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_3.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_3.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[3][k*25 +: 25]);
		end
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_4.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_4.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_4.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_4.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_4.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_4.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[4][k*25 +: 25]);
		end
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_5.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_5.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_5.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_5.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_5.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_5.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[5][k*25 +: 25]);
		end
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_6.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_6.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_6.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_6.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_6.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_6.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[6][k*25 +: 25]);
		end
		for(k=0; k<18; k=k+1) begin
			$fwrite(f_vm, "%0d, ", u_top.u_sub_top_7.u_NRNST_SPBRAM.ram[k][49:25]);
			$fwrite(f_vt, "%0d, ", u_top.u_sub_top_7.u_NRNST_SPBRAM.ram[k][24:0]);
			$fwrite(f_ge, "%0d, ", u_top.u_sub_top_7.u_CDTC_SPBRAM.ram[k][49:25]);
			$fwrite(f_gi, "%0d, ", u_top.u_sub_top_7.u_CDTC_SPBRAM.ram[k][24:0]);
			$fwrite(f_y1, "%0d, ", u_top.u_sub_top_7.nrn_y1_trace[k*16 +: 16]);
			$fwrite(f_y2, "%0d, ", u_top.u_sub_top_7.nrn_y2_trace_buf[k*16 +: 16]);
			$fwrite(f_acc, "%0d, ", acc_reg[7][k*25 +: 25]);
		end
	
		wait(o_s_stdp);
		wait(u_top.u_PREBUFFER.o_valid);
		for(j=0; j<24; j=j+1) begin
			@(posedge clk);
			for(k=0; k<24; k=k+1) begin
				$fwrite(sout, "%0d, ", u_top.o_spike_bundle[k]);
				$fwrite(x_trace, "%0d, ", u_top.o_trace[k*16 +: 16]);
			end
		end
		$fwrite(x_trace, "\n");
		$fwrite(sout, "\n");
		$fwrite(f_vm, "\n");
		$fwrite(f_vt, "\n");
		$fwrite(f_ge, "\n");
		$fwrite(f_gi, "\n");
		$fwrite(f_y1, "\n");
		$fwrite(f_y2, "\n");
		$fwrite(f_acc, "\n");
		
		wait(o_stdp_done);
	end
		wait(o_cnt_clr);
	
	for(i=0; i<100; i=i+1) begin
		@(posedge clk);
	end
end

$fclose(file);
$fclose(x_trace);
$fclose(sout);
$fclose(f_vm);
$fclose(f_vt);
$fclose(f_ge);
$fclose(f_gi);
$fclose(f_y1);
$fclose(f_y2);
$fclose(f_acc);

# 100
$display("Finish! [%0d]", $time);
$finish;
end

reg r_done; // to keep done status, i_done is a 1 tick.
reg [7:0] r_winner; // to keep done status, i_done is a 1 tick.

always @(posedge clk) begin
   	if(!reset_n) begin  // sync reset_n
   	    r_done <= 1'b0;
		r_winner <= 8'd0;
   	end else if (o_s_done) begin
   	    r_done <= 1'b1;
		r_winner <= o_winner;
	end else if (i_init || i_lern || i_infr) begin
		r_done <= 1'b0;
		r_winner <= 8'd0;
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[0] <= 0;
	end else begin
		if(u_top.u_sub_top_0.syn_valid) begin
			acc_reg[0] <= {u_top.u_sub_top_0.syn_current, acc_reg[0][25*18-1:25]};
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[1] <= 0;
	end else begin
		if(u_top.u_sub_top_1.syn_valid) begin
			acc_reg[1] <= {u_top.u_sub_top_1.syn_current, acc_reg[1][25*18-1:25]};
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[2] <= 0;
	end else begin
		if(u_top.u_sub_top_2.syn_valid) begin
			acc_reg[2] <= {u_top.u_sub_top_2.syn_current, acc_reg[2][25*18-1:25]};
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[3] <= 0;
	end else begin
		if(u_top.u_sub_top_3.syn_valid) begin
			acc_reg[3] <= {u_top.u_sub_top_3.syn_current, acc_reg[3][25*18-1:25]};
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[4] <= 0;
	end else begin
		if(u_top.u_sub_top_4.syn_valid) begin
			acc_reg[4] <= {u_top.u_sub_top_4.syn_current, acc_reg[4][25*18-1:25]};
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[5] <= 0;
	end else begin
		if(u_top.u_sub_top_5.syn_valid) begin
			acc_reg[5] <= {u_top.u_sub_top_5.syn_current, acc_reg[5][25*18-1:25]};
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[6] <= 0;
	end else begin
		if(u_top.u_sub_top_6.syn_valid) begin
			acc_reg[6] <= {u_top.u_sub_top_6.syn_current, acc_reg[6][25*18-1:25]};
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		acc_reg[7] <= 0;
	end else begin
		if(u_top.u_sub_top_7.syn_valid) begin
			acc_reg[7] <= {u_top.u_sub_top_7.syn_current, acc_reg[7][25*18-1:25]};
		end
	end
end

	
top u_top (
	.clk (clk),
	.reset_n (reset_n),
	.i_run (o_run),
	.i_rest_run (o_rest_run),
	.i_stdp_run (o_stdp_run),
	.i_init (o_init),
	.i_cnt_en (o_cnt_en),
	.i_cnt_clr (o_cnt_clr),
	.i_s_lern (o_s_lern),
	.i_s_infr (o_s_infr),
	.i_sub (o_sub),
	.i_s_stdp (o_s_stdp),

	.o_syn_done (o_syn_done),
	.o_inh_valid (o_inh_valid),
	.o_stdp_done (o_stdp_done),
	.o_winner (o_winner),

	.d (d),
	.addr (addr),
	.ce (ce),
	.we (we),
	.q (q)
);

controller u_controller (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_lern (i_lern),
	.i_infr  (i_infr),

	.i_syn_done (o_syn_done),
	.i_inh_valid (o_inh_valid),
	.i_stdp_done (o_stdp_done),

	.o_run (o_run),
	.o_init (o_init),
	.o_rest_run (o_rest_run),
	.o_stdp_run (o_stdp_run),
	.o_cnt_en (o_cnt_en),
	.o_cnt_clr (o_cnt_clr),
	.o_s_lern (o_s_lern),
	.o_s_infr (o_s_infr),
	.o_sub (o_sub),
	.o_s_stdp (o_s_stdp),
	.o_s_idle (o_s_idle),
	.o_s_running (o_s_running),
	.o_s_done (o_s_done)
);

(* dont_touch = "true" *) spbram
#(
	.DWIDTH (32),
	.AWIDTH (8),
	.MEM_SIZE (144)
)
u_img (
	.clk (clk),
	.addr (addr),
	.ce (ce),
	.we (we),
	.q (q),
	.d (d)
);


endmodule
