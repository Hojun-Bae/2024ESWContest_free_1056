`timescale 1ns/1ps

module preBuffer (
	input clk,
	input reset_n,
	input i_init,
	input [3:0] i_spike,
	input i_b_run,
	input i_valid,
	input i_stdp_run,
	output [23:0] o_spike_bundle,
	output o_valid,
	output o_syn_run,
	output [383:0] o_trace,
	output o_done
);

localparam S_IDLE = 3'd0;
localparam S_INIT = 3'd1;
localparam S_STCK = 3'd2;
localparam S_SEND = 3'd3;
localparam S_DONE = 3'd4;

wire s_init;
wire s_stck;
wire s_send;
wire s_done;

wire cnt_done;
wire row_done;
wire nrn_done;
wire nrn_ns;

wire [23:0] spike_arr [23:0];
wire [383:0] trace_arr [23:0];
wire [16*24*24-1:0] trace_wire;
wire [15:0] sub_out [3:0];
wire [16*4-1:0] post_trace;

reg [2:0] cs, ns;
reg [24*24-1:0] spike_buffer;
reg [16*4-1:0] x_trace[143:0];
reg [$clog2(144)-1:0] cnt;
reg [$clog2(144)-1:0] cnt_d;
reg [4:0] row_cnt;
reg [4:0] nrn_cnt;

reg [15:0] sub_in_1 [3:0];
reg [15:0] sub_in_2 [3:0];

reg [23:0] spike_bundle;
reg [383:0] trace_bundle;
reg s_init_d;
reg s_stck_d;
reg valid;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cs <= S_IDLE;
		s_init_d <= 1'b0;
		s_stck_d <= 1'b0;
		cnt_d <= {$clog2(144){1'b0}};
	end else begin
		cs <= ns;
		s_init_d <= s_init;
		s_stck_d <= s_stck;
		cnt_d <= cnt;
	end
end

always @(*) begin
	ns = cs;
	case(cs)
		S_IDLE : begin
			if(i_b_run) 
				ns = S_STCK;
			else if(i_init)
				ns = S_INIT;
			else if(i_stdp_run)
				ns = S_SEND;
		end
		S_INIT :
			if(cnt_done)
				ns = S_DONE;
		S_STCK :
			if(cnt_done)
				ns = S_SEND;
		S_SEND :
			if(row_done && nrn_ns)
				ns = S_DONE;
		S_DONE :
			ns = S_IDLE;
	endcase
end

assign s_init = (cs == S_INIT);
assign s_stck = (cs == S_STCK);
assign s_send = (cs == S_SEND);
assign s_done = (cs == S_DONE);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		spike_buffer <= {24*24{1'b0}};
	end else begin
		if(i_valid && s_stck) begin
			spike_buffer <= {i_spike, spike_buffer[24*24-1:4]};
		end else begin
			spike_buffer <= spike_buffer;
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cnt <= {$clog2(144){1'b0}};
	end else begin
		if(s_stck || s_init) begin
			cnt <= cnt + 1;
		end else begin
			cnt <= {$clog2(144){1'b0}};
		end
	end
end

assign cnt_done = (cnt == 143);

genvar i;
generate
	for(i=0; i<4; i=i+1) begin : gen_i
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				sub_in_1[i] <= 16'd0;
				sub_in_2[i] <= 16'd0;
			end else begin
				if(i_valid && s_stck) begin
					if(i_spike[i]) begin
						sub_in_1[i] <= 16'hffff;
						sub_in_2[i] <= 16'd0; 
					end else begin
						sub_in_1[i] <= x_trace[cnt][i*16 +: 16];
						sub_in_2[i] <= {4'd0, x_trace[cnt][(i*16+4) +: 12]}; 
					end
				end else begin
					sub_in_1[i] <= 16'd0;
					sub_in_2[i] <= 16'd0;
				end
			end
		end
		assign sub_out[i] = sub_in_1[i] - sub_in_2[i];
		assign post_trace[i*16 +: 16] = sub_out[i];
	end
endgenerate

genvar trc_idx;
generate
	for(trc_idx=0; trc_idx<144; trc_idx=trc_idx+1) begin
		assign trace_wire[trc_idx*64 +: 64] = x_trace[trc_idx];
	end
endgenerate

always @(posedge clk) begin
	if(s_init_d || s_stck_d) begin
		x_trace[cnt_d] <= post_trace;
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		row_cnt <= 5'd0;
	end else begin
		if(s_send) begin
			row_cnt <= row_done ? 5'd0 : row_cnt + 5'd1;
		end else begin
			row_cnt <= 5'd0;
		end
	end
end

assign row_done = (row_cnt == 5'd23);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		nrn_cnt <= 5'd0;
	end else begin
		if(s_send && row_done) begin
			nrn_cnt <= nrn_done ? 5'd0 : nrn_cnt + 5'd1;
		end else if(nrn_done) begin
			nrn_cnt <= 5'd0;
		end else begin
			nrn_cnt <= nrn_cnt;
		end
	end
end

assign nrn_done = (nrn_cnt == 5'd18);
assign nrn_ns = (nrn_cnt == 5'd17);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		spike_bundle <= 24'd0;
		trace_bundle <= 384'd0;
		valid <= 1'b0;
	end else begin
		if(s_send) begin
			spike_bundle <= spike_arr[row_cnt];
			trace_bundle <= trace_arr[row_cnt];
			valid <= 1'b1;
		end else begin
			spike_bundle <= 24'd0;
			trace_bundle <= 384'd0;
			valid <= 1'b0;
		end
	end
end

genvar idx;
generate 
	for(idx=0; idx<24; idx=idx+1) begin : gen_idx
		assign spike_arr[idx] = spike_buffer[idx*24 +: 24];
		assign trace_arr[idx] = trace_wire[idx*384 +: 384];
	end
endgenerate

assign o_spike_bundle = spike_bundle;
assign o_valid = valid;
assign o_syn_run = cnt_done;
assign o_trace = trace_bundle;
assign o_done = s_done;

endmodule
