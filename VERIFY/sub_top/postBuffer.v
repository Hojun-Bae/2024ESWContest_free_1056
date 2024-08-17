`timescale 1ns/1ps

module postBuffer (
	input clk,
	input reset_n,
	input i_valid,
	input i_spike,
	input i_cnt_clr,
	input [4:0] i_neuron_idx,

	output [17:0] o_spike_buffer,
	output [287:0] o_y1_trace,
	output [287:0] o_y2_trace_buf,
	output signed [24:0] o_inhbt,
	output [125:0] o_post_cnt,
	output o_valid
);

reg [17:0] spike_buf;
reg [287:0] y1_trace;
reg [287:0] y2_trace;
reg [287:0] y2_trace_buf;
reg [4:0] neuron_idx_buf;
reg signed [24:0] ltrl_inhbt;

reg [125:0] post_cnt;

reg valid_buf;
reg valid;

wire signed [24:0] ltrl_inhbt_bound;
wire [4:0] neuron_idx = i_neuron_idx;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		neuron_idx_buf <= 5'd0;
	end else begin
		if(i_valid) begin
			neuron_idx_buf <= neuron_idx;
		end else begin
			neuron_idx_buf <= neuron_idx_buf;
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		valid_buf <= 1'b0;
		valid <= 1'b0;
	end else begin
		valid_buf <= i_valid;
		valid <= i_valid && (neuron_idx == 5'd17);
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		spike_buf <= 18'd0;
	end else if(i_valid) begin
		spike_buf <= {i_spike, spike_buf[17:1]};
	end else begin
		spike_buf <= spike_buf;
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		ltrl_inhbt <= 25'd0;
	end else begin
		if(i_valid) begin
			if(neuron_idx == 5'd0) begin
				ltrl_inhbt <= i_spike ? 25'd458752 : 25'd0;
			end else begin
				ltrl_inhbt <= (ltrl_inhbt_bound > 25'd655360) ? 25'd655360 : ltrl_inhbt_bound;
			end
		end else begin
			ltrl_inhbt <= ltrl_inhbt;
		end
	end
end

assign ltrl_inhbt_bound = ltrl_inhbt + (i_spike ? 25'd458752 : 25'd0);
assign o_inhbt = ltrl_inhbt;

wire [15:0] sub2_1_out;
wire [15:0] sub2_2_out;
reg [31:0] sub2_1_in;
reg [31:0] sub2_2_in;

genvar sub_idx;
generate 
	for(sub_idx=0; sub_idx<18; sub_idx=sub_idx+1) begin : gen_sub
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				sub2_1_in <= 32'd0;
				sub2_2_in <= 32'd0;
			end else begin
				if(i_valid) begin
					case(neuron_idx)
						sub_idx: begin
							if(i_spike) begin
								sub2_1_in[31:16] <= 16'hffff;
								sub2_1_in[15:0] <= 16'd0;
								sub2_2_in[31:16] <= 16'hffff;
								sub2_2_in[15:0] <= 16'd0;
							end else begin
								sub2_1_in[31:16] <= y1_trace[sub_idx*16 +: 16];
								sub2_1_in[15:0] <= {4'd0, y1_trace[(sub_idx*16 + 4) +: 12]};
								sub2_2_in[31:16] <= y1_trace[sub_idx*16 +: 16];
								sub2_2_in[15:0] <= {5'd0, y2_trace[(sub_idx*16 + 5) +: 11]};
							end
						end
					endcase
				end else begin
					sub2_1_in <= 32'd0;
					sub2_2_in <= 32'd0;
				end
			end
		end
	end
endgenerate

assign sub2_1_out = sub2_1_in[31:16] - sub2_1_in[15:0];
assign sub2_2_out = sub2_2_in[31:16] - sub2_2_in[15:0];


genvar buf_idx;
generate 
	for(buf_idx=0; buf_idx<18; buf_idx=buf_idx+1) begin : gen_buf
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				y1_trace[buf_idx*16 +: 16] <= 16'd0;
				y2_trace[buf_idx*16 +: 16] <= 16'd0;
				y2_trace_buf[buf_idx*16 +: 16] <= 16'd0;
			end else begin
				if(valid_buf) begin
					case(neuron_idx_buf)
						buf_idx: begin
							y1_trace[buf_idx*16 +: 16] <= sub2_1_out;
							y2_trace[buf_idx*16 +: 16] <= sub2_2_out;
							y2_trace_buf[buf_idx*16 +: 16] <= y2_trace[buf_idx*16 +: 16];
						end
					endcase
				end else begin
					y1_trace[buf_idx*16 +: 16] <= y1_trace[buf_idx*16 +: 16];
					y2_trace[buf_idx*16 +: 16] <= y2_trace[buf_idx*16 +: 16];
					y2_trace_buf[buf_idx*16 +: 16] <= y2_trace_buf[buf_idx*16 +: 16];
				end
			end
		end
	end
endgenerate

genvar nrn_idx;
generate
	for(nrn_idx=0; nrn_idx<18; nrn_idx=nrn_idx+1) begin : gen_cnt
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				post_cnt[nrn_idx*7 +: 7] <= 7'd0;
			end else begin
				if(i_cnt_clr) begin
					post_cnt[nrn_idx*7 +: 7] <= 7'd0;
				end else if(i_valid) begin
					case(neuron_idx) 
						nrn_idx:
							post_cnt[nrn_idx*7 +: 7] <= post_cnt[nrn_idx*7 +: 7] + (i_spike ? 7'd1 : 7'd0);
					endcase
				end else begin
					post_cnt[nrn_idx*7 +: 7] <= post_cnt[nrn_idx*7 +: 7];
				end
			end
		end
	end
endgenerate


assign o_spike_buffer = spike_buf;
assign o_y1_trace = y1_trace;
assign o_y2_trace_buf = y2_trace_buf;
assign o_post_cnt = post_cnt;
assign o_valid = valid;

endmodule

