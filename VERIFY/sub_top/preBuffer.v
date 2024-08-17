`timescale 1ns/1ps

module preBuffer (
	input clk,
	input reset_n,
	input [3:0] i_spike,
	input i_b_run,
	input i_valid,
	input i_stdp_run,
	output [23:0] o_spike_bundle,
	output o_valid,
	output o_syn_run,
	output [383:0] o_trace,
	output o_done,

	// x trace BRAM I/F
	output [63:0] d_r,
	output [4:0] addr_r,
	output [5:0] ce_r,
	output [5:0] we_r,
	input [383:0] q_r,
	
	output [63:0] d_w,
	output [4:0] addr_w,
	output [5:0] ce_w,
	output [5:0] we_w,
	input [383:0] q_w
);

wire s_idle;
wire s_stck;
wire s_send;

wire sr_stck;
wire sr_stdp;
wire sr_done;

wire row_ns;
wire row_done;
wire nrn_done;
wire cnt_done;
wire bram_idx_done;
wire addr_cnt_done;
wire access_done;

reg [63:0] x_trace;

reg [575:0] spike_buffer;
reg [23:0] bundle;
reg valid;
reg [4:0] row_cnt;
reg [4:0] nrn_cnt;
reg [7:0] cnt;

reg [3:0] spike_info;
reg [7:0] spike_slct;

reg [5:0] bram_idx;
reg [19:0] addr_cnt;

reg [1:0] sr_stck_buf;
reg sr_stdp_buf;
reg [1:0] sr_done_buf;
reg stdp_run_buf;

reg [2:0] access_done_buf;
reg [3:0] bram_run;
reg [1:0] sub_en;

reg [5:0] ce_rr;
reg [5:0] ce_ww;

reg [1:0] cs;
reg [1:0] ns;
reg [1:0] cs_r;
reg [1:0] ns_r;
reg [1:0] cs_w;
reg [1:0] ns_w;

localparam S_IDLE = 2'b00;
localparam S_STCK = 2'b01;
localparam S_SEND = 2'b10;
localparam S_STDP = 2'b10;
localparam S_DONE = 2'b11;

always @(*) begin
	ns = cs;
	case(cs)
		S_IDLE: begin
			if(i_b_run)
				ns = S_STCK;
			else if(stdp_run_buf)
				ns = S_SEND;
		end
		S_STCK:
			if(o_syn_run)
				ns = S_SEND;
		S_SEND:
			if(nrn_done && row_done)
				ns = S_DONE;
		S_DONE:
			ns = S_IDLE;
	endcase
end

always @(*) begin
	ns_r = cs_r;
	case(cs_r)
		S_IDLE: begin
			if(bram_run[0])
				ns_r = S_STCK;
			else if(i_stdp_run)
				ns_r = S_STDP;
		end
		S_STCK:
			if(access_done)
				ns_r = S_DONE;
		S_STDP:
			if(nrn_done && row_done)
				ns_r = S_DONE;
		S_DONE:
			ns_r = S_IDLE;
	endcase
end

always @(*) begin
	ns_w = cs_w;
	case(cs_w)
		S_IDLE: 
			if(bram_run[3])
				ns_w = S_STCK;
		S_STCK:
			if(access_done_buf[2])
				ns_w = S_DONE;
		S_DONE:
			ns_w = S_IDLE;
	endcase
end


always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cs = S_IDLE;
		cs_r = S_IDLE;
		cs_w = S_IDLE;
	end else begin
		cs = ns;
		cs_r = ns_r;
		cs_w = ns_w;
	end
end

assign s_idle = (cs == S_IDLE);
assign s_stck = (cs == S_STCK);
assign s_send = (cs == S_SEND);
assign o_done = (cs == S_DONE);
assign sr_stck = (cs_r == S_STCK);
assign sr_stdp = (cs_r == S_STDP);
assign sr_done = (cs_r == S_DONE);

// Buffer
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		stdp_run_buf <= 1'b0;
		sr_stck_buf <= 2'b0;
		sr_stdp_buf <= 1'b0;
		sr_done_buf <= 2'b0;
		sub_en <= 2'b0;
		bram_run <= 4'd0;
		bram_idx[5:3] <= 9'd0;
		addr_cnt[19:5] <= 15'd0;
		access_done_buf <= 3'd0;
	end else begin
		stdp_run_buf <= i_stdp_run;
		sr_stck_buf <= {sr_stck_buf[0], sr_stck};
		sr_stdp_buf <= sr_stdp;
		sr_done_buf <= {sr_done_buf[0], sr_done};
		sub_en <= {sub_en[0], sr_stck};
		bram_run[0] <= (cnt == 8'd144);
		bram_run[3:1] <= bram_run[2:0];
		bram_idx[5:3] <= bram_idx[2:0];
		addr_cnt[19:5] <= addr_cnt[14:0];
		access_done_buf <= {access_done_buf[1:0], access_done};
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		row_cnt <= 5'd0;
	end else begin
		if(s_send) begin
			if(row_done) begin
				row_cnt <= 5'd0;
			end else begin
				row_cnt <= row_cnt + 5'd1;
			end
		end else begin
			row_cnt <= 5'd0;
		end
	end
end

assign row_done = (row_cnt == 5'd23);
assign row_ns = (row_cnt == 5'd22);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		nrn_cnt <= 5'd0;
	end else begin
		if(s_send && row_done) begin
			if(nrn_cnt == 5'd18) begin
				nrn_cnt <= 5'd0;
			end else begin
				nrn_cnt <= nrn_cnt + 5'd1;
			end
		end else if(nrn_cnt == 5'd18) begin
			nrn_cnt <= 5'd0;
		end else begin
			nrn_cnt <= nrn_cnt;
		end
	end
end

assign nrn_done = (nrn_cnt == 5'd17);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cnt <= 8'd0;
	end else begin
		if(s_stck) begin
			if(cnt_done) begin
				cnt <= 8'd0;
			end else begin
				cnt <= cnt + 8'd1;
			end
		end else begin
			cnt <= 8'd0;
		end
	end
end

assign cnt_done = (cnt == 8'd144);
assign o_syn_run = (cnt == 8'd143);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		bram_idx[2:0] <= 3'd0;
	end else begin
		if (sr_stck) begin
			if(bram_idx_done) begin
				bram_idx[2:0] <= 3'd0;
			end else begin
				bram_idx[2:0] <= bram_idx[2:0] + 3'd1;
			end
		end else begin
			bram_idx[2:0] <= 3'd0;
		end
	end
end

assign bram_idx_done = (bram_idx[2:0] == 3'd5);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		addr_cnt[4:0] <= 5'd0;
	end else begin
		if (sr_stck) begin
			if(sr_done_buf[0]) begin
				addr_cnt[4:0] <= 5'd0;
			end else if(bram_idx_done) begin
				addr_cnt[4:0] <= addr_cnt[4:0] + 5'd1;
			end else begin
				addr_cnt[4:0] <= addr_cnt[4:0];
			end
		end else begin
			addr_cnt[4:0] <= 5'd0;
		end	
	end
end
		
assign addr_cnt_done = (addr_cnt[4:0] == 5'd23);
assign access_done = bram_idx_done && addr_cnt_done;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		spike_slct <= 8'd0;
	end else begin
		if (sr_stck_buf[0]) begin
			if(spike_slct == 8'd143) begin
				spike_slct <= 8'd0;
			end else begin
				spike_slct <= spike_slct + 8'd1;
			end
		end else begin
			spike_slct <= 8'd0;
		end
	end
end

// Shift register
genvar idx;
generate
	for(idx=0; idx<143; idx=idx+1) begin: gen_sr
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				spike_buffer[575:572] <= 4'b0;
				spike_buffer[idx*4 +: 4] <= 4'b0;
			end else begin
				if(i_valid && s_stck) begin
					spike_buffer[575:572] <= i_spike;
					spike_buffer[idx*4 +: 4] <= spike_buffer[(idx+1)*4 +: 4];
				end
			end
		end
	end
endgenerate

// Spike selector
genvar row_idx;
generate
	for(row_idx=0; row_idx<24; row_idx=row_idx+1) begin: gen_bdl
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				valid <= 1'b0;
				bundle[row_idx] <= 1'b0;
			end else begin 
				if(s_send) begin
					valid <= 1'b1;
					case(row_cnt)
						row_idx:
							bundle <= spike_buffer[row_idx*24 +: 24];
					endcase
				end else begin
					valid <= 1'b0;
					bundle[row_idx] <= 1'b0;
				end
			end
		end
	end
endgenerate

genvar spk_idx;
generate
	for(spk_idx=0; spk_idx<144; spk_idx=spk_idx+1) begin : gen_spk
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				spike_info <= 4'd0;
			end else begin
				if (sr_stck_buf[0]) begin
					case(spike_slct)
						spk_idx:
							spike_info <= spike_buffer[spk_idx*4 +: 4];
					endcase
				end else begin
					spike_info <= 4'd0;
				end
			end
		end
	end
endgenerate

assign o_spike_bundle = bundle;
assign o_valid = valid;

// x trace
reg [63:0] sub2_in_1;
reg [63:0] sub2_in_2;
wire [63:0] sub2_out;

genvar sub_idx;
generate
	for(sub_idx=0; sub_idx<4; sub_idx=sub_idx+1) begin : gen_sub
		assign sub2_out[sub_idx*16 +: 16] = sub2_in_1[sub_idx*16 +: 16] - sub2_in_2[sub_idx*16 +: 16];

		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				sub2_in_1[sub_idx*16 +: 16] <= 16'd0;
				sub2_in_2[sub_idx*16 +: 16] <= 16'd0;
			end else begin
				if(sub_en[1]) begin
					if(spike_info[sub_idx]) begin
						sub2_in_1[sub_idx*16 +: 16] <= 16'hffff;
						sub2_in_2[sub_idx*16 +: 16] <= 0;
					end else begin
						sub2_in_1[sub_idx*16 +: 16] <= x_trace[sub_idx*16 +: 16];
						sub2_in_2[sub_idx*16 +: 16] <= {4'd0, x_trace[(sub_idx*16+4) +: 12]};
					end
				end else begin
					sub2_in_1[sub_idx*16 +: 16] <= 16'd0;
					sub2_in_2[sub_idx*16 +: 16] <= 16'd0;
				end
			end
		end
	end
endgenerate

// BRAM I/F
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		ce_rr <= 6'd0;
	end else begin
		if(bram_run[0]) begin
			ce_rr <= 6'd1;
		end else if (sr_stck) begin
			if(access_done) begin
				ce_rr <= 6'd0;
			end else begin
				ce_rr <= {ce_rr[4:0], ce_rr[5]};
			end 
		end else begin
			ce_rr <= 6'd0;
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		ce_ww <= 6'd0;
	end else begin
		if(bram_run[3]) begin
			ce_ww <= 6'd1;
		end else if (cs_w == S_STCK) begin
			if (access_done_buf[2]) begin
				ce_ww <= 6'd0;
			end else begin
				ce_ww <= {ce_ww[4:0], ce_ww[5]};
			end
		end else begin
			ce_ww <= 6'd0;
		end
	end
end

genvar mux_idx;
generate
	for(mux_idx=0; mux_idx<6; mux_idx=mux_idx+1) begin : gen_mux
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				x_trace <= 64'd0;
			end else begin
				if(sr_stck_buf[0]) begin
					case(bram_idx[5:3])
						mux_idx:
							x_trace <= q_r[mux_idx*64 +: 64];
					endcase
				end else begin
					x_trace <= 64'd0;
				end
			end
		end
	end
endgenerate

assign d_r = 64'd0;
assign addr_r = sr_stdp ? row_cnt : addr_cnt[4:0];
assign ce_r = sr_stdp ? 5'd31 : ce_rr;
assign we_r = 6'b0;

assign d_w = sub2_out;
assign addr_w = addr_cnt[19:15];
assign ce_w = ce_ww;
assign we_w = ce_ww;

assign o_trace = sr_stdp_buf ? q_r : 384'd0;

endmodule
