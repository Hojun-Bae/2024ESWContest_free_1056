module spbram 
#(
	parameter DWIDTH = 16,
	parameter AWIDTH = 12,
	parameter MEM_SIZE = 3840
)
(
	clk, 
	addr, 
	en, 
	we, 
	q,
	d
);

input						clk;
input		[AWIDTH-1:0]	addr;
input						en;
input						we;
output reg	[DWIDTH-1:0]	q;
input		[DWIDTH-1:0]	d;

(* ram_style = "block" *)reg [DWIDTH-1:0] ram[0:MEM_SIZE-1];

always @(posedge clk)
begin
	if(en) begin
		if (we)
			ram[addr] <= d;
		else
			q <= ram[addr];
	end
end

endmodule
