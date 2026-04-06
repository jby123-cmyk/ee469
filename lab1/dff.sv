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
			  ,input reset
			  ,input clk
			  ,output [63:0] q);
	generate (genvar i) 
		for (i = 0; i < 64; i++) begin : gen_dffs
			D_FF dff (.q(q[i]), .d(d[i]), .reset(reset), .clk(clk));
		end
	endgenerate
endmodule 

module D_FF_32x64(input [31:0][63:0] d
				  ,input reset
				  ,input clk
				  ,output [31:0][63:0] q);
	generate (genvar i) 
		for (i = 0; i < 32; i++) begin : gen_dffs
			D_FF_64 dff (.q(q[i]), .d(d[i]), .reset(reset), .clk(clk));
		end
	endgenerate
endmodule 