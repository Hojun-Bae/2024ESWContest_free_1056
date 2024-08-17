`timescale 1ns/1ps

module lfsr (
	input				clk		,
	input				reset_n	,
	input				i_run	,
	input				i_rest_run	,
	output [3:0]		o_spike	,
	output				o_w_run ,
	output				o_valid	,

	// Image BRAM I/F
	output			[31:0]	d,
	output			[7:0]	addr,
	output					ce,
	output					we,
	input			[31:0]	q
);

wire s_run;
wire s_rest;
wire s_done;
(* DONT_TOUCH = "TRUE" *) wire [15:0] pixel [3:0];

(* DONT_TOUCH = "TRUE" *) wire [15:0] rand [3:0];
reg [15:0] lfsr [3:0];

reg [7:0] cnt;

reg [1:0] c_state;
reg [1:0] n_state;

reg [1:0] s_run_buf;
reg [1:0] s_rest_buf;
reg [3:0] spike;

localparam S_IDLE = 2'b00;
localparam S_RUN = 2'b01;
localparam S_REST = 2'b11;
localparam S_DONE = 2'b10;

always @(*) begin
	n_state = c_state;
	case(c_state)
		S_IDLE: begin
			if(i_run)
				n_state = S_RUN;
			if(i_rest_run)
				n_state = S_REST;
		end
		S_RUN:
			if(cnt == 8'd143)
				n_state = S_DONE;
		S_REST:
			if(cnt == 8'd143)
				n_state = S_DONE;
		S_DONE:
			n_state = S_IDLE;
	endcase
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		c_state <= S_IDLE;
	end else begin
		c_state <= n_state;
	end
end

assign s_run = (c_state == S_RUN);
assign s_rest = (c_state == S_REST);
assign s_done = (c_state == S_DONE);
assign o_valid = s_run_buf[1] || s_rest_buf[1];  

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cnt <= 8'd0;
	end else begin
		if(s_run || s_rest) begin
			cnt <= cnt + 8'd1;
		end else if(s_done) begin
			cnt <= 8'd0;
		end
	end
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		s_run_buf <= 2'b00;
		s_rest_buf <= 2'b00;
	end else begin
		s_run_buf <= {s_run_buf[0], s_run};
		s_rest_buf <= {s_rest_buf[0], s_rest};
	end
end

// BRAM I/F
assign d = 32'd0;
assign addr = cnt;
assign ce = s_run;
assign we = 1'b0;

// LFSR
genvar idx;
generate 
	for(idx=0; idx<4; idx=idx+1) begin : gen_ran
		assign pixel[idx] = {6'd0, q[idx*8 +: 8], 2'd0};
		assign rand[idx] = {lfsr[idx][1], lfsr[idx][6], lfsr[idx][3], lfsr[idx][13], lfsr[idx][11], lfsr[idx][8], lfsr[idx][2], lfsr[idx][0], lfsr[idx][15], lfsr[idx][4], lfsr[idx][7], lfsr[idx][5], lfsr[idx][14], lfsr[idx][10], lfsr[idx][12], lfsr[idx][9]};
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				lfsr[idx] <= (idx+1)*10000;
				spike[idx] <= 1'b0;
			end else begin
				if(s_run_buf[0]) begin
					lfsr[idx] <= {lfsr[idx][14:0], lfsr[idx][15] ^ lfsr[idx][13] ^ lfsr[idx][12] ^ lfsr[idx][10]};
					spike[idx] <= (pixel[idx] > rand[idx]) ? 1'b1 : 1'b0;
				end else begin
					lfsr[idx] <= lfsr[idx];
					spike[idx] <= 1'b0;
				end
			end
		end
	end
endgenerate

assign o_w_run = (s_run_buf[0] && (~s_run_buf[1])) || (s_rest_buf[0] && (~s_rest_buf[1]));
assign o_spike = spike;

endmodule

