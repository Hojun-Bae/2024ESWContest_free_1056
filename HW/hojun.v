module hojun#
(
	// (hojun) Users to add parameters here
	parameter integer MEM0_DATA_WIDTH = 32,
	parameter integer MEM0_ADDR_WIDTH = 8,
	parameter integer MEM0_MEM_DEPTH  = 144,

	// User parameters ends
	// Do not modify the parameters beyond this line


	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 6 // (hojun) used #16 reg
)
(
	// Users to add ports here

	// User ports ends
	// Do not modify the ports beyond this line


	// Ports of Axi Slave Bus Interface S00_AXI
	input wire  s00_axi_aclk,
	input wire  s00_axi_aresetn,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready
);

// (hojun)
wire  				w_init;
wire  				w_lern;
wire  				w_infr;
wire   				w_idle;
wire   				w_running;
wire    			w_done;

// (hojun) Memory I/F
wire		[MEM0_ADDR_WIDTH-1:0] 	mem0_addr0;
wire		 						mem0_ce0;
wire		 						mem0_we0;
wire		[MEM0_DATA_WIDTH-1:0]  	mem0_q0;
wire		[MEM0_DATA_WIDTH-1:0] 	mem0_d0;
	
wire		[MEM0_ADDR_WIDTH-1:0] 	mem0_addr1;
wire		 						mem0_ce1;
wire		 						mem0_we1;
wire		[MEM0_DATA_WIDTH-1:0]  	mem0_q1;
wire		[MEM0_DATA_WIDTH-1:0] 	mem0_d1;

// (hojun) Output winner neuron result
wire		[7:0]					winner;

// Instantiation of Axi Bus Interface S00_AXI
	(* DONT_TOUCH = "TRUE" *) myip_v1_0 # ( 
		.MEM0_DATA_WIDTH (MEM0_DATA_WIDTH),
		.MEM0_ADDR_WIDTH (MEM0_ADDR_WIDTH),
		.MEM0_MEM_DEPTH  (MEM0_MEM_DEPTH ),
		.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_inst (
		// (hojun) Users to add ports here
		.o_init		(w_init),
		.o_lern		(w_lern),
		.o_infr		(w_infr),
		.i_idle		(w_idle),
		.i_running	(w_running),
		.i_done		(w_done),

		// (hojun) Users to add ports here
		.mem0_addr1			(mem0_addr1	),
		.mem0_ce1			(mem0_ce1	),
		.mem0_we1			(mem0_we1	),
		.mem0_q1			(mem0_q1	),
		.mem0_d1			(mem0_d1	),

		.i_winner			(winner		),

		.s00_axi_aclk	(s00_axi_aclk	),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr	(s00_axi_awaddr	),
		.s00_axi_awprot	(s00_axi_awprot	),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata	(s00_axi_wdata	),
		.s00_axi_wstrb	(s00_axi_wstrb	),
		.s00_axi_wvalid	(s00_axi_wvalid	),
		.s00_axi_wready	(s00_axi_wready	),
		.s00_axi_bresp	(s00_axi_bresp	),
		.s00_axi_bvalid	(s00_axi_bvalid	),
		.s00_axi_bready	(s00_axi_bready	),
		.s00_axi_araddr	(s00_axi_araddr	),
		.s00_axi_arprot	(s00_axi_arprot	),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata	(s00_axi_rdata	),
		.s00_axi_rresp	(s00_axi_rresp	),
		.s00_axi_rvalid	(s00_axi_rvalid	),
		.s00_axi_rready	(s00_axi_rready	)
	);

	// (hojun) Add user logic here
	(* DONT_TOUCH = "TRUE" *) snnTop	
	u_snnTop (
	    .clk			(s00_axi_aclk),
	    .rst_n			(s00_axi_aresetn),
		.i_init			(w_init),
		.i_lern			(w_lern),
		.i_infr			(w_infr),
		.o_winner		(winner),
		.o_idle			(w_idle),
		.o_running		(w_running),
		.o_done			(w_done),
		.d				(mem0_d0),
		.addr			(mem0_addr0),
		.ce				(mem0_ce0),
		.we				(mem0_we0),
		.q				(mem0_q0)
	);

	// (hojun) Add user logic here
	(* DONT_TOUCH = "TRUE" *) dpbram 
	#(	.DWIDTH   (MEM0_DATA_WIDTH), 
		.AWIDTH   (MEM0_ADDR_WIDTH), 
		.MEM_SIZE (MEM0_MEM_DEPTH)) 
	u_mem0(
		.clk		(s00_axi_aclk), 
	
	// USE Core 
		.addr0		(mem0_addr0    	), 
		.ce0		(mem0_ce0		), 
		.we0		(mem0_we0		), 
		.q0			(mem0_q0		), 
		.d0			(mem0_d0		), 
	
	// USE AXI4LITE
		.addr1 		(mem0_addr1 	), 
		.ce1		(mem0_ce1		), 
		.we1		(mem0_we1		),
		.q1			(mem0_q1		), 
		.d1			(mem0_d1		)
	);

endmodule

