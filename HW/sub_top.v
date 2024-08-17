`timescale 1ns/1ps

module sub_top 
#(
	parameter SEED = 1000
)
(
	input 						clk				,
	input 						rst_n			,
	input 						i_init			,
	input 						i_cnt_clr		,
	input 						i_syn_run		,
	
	input 						i_s_lern		,
	input 						i_s_infr		,

	// stdp
	input 						i_stdp_run		,
	input 						i_sub			,
	input 			[383:0] 	i_x_trace		,
	input 						i_s_stdp		,

	input 			[23:0] 		i_spike_bundle	,
	input 						i_valid			,

	input signed 	[24:0] 		i_inhbt			,

	output 						o_syn_done		,
	
	output 						o_stdp_done		,

	output 			[4:0] 		o_inhbt			,
	output 			[18*7-1:0] 	o_post_cnt		,
	output 						o_inh_valid
);

`define BRAM_W_DATA_WIDTH 64
`define BRAM_W_ADDR_WIDTH 9
`define BRAM_W_MEM_DEPTH 432
`define WEIGHT_WIDTH 16

////////////////////// synapse //////////////////////
wire 	[24:0] 		syn_current			;
wire 				syn_valid			;

wire 	[383:0] 	syn_d				;
wire 	[53:0] 		syn_addr			;
wire 	[5:0] 		syn_ce				;
wire 	[5:0] 		syn_we				;
wire 	[383:0] 	syn_q				;
/////////////////////////////////////////////////////

////////////////////// neuron //////////////////////
wire 				nrn_init			;
wire 				nrn_spike			;
wire 				nrn_valid			;
wire 	[4:0] 		nrn_neuron_idx		;

wire 	[17:0] 		nrn_spike_buffer	;
wire 	[287:0] 	nrn_y1_trace		;
wire 	[287:0] 	nrn_y2_trace_buf	;

wire 	[49:0] 		nrn_d_c				;
wire 	[4:0] 		nrn_addr_c			;
wire 				nrn_ce_c			;
wire 				nrn_we_c			;
wire 	[49:0] 		nrn_q_c				;

wire 	[54:0]		nrn_d_m				;
wire 	[4:0] 		nrn_addr_m			;
wire 				nrn_ce_m			;
wire 				nrn_we_m			;
wire 	[54:0] 		nrn_q_m				;
/////////////////////////////////////////////////////

////////////////////// stdp //////////////////////
wire 	[383:0] 	stdp_d_r			;
wire 	[53:0] 		stdp_addr_r			;
wire 	[5:0] 		stdp_ce_r			;
wire 	[5:0] 		stdp_we_r			;

wire 	[383:0] 	stdp_d_w			;
wire 	[53:0] 		stdp_addr_w			;
wire 	[5:0] 		stdp_ce_w			;
wire 	[5:0] 		stdp_we_w			;
wire 	[383:0] 	stdp_q_w			;
/////////////////////////////////////////////////////

wire 	[383:0] 	w_d					;
wire 	[53:0] 		w_addr				;
wire 	[5:0] 		w_ce				;
wire 	[5:0] 		w_we				;

assign w_d = i_s_stdp ? stdp_d_r : syn_d;
assign w_addr = i_s_stdp ? stdp_addr_r : syn_addr;
assign w_ce = i_s_stdp ? stdp_ce_r : syn_ce;
assign w_we = i_s_stdp ? stdp_we_r : syn_we;

////////////////////// synapse //////////////////////
(* dont_touch = "true" *) synapse 
#(
	.SEED (SEED)
)
dut_synapse (
	.clk 				(clk			),
	.rst_n 				(rst_n			),
	.i_run 				(i_syn_run		),
	.i_wegt_rst 		(i_init			),
	.o_current 			(syn_current	),
	.o_valid 			(syn_valid		),
	.o_done	 			(o_syn_done		),

	// BRAM I/F
	.d 					(syn_d			),
	.addr 				(syn_addr		),
	.ce 				(syn_ce			),
	.we 				(syn_we			),
	.q 					(syn_q			),

	.i_spike_bundle 	(i_spike_bundle	),
	.i_valid 			(i_valid		)
);

genvar brm_idx;
generate
	for(brm_idx=0; brm_idx<6; brm_idx=brm_idx+1) begin : gen_brm
		(* dont_touch = "true" *) dpbram 
		#(	
			.DWIDTH (`BRAM_W_DATA_WIDTH),
			.AWIDTH (`BRAM_W_ADDR_WIDTH),
			.MEM_SIZE (`BRAM_W_MEM_DEPTH)
		)
		u_W_DPBRAM(
			.clk		(clk),
		
			.addr0		(w_addr			[brm_idx*9 	+: 	9]		),
			.ce0		(w_ce			[brm_idx]				),
			.we0		(w_we			[brm_idx]				),
			.q0			(syn_q			[brm_idx*64 +: 64]		),
			.d0			(w_d			[brm_idx*64 +: 64]		), 
			
			.addr1		(stdp_addr_w	[brm_idx*9 +: 9]		),
			.ce1		(stdp_ce_w		[brm_idx]				),
			.we1		(stdp_we_w		[brm_idx]				),
			.q1			(stdp_q_w		[brm_idx*64 +: 64]		),
			.d1			(stdp_d_w		[brm_idx*64 +: 64]		) 
		);
	end
