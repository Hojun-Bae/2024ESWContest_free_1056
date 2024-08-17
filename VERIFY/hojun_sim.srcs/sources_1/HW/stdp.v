`timescale 1ns/1ps

module stdp
(
	input clk,
	input reset_n,
	input i_run,
	input i_sub,
	input [17:0] i_post_spike,
	input [23:0] i_pre_spike,

	input [287:0] i_y1_trace,
	input [287:0] i_y2_trace_buf,
	input [383:0] i_x_trace,

	output o_done,

	// BRAM I/F
	output [383:0] d_r,
	output [53:0] addr_r,
	output [5:0] ce_r,
	output [5:0] we_r,
	input [383:0] q_r,

	output [383:0] d_w,
	output [53:0] addr_w,
	output [5:0] ce_w,
	output [5:0] we_w,
	input [383:0] q_w
);

localparam S_IDLE = 2'b00;
localparam S_RUN = 2'b01;
localparam S_DONE = 2'b10;

wire s_idle;
wire s_run;
wire s_done;
wire s_r_idle;
wire s_r_run;
wire s_r_done;
wire s_w_idle;
wire s_w_run;
wire s_w_done;

wire is_row_done;
wire is_neuron_done;
wire is_read_done;
wire is_wrte_done;

(* DONT_TOUCH = "TRUE" *) wire [383:0] add_result;
(* DONT_TOUCH = "TRUE" *) wire signed [17:0] add_out [23:0];

wire post_spike_in[17:0];
wire [15:0] y1_trace_in[17:0];
wire [15:0] y2_trace_buf_in[17:0];

reg signed [24:0] mult_in_1 [23:0];
reg signed [17:0] mult_in_2 [23:0];
reg signed [42:0] mult_out [23:0];
reg signed [17:0] add_in_1 [23:0];
reg signed [17:0] add_in_2 [23:0];
reg signed [17:0] add_in_3 [23:0];
reg signed [17:0] add_in_4 [23:0];


reg [15:0] pre_delta [23:0];
reg [15:0] pre_delta_buf [23:0];

reg [383:0] post_wegt;
reg [383:0] q_buf;


reg [4:0] run_buf;
reg [2:0] s_r_run_buf;

reg [8:0] addr_read;
reg [8:0] addr_wrte;

reg [4:0] neuron_idx;
reg [4:0] row_cnt;

reg [1:0] cs;
reg [1:0] ns;
reg [1:0] cs_r;
reg [1:0] ns_r;
reg [1:0] cs_w;
reg [1:0] ns_w;

reg post_spike;
reg [15:0] y1_trace;
reg [15:0] y2_trace_buf;

reg sub_check;

// Buffer
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		run_buf <= 5'd0;
		s_r_run_buf <= 3'd0;
		q_buf <= 384'd0;
	end else begin
		run_buf <= {run_buf[3:0], i_run};
		s_r_run_buf <= {s_r_run_buf[1:0], s_r_run};
		q_buf <= q_r;
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		sub_check <= 0;
	end else begin
		if(i_run) begin
			sub_check <= i_sub;
		end else begin
			sub_check <= sub_check;
		end
	end
end
			
// FSM
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cs <= S_IDLE;
		cs_r <= S_IDLE;
		cs_w <= S_IDLE;
	end else begin
		cs <= ns;
		cs_r <= ns_r;
		cs_w <= ns_w;
	end
end

always @(*) begin
	ns = cs;
	case(cs)
		S_IDLE:
			if(i_run)
				ns = S_RUN;
		S_RUN:
			if(is_row_done && is_neuron_done)
				ns = S_DONE;
		S_DONE:
			ns = S_IDLE;
	endcase
end

assign s_idle = (cs == S_IDLE);
assign s_run = (cs == S_RUN);
assign s_done = (cs == S_DONE);

always @(*) begin
	ns_r = cs_r;
	case(cs_r)
		S_IDLE:
			if(run_buf[0])
				ns_r = S_RUN;
		S_RUN:
			if(is_read_done)
				ns_r = S_DONE;
		S_DONE:
			ns_r = S_IDLE;
	endcase
end

assign s_r_idle = (cs_r == S_IDLE);
assign s_r_run = (cs_r == S_RUN);
assign s_r_done = (cs_r == S_DONE);

always @(*) begin
	ns_w = cs_w;
	case(cs_w)
		S_IDLE:
			if(run_buf[4])
				ns_w = S_RUN;
		S_RUN:
			if(is_wrte_done)
				ns_w = S_DONE;
		S_DONE:
			ns_w = S_IDLE;
	endcase
end

assign s_w_idle = (cs_w == S_IDLE);
assign s_w_run = (cs_w == S_RUN);
assign s_w_done = (cs_w == S_DONE);

//
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		row_cnt <= 5'd0;
	end else begin
		if(s_run) begin
			if(is_row_done) begin
				row_cnt <= 5'd0;
			end else begin
				row_cnt <= row_cnt + 5'd1;
			end
		end else if(s_done) begin
			row_cnt <= 5'd0;
		end else begin
			row_cnt <= row_cnt;
		end
	end
end

assign is_row_done = (row_cnt == 5'd23);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		neuron_idx <= 5'd0;
	end else begin
		if(s_run && is_row_done) begin
			if(neuron_idx == 5'd18) begin
				neuron_idx <= 5'd0;
			end else begin
				neuron_idx <= neuron_idx + 5'd1;
			end
		end else if(s_done) begin
			neuron_idx <= 5'd0;
		end else begin
			neuron_idx <= neuron_idx;
		end
	end
end

assign is_neuron_done = (neuron_idx == 5'd17);

// ADDR
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		addr_read <= 9'd0;
	end else begin
		if(s_r_run) begin
			addr_read <= addr_read + 9'd1;
		end else if(s_r_done) begin
			addr_read <= 9'd0;
		end else begin
			addr_read <= addr_read;
		end
	end
end

assign is_read_done = s_r_run && (addr_read == 9'd431);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		addr_wrte <= 9'd0;
	end else begin
		if(s_w_run) begin
			addr_wrte <= addr_wrte + 9'd1;
		end else if(s_w_done) begin
			addr_wrte <= 9'd0;
		end else begin
			addr_wrte <= addr_wrte;
		end
	end
end

assign is_wrte_done = s_w_run && (addr_wrte == 9'd431);

// y trace
genvar nrn_idx;
generate
	for(nrn_idx=0; nrn_idx<18; nrn_idx=nrn_idx+1) begin : gen_y
		assign post_spike_in[nrn_idx] = i_post_spike[nrn_idx];
		assign y1_trace_in[nrn_idx] = i_y1_trace[nrn_idx*16 +: 16];
		assign y2_trace_buf_in[nrn_idx] = i_y2_trace_buf[nrn_idx*16 +: 16];
	end
endgenerate

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		post_spike <= 1'b0;
		y1_trace <= 16'd0;
		y2_trace_buf <= 16'd0;
	end else begin
		if(s_run) begin
			post_spike <= post_spike_in[neuron_idx];
			y1_trace <= y1_trace_in[neuron_idx];
			y2_trace_buf <= y2_trace_buf_in[neuron_idx];
		end else begin
			post_spike <= 1'b0;
			y1_trace <= 16'd0;
			y2_trace_buf <= 16'd0;
		end
	end
end

// mult
genvar mul_idx;
generate
	for(mul_idx=0; mul_idx<24; mul_idx=mul_idx+1) begin : gen_mul
		always @(posedge clk) begin
			mult_out[mul_idx] <= mult_in_1[mul_idx] * mult_in_2[mul_idx];
		end
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				mult_in_1[mul_idx] <= 25'd0;
				mult_in_2[mul_idx] <= 18'd0;
			end else begin
				if(s_r_run && post_spike) begin
					mult_in_1[mul_idx] <= {9'd0, i_x_trace[16*mul_idx +: 16]};
					mult_in_2[mul_idx] <= {2'd0, y2_trace_buf};
				end else begin
					mult_in_1[mul_idx] <= 25'd0;
					mult_in_2[mul_idx] <= 18'd0;
				end
			end
		end
	end
endgenerate

genvar sft_idx;
generate
	for(sft_idx=0; sft_idx<24; sft_idx=sft_idx+1) begin : gen_sft
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				pre_delta[sft_idx] <= 16'd0;
			end else begin
				if(s_r_run) begin
					if(i_pre_spike[sft_idx]) begin
						pre_delta[sft_idx] <= {10'd0, y1_trace[15:10]};
					end else begin
						pre_delta[sft_idx] <= 16'd0;
					end
				end else begin
					pre_delta[sft_idx] <= 16'd0;
				end
			end
		end
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				pre_delta_buf[sft_idx] <= 16'd0;
			end else begin
				pre_delta_buf[sft_idx] <= pre_delta[sft_idx];
			end
		end
	end
endgenerate


// add
genvar add_idx;
generate
	for(add_idx=0; add_idx<24; add_idx=add_idx+1) begin : gen_add
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				add_in_1[add_idx] <= 18'd0;
				add_in_2[add_idx] <= 18'd0;
				add_in_3[add_idx] <= 18'd0;
				add_in_4[add_idx] <= 18'd0;
			end else begin
				if(s_r_run_buf[1]) begin
					add_in_1[add_idx] <= {6'd0, mult_out[add_idx][31:20]};
					add_in_2[add_idx] <= {2'd0, pre_delta_buf[add_idx]};
					add_in_3[add_idx] <= {2'd0, q_buf[16*add_idx +: 16]};
					add_in_4[add_idx] <= sub_check ? 18'd1 : 18'd0;
				end else begin
					add_in_1[add_idx] <= 18'd0;
					add_in_2[add_idx] <= 18'd0;
					add_in_3[add_idx] <= 18'd0;
					add_in_4[add_idx] <= 18'd0;
				end
			end
		end
		assign add_out[add_idx] = add_in_1[add_idx] - add_in_2[add_idx] + add_in_3[add_idx] - add_in_4[add_idx];
		assign add_result[16*add_idx +: 16] = (add_out[add_idx][17]) ? 16'd0 : ((add_out[add_idx] > 16'hffff) ? 16'hffff : add_out[add_idx][15:0]);
	end
endgenerate

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		post_wegt <= 384'd0;
	end else begin
		if(s_r_run_buf[2]) begin
			post_wegt <= add_result;
		end else begin
			post_wegt <= 384'd0;
		end
	end
end

// BRAM I/F
genvar ram_idx;
generate
	for(ram_idx=0; ram_idx<6; ram_idx=ram_idx+1) begin : gen_ram
		assign d_r[64*ram_idx +: 64] = 64'd0;
		assign addr_r[9*ram_idx +: 9] = addr_read;
		assign ce_r[ram_idx] = s_r_run;
		assign we_r[ram_idx] = 1'b0;

		assign d_w[64*ram_idx +: 64] = post_wegt[64*ram_idx +: 64];
		assign addr_w[9*ram_idx +: 9] = addr_wrte;
		assign ce_w[ram_idx] = s_w_run;
		assign we_w[ram_idx] = s_w_run;
	end
endgenerate

assign o_done = s_w_done;

endmodule

