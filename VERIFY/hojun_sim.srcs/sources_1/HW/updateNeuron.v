`timescale 1ns/1ps

module updateNeuron

(
	input					clk,
	input					reset_n,

	input					i_run,
	input					i_init,
	input					i_s_lern,
	input					i_s_infr,

	input	signed [24:0]  exc_current,
	input	signed [24:0]  inh_current,

	output 					o_s_init,
	output					o_spike,
	output					o_valid,
	output			[4:0]	o_neuron_idx,

	// CONDUCTANCE/REFRACTORY BRAM I/F
	output			[49:0]	d_c,
	output			[4:0]	addr_c,
	output					ce_c,
	output					we_c,
	input			[49:0]	q_c,

	// MEMBRANE POTENTIAL/THRESHOLD/REFRACTORY BRAM I/F
	output			[54:0]	d_m,
	output			[4:0]	addr_m,
	output					ce_m,
	output					we_m,
	input			[54:0]	q_m
);

wire s_idle;
wire s_init;
wire s_read;
wire s_calc;
wire s_wrte;
wire s_done;

reg [3:0] fsm;
reg [2:0] c_state;
reg [2:0] n_state;

reg [4:0] neuron_idx;

reg signed [24:0] exc_cur_buf;
reg signed [24:0] inh_cur_buf;

wire signed [24:0] c_ge;
wire signed [24:0] c_gi;
wire signed [24:0] c_vm;
wire signed [24:0] c_vt;
wire c_ref_check;
wire [3:0] c_ref_count;

wire signed [24:0] e_rest = 25'd5242880;	// 80
wire signed [24:0] e_exc = 25'd6881280;		// 105
wire signed [24:0] e_inh = 25'd3604480;		// 55 
wire signed [24:0] thresh_add  = 25'd11240;	// 0.03125 
wire signed [24:0] inh_max = 25'd655360;	// 10 

reg signed [24:0] mult_1_in_1;
reg signed [17:0] mult_1_in_2;
reg signed [24:0] mult_2_in_1;
reg signed [17:0] mult_2_in_2;

reg signed [24:0] add_max;	
reg signed [42:0] mult_1_out;
reg signed [42:0] mult_2_out;

reg signed [24:0] n_ge;
reg signed [24:0] n_gi;
reg signed [24:0] n_vm;
reg signed [24:0] n_vt;

reg n_ref_check;
reg [3:0] n_ref_count;

reg fire;


localparam S_IDLE = 3'b000;
localparam S_READ = 3'b001;
localparam S_CALC = 3'b010;
localparam S_WRTE = 3'b011;
localparam S_INIT = 3'b111;
localparam S_DONE = 3'b100;

// Current buffer
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		exc_cur_buf <= 25'd0;
		inh_cur_buf <= 25'd0;
	end else if(i_run) begin
		exc_cur_buf <= exc_current;
		inh_cur_buf <= inh_current;
	end
end

// FSM
always @(*) begin
	n_state = c_state;
	case(c_state)
		S_IDLE: begin
			if(i_run)
				n_state = S_READ;
			if(i_init)
				n_state = S_INIT;
		end 
		S_INIT:
			if(neuron_idx == 5'd17) 
				n_state = S_IDLE;
		S_READ:
			n_state = S_CALC;
		S_CALC:
			if(fsm == 4'd9)
				n_state = S_WRTE;
		S_WRTE:
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

assign s_idle = (c_state == S_IDLE);
assign s_init = (c_state == S_INIT);
assign s_read = (c_state == S_READ);
assign s_calc = (c_state == S_CALC);
assign s_wrte = (c_state == S_WRTE);
assign s_done = (c_state == S_DONE);

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		fsm <= 4'd0;
	end else begin
		if(s_calc) begin
			fsm <= fsm + 4'd1;
		end else begin
			fsm <= 4'd0;
		end
	end
end

// Neuron index
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		neuron_idx <= 5'd0;
	end else begin
		if(s_done || s_init) begin
			if(neuron_idx == 5'd17) begin
				neuron_idx <= 5'd0;
			end else begin
				neuron_idx <= neuron_idx + 5'd1;
			end
		end else begin
			neuron_idx <= neuron_idx;
		end
	end
end

// Adder 
reg signed [24:0] add2_1_in_1;
reg signed [24:0] add2_1_in_2;
reg signed [24:0] add2_2_in_1;
reg signed [24:0] add2_2_in_2;
reg signed [24:0] add3_1_in_1;
reg signed [24:0] add3_1_in_2;
reg signed [24:0] add3_1_in_3;
reg signed [24:0] add3_2_in_1;
reg signed [24:0] add3_2_in_2;
reg signed [24:0] add3_2_in_3;

(* dont_touch = "true" *) wire signed [24:0] add2_1_out;
(* dont_touch = "true" *) wire signed [24:0] add2_2_out;
(* dont_touch = "true" *) wire signed [24:0] add3_1_out;
(* dont_touch = "true" *) wire signed [24:0] add3_2_out;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		add2_1_in_1 <= 25'd0;
		add2_1_in_2 <= 25'd0;
		add2_2_in_1 <= 25'd0;
		add2_2_in_2 <= 25'd0;
		add3_1_in_1 <= 25'd0;
		add3_1_in_2 <= 25'd0;
		add3_1_in_3 <= 25'd0;
		add3_2_in_1 <= 25'd0;
		add3_2_in_2 <= 25'd0;
		add3_2_in_3 <= 25'd0;
	end else begin
		case (fsm)
			4'd0: begin
				add2_1_in_1 <= 25'd0;
				add2_1_in_2 <= 25'd0;
				add2_2_in_1 <= 25'd0;
				add2_2_in_2 <= 25'd0;
				add3_1_in_1 <= 25'd0;
				add3_1_in_2 <= 25'd0;
				add3_1_in_3 <= 25'd0;
				add3_2_in_1 <= 25'd0;
				add3_2_in_2 <= 25'd0;
				add3_2_in_3 <= 25'd0;
			end
			4'd1: begin
				add2_1_in_1 <= 25'd0;		
				add2_1_in_2 <= 25'd0;
				add2_2_in_1 <= 25'd0;		
				add2_2_in_2 <= 25'd0;
				add3_1_in_1 <= 25'd0;
				add3_1_in_2 <= 25'd0;
				add3_1_in_3 <= 25'd0;
				add3_2_in_1 <= c_ref_check ? 25'd0 : c_gi;
				add3_2_in_2 <= c_ref_check ? 25'd0 : inh_cur_buf;
				add3_2_in_3 <= c_ref_check ? 25'd0 : -{{5{c_gi[24]}}, c_gi[23:4]};
			end
			4'd2: begin
				if(!c_ref_check) begin
					// E_EXC - v[n]
					add2_1_in_1 <= e_exc;		// E_EXC, 105
					add2_1_in_2 <= -c_vm;
					// E_INH - v[n]
					add2_2_in_1 <= e_inh;		// E_INH, 55
					add2_2_in_2 <= -c_vm;
					// ge[n] - dge/dt[n]/tau + I_exc 
					add3_1_in_1 <= c_ge;
					add3_1_in_2 <= exc_cur_buf;
					add3_1_in_3 <= -{{4{c_ge[24]}}, c_ge[23:3]};
					// gi[n] - dgi/dt[n]/tau + I_inh 
					add3_2_in_1 <= add3_2_in_1;
					add3_2_in_2 <= add3_2_in_2;
					add3_2_in_3 <= add3_2_in_3;
				end else begin
					// E_EXC - v[n]
					add2_1_in_1 <= 25'd0;		// E_EXC, 105
					add2_1_in_2 <= 25'd0;
					// E_INH - v[n]
					add2_2_in_1 <= 25'd0;		// E_INH, 55
					add2_2_in_2 <= 25'd0;
					// ge[n] - dge/dt[n]/tau + I_exc 
					add3_1_in_1 <= 25'd0;
					add3_1_in_2 <= 25'd0;
					add3_1_in_3 <= 25'd0;
					// gi[n] - dgi/dt[n]/tau + I_inh 
					add3_2_in_1 <= 25'd0;
					add3_2_in_2 <= 25'd0;
					add3_2_in_3 <= 25'd0;
				end
			end
			4'd3: begin
				add2_1_in_1 <= add2_1_in_1;		
				add2_1_in_2 <= add2_1_in_2;
				//	
				add2_2_in_1 <= add2_2_in_1;		
				add2_2_in_2 <= add2_2_in_2;
				//		
				add3_1_in_1 <= add3_1_in_1;
				add3_1_in_2 <= add3_1_in_2;
				add3_1_in_3 <= add3_1_in_3;
				//		
				add3_2_in_1 <= add3_2_in_1;
				add3_2_in_2 <= add3_2_in_2;
				add3_2_in_3 <= add3_2_in_3;
			end
			4'd4: begin
				if(!c_ref_check) begin
					// E_REST - v[n]
					add2_1_in_1 <= e_rest;		// E_REST, 80
					add2_1_in_2 <= -c_vm;
					//	
					add2_2_in_1 <= add2_2_in_1;		
					add2_2_in_2 <= add2_2_in_2;
					//		
					add3_1_in_1 <= add3_1_in_1;
					add3_1_in_2 <= add3_1_in_2;
					add3_1_in_3 <= add3_1_in_3;
					//		
					add3_2_in_1 <= add3_2_in_1;
					add3_2_in_2 <= add3_2_in_2;
					add3_2_in_3 <= add3_2_in_3;
				end else begin
					// E_REST - v[n]
					add2_1_in_1 <= 25'd0;		
					add2_1_in_2 <= 25'd0;
					//	
					add2_2_in_1 <= add2_2_in_1;		
					add2_2_in_2 <= add2_2_in_2;
					//		
					add3_1_in_1 <= add3_1_in_1;
					add3_1_in_2 <= add3_1_in_2;
					add3_1_in_3 <= add3_1_in_3;
					//		
					add3_2_in_1 <= add3_2_in_1;
					add3_2_in_2 <= add3_2_in_2;
					add3_2_in_3 <= add3_2_in_3;
				end
			end
			4'd5: begin
				// E_REST - vth[n]
				add2_1_in_1 <= i_s_lern ? e_rest : 25'd0;		// E_REST, 80
				add2_1_in_2 <= i_s_lern ? -c_vt : 25'd0;
				//	
				add2_2_in_1 <= add2_2_in_1;		
				add2_2_in_2 <= add2_2_in_2;
				// Parallel Add
				add3_1_in_1 <= mult_1_out >>> 9;
				add3_1_in_2 <= mult_2_out >>> 9;
				add3_1_in_3 <= add2_1_out;
				//		
				add3_2_in_1 <= add3_2_in_1;
				add3_2_in_2 <= add3_2_in_2;
				add3_2_in_3 <= add3_2_in_3;
			end
			4'd6: begin
				if(!c_ref_check) begin
					// Membrane potential
					add2_1_in_1 <= c_vm;
					add2_1_in_2 <= {{9{add3_1_out[24]}}, add3_1_out[23:8]};
					// Threshold
					add2_2_in_1 <= c_vt;
					add2_2_in_2 <= {{18{add2_1_out[24]}}, add2_1_out[23:17]};
					//		
					add3_1_in_1 <= add3_1_in_1;
					add3_1_in_2 <= add3_1_in_2;
					add3_1_in_3 <= add3_1_in_3;
					//		
					add3_2_in_1 <= add3_2_in_1;
					add3_2_in_2 <= add3_2_in_2;
					add3_2_in_3 <= add3_2_in_3;
				end else begin
					// Membrane potential
					add2_1_in_1 <= c_vm;
					add2_1_in_2 <= 25'd0;
					// Threshold
					add2_2_in_1 <= c_vt;
					add2_2_in_2 <= {{18{add2_1_out[24]}}, add2_1_out[23:17]};
					//		
					add3_1_in_1 <= add3_1_in_1;
					add3_1_in_2 <= add3_1_in_2;
					add3_1_in_3 <= add3_1_in_3;
					//		
					add3_2_in_1 <= add3_2_in_1;
					add3_2_in_2 <= add3_2_in_2;
					add3_2_in_3 <= add3_2_in_3;
				end
			end
			4'd7: begin
				add2_1_in_1 <= add2_1_in_1;
				add2_1_in_2 <= add2_1_in_2;
				add2_2_in_1 <= add2_2_in_1;
				add2_2_in_2 <= add2_2_in_2;
				add3_1_in_1 <= add3_1_in_1;
				add3_1_in_2 <= add3_1_in_2;
				add3_1_in_3 <= add3_1_in_3;
				add3_2_in_1 <= add3_2_in_1;
				add3_2_in_2 <= add3_2_in_2;
				add3_2_in_3 <= add3_2_in_3;
			end
			4'd8: begin
				if(fire) begin
					add2_1_in_1 <= i_s_infr ? 25'd0 : thresh_add;		// 0.03125
					add2_1_in_2 <= n_vt;
					//	
					add2_2_in_1 <= add2_2_in_1;		
					add2_2_in_2 <= add2_2_in_2;
					//		
					add3_1_in_1 <= add3_1_in_1;
					add3_1_in_2 <= add3_1_in_2;
					add3_1_in_3 <= add3_1_in_3;
					//		
					add3_2_in_1 <= add3_2_in_1;
					add3_2_in_2 <= add3_2_in_2;
					add3_2_in_3 <= add3_2_in_3;
				end else begin
					// 
					add2_1_in_1 <= add2_1_in_1;		
					add2_1_in_2 <= add2_1_in_2;
					//	
					add2_2_in_1 <= add2_2_in_1;		
					add2_2_in_2 <= add2_2_in_2;
					//		
					add3_1_in_1 <= add3_1_in_1;
					add3_1_in_2 <= add3_1_in_2;
					add3_1_in_3 <= add3_1_in_3;
					//		
					add3_2_in_1 <= add3_2_in_1;
					add3_2_in_2 <= add3_2_in_2;
					add3_2_in_3 <= add3_2_in_3;
				end
			end
			default: begin
				add2_1_in_1 <= add2_1_in_1;
				add2_1_in_2 <= add2_1_in_2;
				add2_2_in_1 <= add2_2_in_1;
				add2_2_in_2 <= add2_2_in_2;
				add3_1_in_1 <= add3_1_in_1;
				add3_1_in_2 <= add3_1_in_2;
				add3_1_in_3 <= add3_1_in_3;
				add3_2_in_1 <= add3_2_in_1;
				add3_2_in_2 <= add3_2_in_2;
				add3_2_in_3 <= add3_2_in_3;
			end
		endcase
	end
end

assign add2_1_out = add2_1_in_1 + add2_1_in_2;
assign add2_2_out = add2_2_in_1 + add2_2_in_2;
assign add3_1_out = add3_1_in_1 + add3_1_in_2 + add3_1_in_3;
assign add3_2_out = add3_2_in_1 + add3_2_in_2 + add3_2_in_3;

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		add_max <= 25'd0;
	end else begin
		if(fsm == 4'd2) begin
			add_max <= (inh_max < add3_2_out) ? inh_max : add3_2_out;
		end else if(fsm == 4'd8) begin
			add_max <= 25'd0;
		end else begin
			add_max <= add_max;
		end
	end
end

// Multiplier
always @(posedge clk) begin
	mult_1_out <= mult_1_in_1 * mult_1_in_2;
	mult_2_out <= mult_2_in_1 * mult_2_in_2;
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		mult_1_in_1 <= 25'd0;  
		mult_1_in_2 <= 18'd0; 
		mult_2_in_1 <= 25'd0; 
		mult_2_in_2 <= 18'd0; 
	end else begin
		if(fsm == 4'd3) begin
			mult_1_in_1 <= add3_1_out;  
			mult_1_in_2 <= add2_1_out[24:7]; 
			mult_2_in_1 <= add_max; 
			mult_2_in_2 <= add2_2_out[24:7]; 
		end else begin
			mult_1_in_1 <= 25'd0;  
			mult_1_in_2 <= 18'd0; 
			mult_2_in_1 <= 25'd0; 
			mult_2_in_2 <= 18'd0; 
		end
	end
end

// Neuron state 
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		n_ge <= 25'd0;
		n_gi <= 25'd0;
		n_vm <= 25'd0;
		n_vt <= 25'd0;
		fire <= 1'd0;
		n_ref_check <= 1'b0;
		n_ref_count <= 4'd0;
	end else begin 
		case (fsm)
			4'd1: begin
				n_ge <= c_ge;
				n_gi <= c_gi;
				n_vm <= c_vm;
				n_vt <= c_vt;
				fire <= 1'b0;
				n_ref_check <= c_ref_check;
				n_ref_count <= c_ref_count;
			end
			4'd3: begin
				n_ge <= add3_1_out;
				n_gi <= add_max;
			end
			4'd5: begin
				if(n_ref_check) begin
					n_ref_count <= n_ref_count + 4'd1;
				end else begin
					n_ref_count <= n_ref_count;
				end
			end
			4'd7: begin
				n_vm <= add2_1_out;
				n_vt <= add2_2_out;
				if(add2_1_out > add2_2_out) begin
					fire <= 1'b1;
					n_ref_check <= 1'b1;
					n_ge <= 25'd0;
					n_gi <= 25'd0;
				end
			end
			4'd9: begin
				if(fire) begin
					n_vm <= e_rest;		// E_REST, 80
					n_vt <= add2_1_out;
				end
				if(n_ref_count == 4'd11) begin
					n_ref_check <= 1'b0;
					n_ref_count <= 4'd0;
				end
			end
		endcase
	end
end

// BRAM I/F
assign ce_c = s_init || s_read || s_wrte;
assign we_c = s_init || s_wrte; 
assign ce_m = s_init || s_read || s_wrte;
assign we_m = s_init || s_wrte;

assign addr_c = neuron_idx;
assign addr_m = neuron_idx;

assign d_c = s_init ? 50'd0 : {n_ge, n_gi};
assign d_m = s_init ? {1'b0, 4'd0, e_rest, 25'd5406720} : {n_ref_check, n_ref_count, n_vm, n_vt};

assign c_ge = q_c[49:25];
assign c_gi = q_c[24:0];
assign c_vm = q_m[49:25];
assign c_vt = q_m[24:0];

assign c_ref_check = q_m[54];
assign c_ref_count = q_m[53:50];

assign o_s_init = s_init;
assign o_spike = fire;
assign o_valid = s_done;
assign o_neuron_idx = neuron_idx;

endmodule

