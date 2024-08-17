`timescale 1ns/1ps

module findMax 
#(
	parameter NUM = 18
)
(
	input clk,
	input reset_n,
	input en,
	input [NUM*7-1:0] i_cnt,

	output [4:0] o_idx,
	output [6:0] o_max,
	output o_valid
);

reg [4:0] idx;
reg [4:0] cnt;
reg [6:0] max;
reg valid;

wire cnt_done;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		cnt <= 5'd0;
	end else begin
		if(en) begin
			cnt <= cnt_done ? 5'd0 : (cnt + 5'd1);
		end else begin
			cnt <= 5'd0;
		end
	end
end

assign cnt_done = (cnt == NUM-1);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		valid <= 1'b0;
	end else begin
		valid <= cnt_done;
	end
end

genvar val_idx;
generate
	for(val_idx=0; val_idx<NUM; val_idx=val_idx+1) begin : gen_val
		always @(posedge clk or negedge reset_n) begin
			if(!reset_n) begin
				idx <= 5'd0;
				max <= 7'd0;
			end else begin
				if(en) begin
					case(cnt)
						val_idx : begin
							if(max < i_cnt[val_idx*7 +: 7]) begin
								max <= i_cnt[val_idx*7 +: 7];
								idx <= cnt;
							end else begin
								max <= max;
								idx <= idx;
							end
						end
					endcase
				end else begin
					max <= max;
					idx <= idx;
				end
			end
		end
	end
endgenerate

assign o_idx = idx;
assign o_max = max;
assign o_valid = valid;

endmodule
