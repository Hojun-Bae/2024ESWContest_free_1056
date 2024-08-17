`timescale 1ns/1ps

module snnTop (
	input 				clk			,
	input 				rst_n		,
	input 				i_init		,
	input 				i_lern		,
	input 				i_infr		,

	output 	[7:0] 		o_winner	,
	output 				o_idle		,
	output 				o_running	,
	output 				o_done		,

	// Image BRAM I/F
	output 	[31:0] 		d			,
	output 	[7:0] 		addr		,
	output 				ce			,
	output 				we			,
	input 	[31:0] 		q

);

wire 			o_run				;
wire 			o_init				;
wire 			o_rest_run			;
wire 			o_stdp_run			;
wire 			o_cnt_en			;
wire 			o_cnt_clr			;
wire 			o_s_lern			;
wire 			o_s_infr			;
wire 			o_sub				;
wire 			o_s_stdp			;

wire 	[7:0] 	o_syn_done			;
wire 	[7:0] 	o_inh_valid			;
wire 	[7:0] 	o_stdp_done			;
//////////////////////////////

(* DONT_TOUCH = "TRUE" *) top u_top (
	.clk 			(clk			),
	.rst_n 			(rst_n			),
	.i_run 			(o_run			),
	.i_rest_run 	(o_rest_run		),
	.i_stdp_run 	(o_stdp_run		),
	.i_init 		(o_init			),
	.i_cnt_en 		(o_cnt_en		),
	.i_cnt_clr 		(o_cnt_clr		),
	.i_s_lern 		(o_s_lern		),
	.i_s_infr 		(o_s_infr		),
	.i_sub 			(o_sub			),
	.i_s_stdp 		(o_s_stdp		),

	.o_syn_done 	(o_syn_done		),
	.o_inh_valid 	(o_inh_valid	),
	.o_stdp_done 	(o_stdp_done	),
	.o_winner 		(o_winner		),

	.d 				(d				),
	.addr 			(addr			),
	.ce 			(ce				),
	.we 			(we				),
	.q 				(q				)
);

(* DONT_TOUCH = "TRUE" *) controller u_controller (
	.clk 			(clk			),
	.rst_n 			(rst_n			),
	.i_init 		(i_init			),
	.i_lern 		(i_lern			),
	.i_infr  		(i_infr			),

	.i_syn_done 	(o_syn_done		),
	.i_inh_valid 	(o_inh_valid	),
	.i_stdp_done 	(o_stdp_done	),

	.o_run 			(o_run			),
	.o_init 		(o_init			),
	.o_rest_run 	(o_rest_run		),
	.o_stdp_run 	(o_stdp_run		),
	.o_cnt_en 		(o_cnt_en		),
	.o_cnt_clr	 	(o_cnt_clr		),
	.o_s_lern 		(o_s_lern		),
	.o_s_infr 		(o_s_infr		),
	.o_sub 			(o_sub			),
	.o_s_stdp 		(o_s_stdp		),
	.o_s_idle 		(o_idle			),
	.o_s_running 	(o_running		),
	.o_s_done 		(o_done			)
);

endmodule
