module D_FF (q, d, reset, clk);
	output reg q;
	input d, reset, clk;
	always_ff @(posedge clk)
		if (reset)
			q <= 0; // On reset, set to 0
		else
			q <= d; // Otherwise out = d
endmodule 

module D_FF_64(input [63:0] d
			  ,input reset, en
			  ,input clk
			  ,output [63:0] q);
	
	genvar i;
	generate  
		for (i = 0; i < 64; i++) begin : gen_dffs
			logic mux_out;
			mux2_1 mux (.z_o(mux_out), .a_i(q[i]), .b_i(d[i]), .sel_i(en));
			D_FF dff (.q(q[i]), .d(mux_out), .reset(reset), .clk(clk));
		end
	endgenerate
endmodule 

module D_FF_32x64(input [63:0] d
				  ,input reset
				  ,input clk
				  ,input [31:0] row_en
				  ,output [31:0][63:0] q);
	
	genvar i;
	generate 
		for (i = 0; i < 31; i++) begin : gen_dffs
			D_FF_64 dff (.q(q[i]), .d(d), .reset(reset), .clk(clk), .en(row_en[i]));
		end
	endgenerate
	
	assign q[31] = 64'b0;
endmodule 