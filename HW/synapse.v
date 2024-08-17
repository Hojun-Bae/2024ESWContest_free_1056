`timescale 1ns/1ps

module synapse 
#(
	parameter SEED = 1000
)
(
	input					clk				,
	input					rst_n			,
	input					i_run			,
	input					i_wegt_rst		,
	output 		[24:0]		o_current		,
	output					o_valid			,
	output					o_done			,

	// BRAM I/F
	output 		[383:0] 	d				,
	output 		[53:0] 		addr			,
	output 		[5:0] 		ce				,
	output 		[5:0] 		we				,
	input 		[383:0] 	q				,

	// Spike input
	input 		[23:0] 		i_spike_bundle	,
	input 					i_valid
);

localparam S_IDLE 	= 		2'b00			;
localparam S_RUN 	= 		2'b01			;
localparam S_RST 	= 		2'b10			;
localparam S_DONE 	= 		2'b11			;

reg 				is_single_done_buf		;
reg 	[2:0] 		fresh					;

reg 	[149:0] 	accum_part				;
reg 	[24:0] 		accum					;
reg 	[149:0] 	sum						;

reg 	[9:0] 		addr_cnt				;
reg 	[4:0] 		fresh_cnt				;

reg 	[1:0] 		s_run_buf				;
reg 	[1:0] 		o_done_buf				;

reg 	[1:0] 		c_state					;
reg 	[1:0] 		n_state					;

reg 	[15:0] 		lfsr 		[23:0]		;
wire 	[15:0] 		rand 		[23:0]		;

wire 				is_read_done			;
wire 				is_single_done			;

wire 				s_rst					;
wire 				s_run					;
wire 				s_idle					;

(* DONT_TOUCH = "TRUE" *) wire 		[383:0] 	cdtc;
(* DONT_TOUCH = "TRUE" *) wire 		[24:0] 		total;

(* DONT_TOUCH = "TRUE" *) wire 		[24:0] 		spike_bundle;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		c_state <= S_IDLE;
	end else begin
		c_state <= n_state;
	end
end

always @(*) begin
	n_state = c_state;
	case(c_state)
		S_IDLE: begin
			if(i_run)
				n_state = S_RUN;
			else if(i_wegt_rst)
				n_state = S_RST;
		end
		S_RUN:
			if(is_read_done)
				n_state = S_DONE;
		S_RST:
			if(is_read_done)
				n_state = S_DONE;
		S_DONE:
			n_state = S_IDLE;
	endcase
end

assign s_idle = (c_state == S_IDLE);
assign s_run = (c_state == S_RUN);
assign s_rst = (c_state == S_RST);
assign o_done = (c_state == S_DONE);

// BRAM I/F
assign is_read_done = (s_run || s_rst) && (addr_cnt == 431);

assign is_single_done = s_run && (fresh_cnt == 23);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_cnt <= 0;
	end else if(is_read_done) begin
		addr_cnt <= 0;
	end else if(s_run || s_rst) begin
		addr_cnt <= addr_cnt + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		fresh_cnt <= 0;
	end else if(is_single_done) begin
		fresh_cnt <= 0;
	end else if(s_run) begin
		fresh_cnt <= fresh_cnt + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		s_run_buf <= 2'b0;
		o_done_buf <= 2'b00;
	end else begin
		s_run_buf <= {s_run_buf[0], s_run};
		o_done_buf <= {o_done_buf[0], o_done};
	end
end

assign total = accum_part[0*25 +: 25] + accum_part[1*25 +: 25] + accum_part[2*25 +: 25] + accum_part[3*25 +: 25] + accum_part[4*25 +: 25] + accum_part[5*25 +: 25];

assign spike_bundle = i_valid ? i_spike_bundle : 24'd0;

genvar i;
generate
	for(i=0; i<6; i=i+1) begin : gen_memif
		assign addr[i*9 +: 9] = addr_cnt;
		assign ce[i] = s_run || s_rst;
		assign we[i] = s_rst;
		
		// Accumulation
		assign cdtc[(i*64 + 16*0) +: 16] = spike_bundle[i*4+0] ? q[(i*64 + 16*0) +: 16] : 16'd0;
		assign cdtc[(i*64 + 16*1) +: 16] = spike_bundle[i*4+1] ? q[(i*64 + 16*1) +: 16] : 16'd0;
		assign cdtc[(i*64 + 16*2) +: 16] = spike_bundle[i*4+2] ? q[(i*64 + 16*2) +: 16] : 16'd0;
		assign cdtc[(i*64 + 16*3) +: 16] = spike_bundle[i*4+3] ? q[(i*64 + 16*3) +: 16] : 16'd0;

        always @(posedge clk or negedge rst_n) begin
			if(!rst_n) begin
			    sum[i*25 +: 25] <= 25'd0;
			end else begin
			    sum[i*25 +: 25] <= cdtc[(i*64 + 0) +: 16] + cdtc[(i*64 + 16) +: 16] + cdtc[(i*64 + 32) +: 16] + cdtc[(i*64 + 48) +: 16];
			end
		end

		always @(posedge clk or negedge rst_n) begin
			if(!rst_n) begin
				accum_part[i*25 +: 25] <= 25'd0;
			end else if(o_done_buf[1]) begin
				accum_part[i*25 +: 25] <= 25'd0;
			end else if(fresh[1]) begin
				accum_part[i*25 +: 25] <= sum[i*25 +: 25];
			end else if(s_run_buf[1]) begin
				accum_part[i*25 +: 25] <= accum_part[i*25 +: 25] + sum[i*25 +: 25];
			end
		end
	end
endgenerate

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		accum <= 25'd0;
	end else begin
		accum <= total;
	end
end

assign o_valid = fresh[2];
assign o_current = o_valid ? accum : 0;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		is_single_done_buf <= 1'b0;
		fresh <= 3'd0;
	end else begin
		is_single_done_buf <= is_single_done;
		fresh <= {fresh[1:0], is_single_done_buf};
	end
end

//
genvar idx;
generate
	for(idx=0; idx<24; idx=idx+1) begin : gen_ran
		assign d[idx*16 +: 16] = rand[idx];
		assign rand[idx] = {2'd0, lfsr[idx][1], lfsr[idx][6], lfsr[idx][3], lfsr[idx][13], lfsr[idx][11], lfsr[idx][8], lfsr[idx][2], lfsr[idx][0], lfsr[idx][15], lfsr[idx][4], lfsr[idx][7], lfsr[idx][5], lfsr[idx][14], lfsr[idx][10]};
		always @(posedge clk or negedge rst_n) begin
			if(!rst_n) begin
				lfsr[idx] <= SEED + idx*101 +10000;
			end else begin
				if(s_rst) begin
					lfsr[idx] <= {lfsr[idx][14:0], lfsr[idx][15] ^ lfsr[idx][13] ^ lfsr[idx][12] ^ lfsr[idx][10]};
				end else begin
					lfsr[idx] <= lfsr[idx];
				end
			end
		end
	end
endgenerate

endmodule
