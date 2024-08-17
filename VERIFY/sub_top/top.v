`timescale 1ns/1ps

module top (
	input clk,
	input reset_n,
	input i_run,
	input i_rest_run,
	input i_stdp_run,
	input i_init,
	input i_cnt_clr,
	input i_s_lern,
	input i_s_infr,
	input i_sub,
	input i_s_stdp,

	output [7:0] o_syn_done,
	output [7:0] o_inh_valid,
	output [7:0] o_stdp_done,
	output [7:0] o_winner,
	output o_winner_valid
);

///////////////////////////////
// LFSR
(* dont_touch = "true" *) wire [3:0] spike;
(* dont_touch = "true" *) wire w_run;
(* dont_touch = "true" *) wire valid;

// Image BRAM I/F
(* dont_touch = "true" *) wire [31:0] d;
(* dont_touch = "true" *) wire [7:0] addr;
(* dont_touch = "true" *) wire ce;
(* dont_touch = "true" *) wire we;
(* dont_touch = "true" *) wire [31:0] q;
///////////////////////////////

///////////////////////////////
// PREBUFFER
(* dont_touch = "true" *) wire [23:0] o_spike_bundle;
(* dont_touch = "true" *) wire o_valid;
(* dont_touch = "true" *) wire o_syn_run;
(* dont_touch = "true" *) wire [383:0] o_trace;
(* dont_touch = "true" *) wire o_done;

(* dont_touch = "true" *) wire [63:0] d_r;
(* dont_touch = "true" *) wire [4:0] addr_r;
(* dont_touch = "true" *) wire [5:0] ce_r;
(* dont_touch = "true" *) wire [5:0] we_r;
(* dont_touch = "true" *) wire [383:0] q_r;

(* dont_touch = "true" *) wire [63:0] d_w;
(* dont_touch = "true" *) wire [4:0] addr_w;
(* dont_touch = "true" *) wire [5:0] ce_w;
(* dont_touch = "true" *) wire [5:0] we_w;
(* dont_touch = "true" *) wire [383:0] q_w;
///////////////////////////////

///////////////////////////////
// SUB_TOP

(* dont_touch = "true" *) wire signed [24:0] o_inhbt [7:0] ;
(* dont_touch = "true" *) wire [125:0] o_post_cnt [7:0];
//////////////////////////////

//////////////////////////////
// Find Max
(* dont_touch = "true" *) wire chck_en = 1'b1;
(* dont_touch = "true" *) wire [39:0] o_idx;
(* dont_touch = "true" *) wire [55:0] o_max;
(* dont_touch = "true" *) wire [7:0] o_chck_valid;

reg [4:0] neuron_idx;

(* dont_touch = "true" *) wire [4:0] oo_idx;
(* dont_touch = "true" *) wire [6:0] oo_max;
(* dont_touch = "true" *) wire oo_chck_valid;
(* dont_touch = "true" *) wire [7:0] winner = {oo_idx[3:0], 4'b0} + {2'b0, oo_idx, 1'b0} + neuron_idx;

assign o_winner = winner;
assign o_winner_valid = oo_chck_valid;
//////////////////////////////

localparam S_IDLE = 2'b00;
localparam S_INIT = 2'b01;
localparam S_DONE = 2'b10;

reg [1:0] cs;
reg [1:0] ns;
reg [4:0] init_addr;

(* dont_touch = "true" *) wire s_init;
(* dont_touch = "true" *) wire s_done;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cs <= S_IDLE;
	end else begin
		cs <= ns;
	end
end

always @(*) begin
	ns = cs;
	case(cs)
		S_IDLE:
			if(i_init)
				ns = S_INIT;
		S_INIT:
			if(init_addr == 5'd23)
				ns = S_DONE;
		S_DONE:
			ns = S_IDLE;
	endcase
end

assign s_init = (cs == S_INIT);
assign s_done = (cs == S_DONE);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		init_addr <= 5'd0;
	end else begin
		if(s_init) begin
			init_addr <= init_addr + 5'd1;
		end else if(s_done) begin
			init_addr <= 5'd0;
		end else begin 
			init_addr <= init_addr;
		end
	end
end

(* dont_touch = "true" *) wire [63:0] d_ = s_init ? 64'd0 : d_r;
(* dont_touch = "true" *) wire [4:0] addr_ = s_init ? init_addr : addr_r;
(* dont_touch = "true" *) wire [5:0] ce_ = s_init ? 6'h3f : ce_r; 
(* dont_touch = "true" *) wire [5:0] we_ = s_init ? 6'h3f : we_r; 


genvar max_idx;
generate
	for(max_idx=0; max_idx<8; max_idx=max_idx+1) begin : gen_max
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				neuron_idx <= 5'd0;
			end else begin
				case(oo_idx)
					max_idx:
						neuron_idx <= o_idx[max_idx*5 +: 5];
				endcase
			end
		end
	end
endgenerate

///////////////////////////////////////////////////////

reg signed [24:0] inh;
(* dont_touch = "true" *) wire signed [24:0] inh_sum = o_inhbt[0] + o_inhbt[1] + o_inhbt[2] + o_inhbt[3] + o_inhbt[4] + o_inhbt[5] + o_inhbt[6] + o_inhbt[7];
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		inh <= 25'd0;
	end else begin
		if(o_inh_valid == 8'hff) begin
			inh <= (inh_sum > 25'd655360) ? 25'd655360 : inh_sum;
		end else begin
			inh <= inh;
		end
	end
end

// Instantiate the LFSR module
(* dont_touch = "true" *) lfsr u_LFSR (
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

(* dont_touch = "true" *) preBuffer u_PREBUFFER (
	.clk (clk),
	.reset_n (reset_n),
	.i_spike (spike),
	.i_b_run (w_run),
	.i_valid (valid),
	.i_stdp_run (i_stdp_run),
	.o_spike_bundle (o_spike_bundle),
	.o_valid (o_valid),
	.o_syn_run (o_syn_run),
	.o_trace (o_trace),
	.o_done (o_done),

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

(* dont_touch = "true" *) spbram
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

(* dont_touch = "true" *) dpbram
#(
	.DWIDTH (64),
	.AWIDTH (5),
	.MEM_SIZE (24)
)
u_DPBRAM_0 (
	.clk (clk),
	.addr0 (addr_),
	.ce0 (ce_[0]),
	.we0 (we_[0]),
	.q0 (q_r[0*64 +: 64]),
	.d0 (d_),
	
	.addr1 (addr_w),
	.ce1 (ce_w[0]),
	.we1 (we_w[0]),
	.q1 (q_w[0*64 +: 64]),
	.d1 (d_w)
);

(* dont_touch = "true" *) dpbram
#(
	.DWIDTH (64),
	.AWIDTH (5),
	.MEM_SIZE (24)
)
u_DPBRAM_1 (
	.clk (clk),
	.addr0 (addr_),
	.ce0 (ce_[1]),
	.we0 (we_[1]),
	.q0 (q_r[1*64 +: 64]),
	.d0 (d_),
	
	.addr1 (addr_w),
	.ce1 (ce_w[1]),
	.we1 (we_w[1]),
	.q1 (q_w[1*64 +: 64]),
	.d1 (d_w)
);

(* dont_touch = "true" *) dpbram
#(
	.DWIDTH (64),
	.AWIDTH (5),
	.MEM_SIZE (24)
)
u_DPBRAM_2 (
	.clk (clk),
	.addr0 (addr_),
	.ce0 (ce_[2]),
	.we0 (we_[2]),
	.q0 (q_r[2*64 +: 64]),
	.d0 (d_),
	
	.addr1 (addr_w),
	.ce1 (ce_w[2]),
	.we1 (we_w[2]),
	.q1 (q_w[2*64 +: 64]),
	.d1 (d_w)
);

(* dont_touch = "true" *) dpbram
#(
	.DWIDTH (64),
	.AWIDTH (5),
	.MEM_SIZE (24)
)
u_DPBRAM_3 (
	.clk (clk),
	.addr0 (addr_),
	.ce0 (ce_[3]),
	.we0 (we_[3]),
	.q0 (q_r[3*64 +: 64]),
	.d0 (d_),
	
	.addr1 (addr_w),
	.ce1 (ce_w[3]),
	.we1 (we_w[3]),
	.q1 (q_w[3*64 +: 64]),
	.d1 (d_w)
);

(* dont_touch = "true" *) dpbram
#(
	.DWIDTH (64),
	.AWIDTH (5),
	.MEM_SIZE (24)
)
u_DPBRAM_4 (
	.clk (clk),
	.addr0 (addr_),
	.ce0 (ce_[4]),
	.we0 (we_[4]),
	.q0 (q_r[4*64 +: 64]),
	.d0 (d_),
	
	.addr1 (addr_w),
	.ce1 (ce_w[4]),
	.we1 (we_w[4]),
	.q1 (q_w[4*64 +: 64]),
	.d1 (d_w)
);

(* dont_touch = "true" *) dpbram
#(
	.DWIDTH (64),
	.AWIDTH (5),
	.MEM_SIZE (24)
)
u_DPBRAM_5 (
	.clk (clk),
	.addr0 (addr_),
	.ce0 (ce_[5]),
	.we0 (we_[5]),
	.q0 (q_r[5*64 +: 64]),
	.d0 (d_),
	
	.addr1 (addr_w),
	.ce1 (ce_w[5]),
	.we1 (we_w[5]),
	.q1 (q_w[5*64 +: 64]),
	.d1 (d_w)
);

(* dont_touch = "true" *) sub_top #(.SEED (1*1000))
u_sub_top_0 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[0]),

	.o_stdp_done (o_stdp_done[0]),

	.o_inhbt (o_inhbt[0]),
	.o_post_cnt (o_post_cnt[0]),
	.o_inh_valid (o_inh_valid[0])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_0 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[0]),
	.o_idx (o_idx[0*5 +: 5]),
	.o_max (o_max[0*7 +: 7]),
	.o_valid (o_chck_valid[0])
);

(* dont_touch = "true" *) sub_top #(.SEED (2*1000))
u_sub_top_1 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[1]),

	.o_stdp_done (o_stdp_done[1]),

	.o_inhbt (o_inhbt[1]),
	.o_post_cnt (o_post_cnt[1]),
	.o_inh_valid (o_inh_valid[1])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_1 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[1]),
	.o_idx (o_idx[1*5 +: 5]),
	.o_max (o_max[1*7 +: 7]),
	.o_valid (o_chck_valid[1])
);

(* dont_touch = "true" *) sub_top #(.SEED (3*1000))
u_sub_top_2 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[2]),

	.o_stdp_done (o_stdp_done[2]),

	.o_inhbt (o_inhbt[2]),
	.o_post_cnt (o_post_cnt[2]),
	.o_inh_valid (o_inh_valid[2])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_2 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[2]),
	.o_idx (o_idx[2*5 +: 5]),
	.o_max (o_max[2*7 +: 7]),
	.o_valid (o_chck_valid[2])
);

(* dont_touch = "true" *) sub_top #(.SEED (4*1000))
u_sub_top_3 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[3]),

	.o_stdp_done (o_stdp_done[3]),

	.o_inhbt (o_inhbt[3]),
	.o_post_cnt (o_post_cnt[3]),
	.o_inh_valid (o_inh_valid[3])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_3 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[3]),
	.o_idx (o_idx[3*5 +: 5]),
	.o_max (o_max[3*7 +: 7]),
	.o_valid (o_chck_valid[3])
);

(* dont_touch = "true" *) sub_top #(.SEED (5*1000))
u_sub_top_4 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[4]),

	.o_stdp_done (o_stdp_done[4]),

	.o_inhbt (o_inhbt[4]),
	.o_post_cnt (o_post_cnt[4]),
	.o_inh_valid (o_inh_valid[4])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_4 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[4]),
	.o_idx (o_idx[4*5 +: 5]),
	.o_max (o_max[4*7 +: 7]),
	.o_valid (o_chck_valid[4])
);

(* dont_touch = "true" *) sub_top #(.SEED (6*1000))
u_sub_top_5 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[5]),

	.o_stdp_done (o_stdp_done[5]),

	.o_inhbt (o_inhbt[5]),
	.o_post_cnt (o_post_cnt[5]),
	.o_inh_valid (o_inh_valid[5])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_5 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[5]),
	.o_idx (o_idx[5*5 +: 5]),
	.o_max (o_max[5*7 +: 7]),
	.o_valid (o_chck_valid[5])
);

(* dont_touch = "true" *) sub_top #(.SEED (7*1000))
u_sub_top_6 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[6]),

	.o_stdp_done (o_stdp_done[6]),

	.o_inhbt (o_inhbt[6]),
	.o_post_cnt (o_post_cnt[6]),
	.o_inh_valid (o_inh_valid[6])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_6 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[6]),
	.o_idx (o_idx[6*5 +: 5]),
	.o_max (o_max[6*7 +: 7]),
	.o_valid (o_chck_valid[6])
);

(* dont_touch = "true" *) sub_top #(.SEED (8*1000))
u_sub_top_7 (
	.clk (clk),
	.reset_n (reset_n),
	.i_init (i_init),
	.i_cnt_clr (i_cnt_clr),
	.i_syn_run (o_syn_run),

	.i_s_lern (i_s_lern),
	.i_s_infr (i_s_infr),

	.i_stdp_run (i_stdp_run),
	.i_sub (i_sub),
	.i_x_trace (o_trace),
	.i_s_stdp (i_s_stdp),

	.i_spike_bundle (o_spike_bundle),
	.i_valid (o_valid),

	.i_inhbt (inh),

	.o_syn_done (o_syn_done[7]),

	.o_stdp_done (o_stdp_done[7]),

	.o_inhbt (o_inhbt[7]),
	.o_post_cnt (o_post_cnt[7]),
	.o_inh_valid (o_inh_valid[7])
);
(* dont_touch = "true" *) findMax #(.NUM (18))
u_findMax_7 (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_post_cnt[7]),
	.o_idx (o_idx[7*5 +: 5]),
	.o_max (o_max[7*7 +: 7]),
	.o_valid (o_chck_valid[7])
);

(* dont_touch = "true" *) findMax #(.NUM (8))
u_findMaxTop (
	.clk (clk),
	.reset_n (reset_n),
	.en (chck_en),
	.i_cnt (o_max),
	.o_idx (oo_idx),
	.o_max (oo_max),
	.o_valid (oo_chck_valid)
);

endmodule

