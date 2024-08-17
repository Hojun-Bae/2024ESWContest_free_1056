`timescale 1ns/1ps

module controller (
	input clk,
	input reset_n,
	input i_init,
	input i_lern,
	input i_infr,

	input [7:0] i_syn_done,
	input [7:0] i_inh_valid,
	input [7:0] i_stdp_done,

	output o_run,
	output o_init,
	output o_rest_run,
	output o_stdp_run,
	output o_cnt_clr,
	output o_s_lern,
	output o_s_infr,
	output o_sub,
	output o_s_stdp
);

localparam S_IDLE = 3'd0;
localparam S_INIT = 3'd1;
localparam S_LERN = 3'd2;
localparam S_LRST = 3'd3;
localparam S_INFR = 3'd4;
localparam S_IRST = 3'd5;
localparam S_STDP = 3'd6;
localparam S_DONE = 3'd7;

reg [2:0] cs, ns;
reg [10:0] time_step;
reg [10:0] inf_time_step;

reg [1:0] inh_valid_buf;

reg s_init_buf;
reg s_lern_buf;
reg s_lrst_buf;
reg s_infr_buf;
reg s_irst_buf;
reg s_stdp_buf;
reg s_done_buf;

wire s_init;
wire s_lern;
wire s_lrst;
wire s_infr;
wire s_irst;
wire s_stdp;
wire s_done;

wire inh_valid;
wire lfsr_run;
wire stdp_run;
wire learning;
wire inferencing;
wire finish;

always @(*) begin
	ns = cs;
	case(cs)
		S_IDLE : begin
			if(i_init) begin
				ns = S_INIT;
			end else if(i_lern) begin
				ns = S_LERN;
			end else if(i_infr) begin
				ns = S_INFR;
			end
		end
		S_INIT : begin
			if(i_syn_done) begin
				ns = S_DONE;
			end
		end
		S_LERN : begin
			if(inh_valid) begin
				ns = S_STDP;
			end
		end
		S_STDP : begin
			if(i_stdp_done) begin
				if(learning) begin
					ns = S_LERN;
				end else begin
					ns = finish ? S_DONE : S_LRST;
				end
			end
		end
		S_LRST : begin
			if(inh_valid) begin
				ns = S_STDP;
			end
		end
		S_INFR : begin
			if(!inferencing) begin
				ns = S_IRST;
			end
		end
		S_IRST : begin
			if(finish) begin
				ns = S_DONE;
			end
		end
		S_DONE : begin
			ns = S_IDLE;
		end
	endcase
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cs <= S_IDLE;
	end else begin
		cs <= ns;
	end
end

assign s_init = (cs == S_INIT);
assign s_lern = (cs == S_LERN);
assign s_lrst = (cs == S_LRST);
assign s_infr = (cs == S_INFR);
assign s_irst = (cs == S_IRST);
assign s_stdp = (cs == S_STDP);
assign s_done = (cs == S_DONE);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		s_init_buf <= 1'b0;
		s_lern_buf <= 1'b0;
		s_lrst_buf <= 1'b0;
		s_infr_buf <= 1'b0;
		s_irst_buf <= 1'b0;
		s_stdp_buf <= 1'b0;
		s_done_buf <= 1'b0;
		inh_valid_buf <= 2'b0;
	end else begin
		s_init_buf <= s_init;
		s_lern_buf <= s_lern;
		s_lrst_buf <= s_lrst;
		s_infr_buf <= s_infr;
		s_irst_buf <= s_irst;
		s_stdp_buf <= s_stdp;
		s_done_buf <= s_done;
		inh_valid_buf <= {inh_valid_buf[0], inh_valid};
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		time_step <= 11'd0;
	end else begin
		if(lfsr_run && (s_lern || s_lrst)) begin
			if(finish) begin
				time_step <= 11'd0;
			end else begin
				time_step <= time_step + 11'd1;
			end
		end else if(s_done) begin
			time_step <= 11'd0;
		end else begin
			time_step <= time_step;
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		inf_time_step <= 11'd0;
	end else begin
		if(inh_valid_buf[1]) begin
			if(finish) begin
				inf_time_step <= 11'd0;
			end else begin
				inf_time_step <= inf_time_step + 11'd1;
			end
		end else if(s_done) begin
			inf_time_step <= 11'd0;
		end else begin
			inf_time_step <= inf_time_step;
		end
	end
end

assign inh_valid = (i_inh_valid == 8'hff);
assign learning = (time_step < 11'd800);
assign inferencing = (inf_time_step < 11'd800);
assign finish = (time_step == 11'd1200) || (inf_time_step == 11'd1200);

assign lfsr_run = (s_lern && (!s_lern_buf));
assign stdp_run = s_stdp && (!s_stdp_buf);

assign o_run = lfsr_run || ((inh_valid_buf[1] || !s_infr_buf) && s_infr);
assign o_init = s_init && (!s_init_buf);
assign o_rest_run = (s_lrst && (!s_lrst_buf)) || (inh_valid_buf[1] && s_irst);
assign o_stdp_run = stdp_run;
assign o_cnt_clr = (cs == S_IDLE);
assign o_s_lern = s_lern;
assign o_s_infr = s_infr || s_irst;
assign o_sub = (time_step[6:0] == 7'h7f);
assign o_s_stdp = s_stdp;

endmodule