endgenerate
/////////////////////////////////////////////////////

////////////////////// neuron //////////////////////
(* dont_touch = "true" *) updateNeuron dut_updateNeuron
(
	.clk				(clk				),
	.rst_n				(rst_n				),
	.i_run				(syn_valid			),
	.i_init				(i_init				),
	.i_s_lern			(i_s_lern			),
	.i_s_infr			(i_s_infr			),

	.exc_current		(syn_current		),
	.inh_current		(i_inhbt			),

	.o_s_init			(nrn_init			),
	.o_spike			(nrn_spike			),
	.o_valid			(nrn_valid			),
	.o_neuron_idx		(nrn_neuron_idx		),

	// BRAM I/F	
	.d_c				(nrn_d_c			),
	.addr_c				(nrn_addr_c			),
	.ce_c				(nrn_ce_c			),
	.we_c				(nrn_we_c			),
	.q_c				(nrn_q_c			),

	.d_m				(nrn_d_m			),
	.addr_m				(nrn_addr_m			),
	.ce_m				(nrn_ce_m			),
	.we_m				(nrn_we_m			),
	.q_m				(nrn_q_m			)
);

(* dont_touch = "true" *) postBuffer dut_postBuffer
(
	.clk				(clk				),
	.rst_n				(rst_n				),
	.i_valid			(nrn_valid			),
	.i_spike			(nrn_spike			),
	.i_cnt_clr			(i_cnt_clr			),
	.i_s_init			(nrn_init			),
	.i_neuron_idx		(nrn_neuron_idx		),

	.o_spike_buffer		(nrn_spike_buffer	),
	.o_y1_trace			(nrn_y1_trace		),
	.o_y2_trace_buf		(nrn_y2_trace_buf	),
	.o_inhbt			(o_inhbt			),
	.o_post_cnt			(o_post_cnt			),
	.o_valid			(o_inh_valid		)
);

(* dont_touch = "true" *) spbram
#(	
	.DWIDTH 			(50			),
	.AWIDTH 			(5			),
	.MEM_SIZE 			(18			)
)
u_CDTC_SPBRAM(
	.clk				(clk		),

	.addr				(nrn_addr_c	),
	.ce					(nrn_ce_c	),
	.we					(nrn_we_c	),
	.q					(nrn_q_c	),
	.d					(nrn_d_c	) 
);

(* dont_touch = "true" *) spbram
#(	
	.DWIDTH 			(55			),
	.AWIDTH 			(5			),
	.MEM_SIZE 			(18			)
)
u_NRNST_SPBRAM(
	.clk				(clk		),

	.addr				(nrn_addr_m	),
	.ce					(nrn_ce_m	),
	.we					(nrn_we_m	),
	.q					(nrn_q_m	),
	.d					(nrn_d_m	)
);
/////////////////////////////////////////////////////

////////////////////// stdp //////////////////////
(* dont_touch = "true" *) stdp dut_stdp (
	.clk				(clk				),
	.rst_n				(rst_n				),
	.i_run				(i_stdp_run			),
	.i_sub				(i_sub				),
	.i_post_spike		(nrn_spike_buffer	),
	.i_pre_spike		(i_spike_bundle		),

	.i_y1_trace			(nrn_y1_trace		),
	.i_y2_trace_buf		(nrn_y2_trace_buf	),
	.i_x_trace			(i_x_trace			),
	
	.o_done				(o_stdp_done		),

	// BRAM I/F
	.d_r				(stdp_d_r			),
	.addr_r				(stdp_addr_r		),
	.ce_r				(stdp_ce_r			),
	.we_r				(stdp_we_r			),
	.q_r				(syn_q				),

	.d_w				(stdp_d_w			),
	.addr_w				(stdp_addr_w		),
	.ce_w				(stdp_ce_w			),
	.we_w				(stdp_we_w			),
	.q_w				(stdp_q_w			)
);
/////////////////////////////////////////////////////
endmodule
