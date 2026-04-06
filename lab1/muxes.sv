module mux2_1(output z_o
			 ,input a_i, b_i,
			 ,input sel_i);
	
	logic sel_i_n, sel_a, sel_b;
	
	not #50 sel_not (sel_i_n, sel_i);	
	nand #50 sel_a_mid (sel_a, sel_i_n, a_i); 
	nand #50 sel_b_mid (sel_b, sel_i, b_i);
	nand #50 out (z_o, sel_a, sel_b);
endmodule 

module mux4_1(output z_o
             ,input [3:0] mux_i
			 ,input [1:0] sel_i);
				 
	logic [1:0] mid;
	
	mux2_1 top (.z_o(mid[0]) 
			   ,.a_i(mux_i[0]) 
			   ,.b_i(mux_i[1])
			   ,.sel_i(sel_i[0]));
	mux2_1 bot (.z_o(mid[1])
			   ,.a_i(mux_i[2])
			   ,.b_i(mux_i[3])
			   ,.sel_i(sel_i[0]));
	mux2_1 out (.z_o(z_o)
	           ,.a_i(mid[0])
			   ,.b_i(mid[1])
			   ,.sel_i(sel_i[1]));
endmodule

module mux8_1(output z_o
             ,input [7:0] mux_i
             ,input [2:0] sel_i);
	logic [1:0] mid;
	
	mux4_1 top (.z_o(mid[0])
	           ,.mux_i(mux_i[3:0])
			   ,.sel_i(sel_i[1:0]));
	mux4_1 bot (.z_o(mid[1])
	           ,.mux_i(mux_i[7:4])
			   ,.sel_i(sel_i[1:0]));
	mux2_1 out (.z_o(z_o)
	           ,.a_i(mid[0])
			   ,.b_i(mid[1])
			   ,.sel_i(sel_i[2]));
endmodule

module mux16_1(output z_o
             ,input [15:0] mux_i
             ,input [3:0] sel_i);
	logic [1:0] mid;
	
	mux8_1 top (.z_o(mid[0])
	           ,.mux_i(mux_i[7:0])
			   ,.sel_i(sel_i[2:0]));
	mux8_1 bot (.z_o(mid[1])
	           ,.mux_i(mux_i[15:8])
			   ,.sel_i(sel_i[2:0]));
	mux2_1 out (.z_o(z_o)
	           ,.a_i(mid[0])
			   ,.b_i(mid[1])
			   ,.sel_i(sel_i[3]));
endmodule

module mux32_1(output z_o
              ,input [31:0] mux_i
              ,input [4:0] sel_i);
	logic [1:0] mid;
	
	mux16_1 top (.z_o(mid[0])
	            ,.mux_i(mux_i[15:0])
				,.sel_i(sel_i[3:0]));
	mux16_1 bot (.z_o(mid[1])
	            ,.mux_i(mux_i[31:16])
				,.sel_i(sel_i[3:0]));
	mux2_1 out (.z_o(z_o)
	           ,.a_i(mid[0])
			   ,.b_i(mid[1])
			   ,.sel_i(sel_i[4]));
endmodule 

module mux32_1x64(output [63:0] z_o
				 ,input [31:0][63:0] words_i 
				 ,input [4:0] sel_i);
	
	genvar i;
	generate 
		for (i = 0; i < 64; i++) begin : gen_muxes
			mux32_1 m (.z_o(z_o[i])
					  ,.mux_i(words_i[31:0][i])
				      ,.sel_i(sel_i));
		end
	endgenerate
endmodule 