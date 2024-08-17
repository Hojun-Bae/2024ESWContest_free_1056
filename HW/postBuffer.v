`timescale 1ns/1ps

module postBuffer (
	input 					clk				,
	input 					rst_n			,
	input 					i_valid			,
	input 					i_spike			,
	input 					i_cnt_clr		,
	input 					i_s_init		,
	input 		[4:0] 		i_neuron_idx	,

	output 		[17:0] 		o_spike_buffer	,
	output 		[287:0] 	o_y1_trace		,
	output 		[287:0] 	o_y2_trace_buf	,
	output 		[4:0] 		o_inhbt			,
	output 		[125:0] 	o_post_cnt		,
	output 					o_valid
);

reg 	[17:0] 		spike_buf						;
reg 	[15:0] 		y1_trace			[17:0]		;
reg 	[15:0] 		y2_trace			[17:0]		;
reg 	[15:0] 		y2_trace_buf		[17:0]		;
reg 	[4:0] 		neuron_idx_buf					;
reg 	[4:0] 		ltrl_inhbt						;

reg 	[6:0] 		post_cnt			[17:0]		;

reg 				valid_buf						;
reg 				valid							;
reg 				s_init_d						;

wire 	[4:0] 		neuron_idx = i_neuron_idx		;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		valid_buf <= 1'b0;
		valid <= 1'b0;
		s_init_d <= 1'b0;
		neuron_idx_buf <= 5'd0;
	end else begin
		valid_buf <= i_valid;
		valid <= i_valid && (neuron_idx == 5'd17);
		s_init_d <= i_s_init;
		neuron_idx_buf <= neuron_idx;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		spike_buf <= 18'd0;
	end else if(i_valid) begin
		spike_buf <= {i_spike, spike_buf[17:1]};
	end else begin
		spike_buf <= spike_buf;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		ltrl_inhbt <= 5'd0;
	end else begin
		if(i_valid) begin
			if(neuron_idx == 5'd0) begin
				ltrl_inhbt <= i_spike ? 5'd1 : 5'd0;
			end else begin
				ltrl_inhbt <= i_spike ? ltrl_inhbt + 5'd1 : ltrl_inhbt;
			end
		end else begin
			ltrl_inhbt <= ltrl_inhbt;
		end
	end
end

assign o_inhbt = ltrl_inhbt;

(* DONT_TOUCH = "TRUE" *) wire [15:0] sub2_1_out;
(* DONT_TOUCH = "TRUE" *) wire [15:0] sub2_2_out;
reg [31:0] sub2_1_in;
reg [31:0] sub2_2_in;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub2_1_in <= 32'd0;
		sub2_2_in <= 32'd0;
	end else begin
		if(i_valid) begin
			if(i_spike) begin
				sub2_1_in[31:16] <= 16'hffff;
				sub2_1_in[15:0] <= 16'd0;
				sub2_2_in[31:16] <= 16'hffff;
				sub2_2_in[15:0] <= 16'd0;
			end else begin
				sub2_1_in[31:16] <= y1_trace[neuron_idx];
				sub2_1_in[15:0] <= {4'd0, y1_trace[neuron_idx][15:4]};
				sub2_2_in[31:16] <= y2_trace[neuron_idx];
				sub2_2_in[15:0] <= {5'd0, y2_trace[neuron_idx][15:5]};
			end
		end else begin
			sub2_1_in <= 32'd0;
			sub2_2_in <= 32'd0;
		end
	end
end

assign sub2_1_out = sub2_1_in[31:16] - sub2_1_in[15:0];
assign sub2_2_out = sub2_2_in[31:16] - sub2_2_in[15:0];

always @(posedge clk) begin
	if(s_init_d) begin
		y1_trace[neuron_idx_buf] <= 16'd0;
		y2_trace[neuron_idx_buf] <= 16'd0;
		y2_trace_buf[neuron_idx_buf] <= 16'd0;
	end else if(valid_buf) begin
		y1_trace[neuron_idx_buf] <= sub2_1_out;
		y2_trace[neuron_idx_buf] <= sub2_2_out;
		y2_trace_buf[neuron_idx_buf] <= y2_trace[neuron_idx_buf];
	end
end

genvar nrn_idx;
generate
	for(nrn_idx=0; nrn_idx<18; nrn_idx=nrn_idx+1) begin : gen_cnt
		assign o_y1_trace[nrn_idx*16 +: 16] = y1_trace[nrn_idx];
		assign o_y2_trace_buf[nrn_idx*16 +: 16] = y2_trace_buf[nrn_idx];	
		assign o_post_cnt[nrn_idx*7 +: 7] = post_cnt[nrn_idx];
		always @(posedge clk or negedge rst_n) begin
			if(!rst_n) begin
				post_cnt[nrn_idx] <= 7'd0;
			end else begin
				if(i_cnt_clr) begin
					post_cnt[nrn_idx] <= 7'd0;
				end else if(i_valid) begin
					case(neuron_idx) 
						nrn_idx:
							post_cnt[nrn_idx] <= post_cnt[nrn_idx] + (i_spike ? 7'd1 : 7'd0);
					endcase
				end else begin
					post_cnt[nrn_idx] <= post_cnt[nrn_idx];
				end
			end
		end
	end
endgenerate


assign o_spike_buffer = spike_buf;
assign o_valid = valid;

endmodule

