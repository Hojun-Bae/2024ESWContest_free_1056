`timescale 1ns/1ps

module findMax
#(
	parameter NUM = 18
)
(
	input clk,
	input reset_n,
	input i_cnt_en,
	input i_cnt_clr,
	input [NUM*7-1:0] i_cnt,

	output [4:0] o_idx,
	output [6:0] o_max
);

reg [4:0] idx;
reg [4:0] cnt;
reg [6:0] max;

wire [6:0] val [NUM-1:0];
wire cnt_done;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cnt <= 5'd0;
	end else begin
		if(i_cnt_en) begin
			cnt <= cnt_done ? 5'd0 : (cnt + 5'd1);
		end else begin
			cnt <= 5'd0;
		end
	end
end

assign cnt_done = (cnt == NUM-1);

genvar val_idx;
generate
	for(val_idx=0; val_idx<NUM; val_idx=val_idx+1) begin : gen_val
		assign val[val_idx] = i_cnt[val_idx*7 +: 7];
	end
endgenerate

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		idx <= 5'd0;
		max <= 7'd0;
	end else begin
		if(i_cnt_en) begin
			if(max < val[cnt]) begin
				max <= val[cnt];
				idx <= cnt;
			end else begin
				max <= max;
				idx <= idx;
			end
		end else if(i_cnt_clr) begin
			idx <= 5'd0;
			max <= 7'd0;
		end else begin
			max <= max;
			idx <= idx;
		end
	end
end

assign o_idx = idx;
assign o_max = max;

endmodule
