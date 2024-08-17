`timescale 1ns/1ps

module top (
	input 					clk				,
	input 					rst_n			,
	input 					i_run			,
	input 					i_rest_run		,
	input 					i_stdp_run		,
	input 					i_init			,
	input 					i_cnt_en		,
	input 					i_cnt_clr		,
	input 					i_s_lern		,
	input 					i_s_infr		,
	input 					i_sub			,
	input 					i_s_stdp		,

	output 		[7:0] 		o_syn_done		,
	output 		[7:0] 		o_inh_valid		,
	output 		[7:0] 		o_stdp_done		,
	output 		[7:0] 		o_winner		,

	// Image BRAM I/F
	output 		[31:0] 		d				,
	output 		[7:0] 		addr			,
	output 					ce				,
	output 					we				,
	input 		[31:0] 		q
);

///////////////////////////////
// LFSR
wire 			[3:0] 		spike					;
wire 						w_run					;
wire 						valid					;

///////////////////////////////

///////////////////////////////
// PREBUFFER
wire 			[23:0] 		o_spike_bundle			;
wire 						o_valid					;
wire 						o_syn_run				;
wire 			[383:0] 	o_trace					;
wire 						o_done					;
///////////////////////////////

///////////////////////////////
// SUB_TOP
wire signed 	[4:0] 		o_inhbt 		[7:0]	;
wire 			[125:0] 	o_post_cnt 		[7:0]	;
//////////////////////////////
// Find Max
wire 			[39:0] 		o_idx					;
wire 			[55:0] 		o_max					;
wire 			[4:0] 		o_index			[7:0]	;

reg 			[4:0] 		neuron_idx				;

wire 			[4:0] 		oo_idx					;
wire 			[6:0] 		oo_max					;
wire 			[7:0] 		winner					;

assign winner = {oo_idx[3:0], 4'b0} + {2'b0, oo_idx, 1'b0} + neuron_idx;
assign o_winner = winner;
//////////////////////////////


genvar max_idx;
generate
	for(max_idx=0; max_idx<8; max_idx=max_idx+1) begin : gen_max
		assign o_index[max_idx] = o_idx[max_idx*5 +: 5];	
	end
endgenerate

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		neuron_idx <= 5'd0;
	end else begin
		neuron_idx <= o_index[oo_idx];
	end
end

///////////////////////////////////////////////////////

reg signed [24:0] inh;
(* dont_touch = "true" *) wire signed [24:0] inh_sum = o_inhbt[0] + o_inhbt[1] + o_inhbt[2] + o_inhbt[3] + o_inhbt[4] + o_inhbt[5] + o_inhbt[6] + o_inhbt[7];
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		inh <= 25'd0;
	end else begin
		if(o_inh_valid == 8'hff) begin
			if(inh_sum==0) begin
				inh <= 25'd0;
			end else if(inh_sum == 1) begin
				inh <= 25'd458752;
			end else begin
				inh <= 25'd655360;
			end
		end else begin
			inh <= inh;
		end
	end
end

// Instantiate the LFSR module
(* dont_touch = "true" *) lfsr u_LFSR (
    .clk 				(clk			),
    .rst_n 				(rst_n			),
    .i_run 				(i_run			),
    .i_rest_run 		(i_rest_run		),
	.o_spike 			(spike			),
	.o_w_run 			(w_run			),
	.o_valid 			(valid			),

	.d 					(d				),
	.addr 				(addr			),
	.ce 				(ce				),
	.we 				(we				),
	.q 					(q				)
);

(* dont_touch = "true" *) preBuffer u_PREBUFFER (
	.clk 				(clk			),
	.rst_n 				(rst_n			),
	.i_init 			(i_init			),
	.i_spike 			(spike			),
	.i_b_run 			(w_run			),
	.i_valid 			(valid			),
	.i_stdp_run 		(i_stdp_run		),
	.o_spike_bundle 	(o_spike_bundle	),
	.o_valid 			(o_valid		),
	.o_syn_run 			(o_syn_run		),
	.o_trace 			(o_trace		),
	.o_done			 	(o_done			)
);

genvar sub_idx;
generate
	for(sub_idx=0; sub_idx<8; sub_idx=sub_idx+1) begin : gen_sub
		(* dont_touch = "true" *) sub_top #(.SEED (sub_idx+1))
		u_sub_top (
			.clk 				(clk							),
			.rst_n 				(rst_n							),
			.i_init 			(i_init							),
			.i_cnt_clr 			(i_cnt_clr						),
			.i_syn_run 			(o_syn_run						),

			.i_s_lern 			(i_s_lern						),
			.i_s_infr 			(i_s_infr						),

			.i_stdp_run 		(i_stdp_run						),
			.i_sub 				(i_sub							),
			.i_x_trace 			(o_trace						),
			.i_s_stdp 			(i_s_stdp						),

			.i_spike_bundle 	(o_spike_bundle					),
			.i_valid 			(o_valid						),

			.i_inhbt 			(inh							),

			.o_syn_done 		(o_syn_done		[sub_idx]		),

			.o_stdp_done 		(o_stdp_done	[sub_idx]		),

			.o_inhbt 			(o_inhbt		[sub_idx]		),
			.o_post_cnt 		(o_post_cnt		[sub_idx]		),
			.o_inh_valid 		(o_inh_valid	[sub_idx]		)
		);
		(* dont_touch = "true" *) findMax #(.NUM (18))
		u_findMax (
			.clk 				(clk							),
			.rst_n 				(rst_n							),
			.i_cnt_en 			(i_cnt_en						),
			.i_cnt_clr 			(i_cnt_clr						),
			.i_cnt 				(o_post_cnt	[sub_idx]			),
			.o_idx 				(o_idx		[sub_idx*5 +: 5]	),
			.o_max 				(o_max		[sub_idx*7 +: 7]	)
		);
	end
endgenerate

(* dont_touch = "true" *) findMax #(.NUM (8))
u_findMaxTop (
	.clk 			(clk			),
	.rst_n 			(rst_n			),
	.i_cnt_en 		(i_cnt_en		),
	.i_cnt_clr 		(i_cnt_clr		),
	.i_cnt 			(o_max			),
	.o_idx 			(oo_idx			),
	.o_max 			(oo_max			)
);


endmodule

