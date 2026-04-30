`timescale 1ns/10ps

module mux2_1(output logic z_o
			 ,input logic a_i, b_i
			 ,input logic sel_i);
	
	logic sel_i_n, sel_a, sel_b;
	
	not #0.050 sel_not (sel_i_n, sel_i);	
	nand #0.050 sel_a_mid (sel_a, sel_i_n, a_i); 
	nand #0.050 sel_b_mid (sel_b, sel_i, b_i);
	nand #0.050 out (z_o, sel_a, sel_b);
endmodule 

module mux4_1(output logic z_o
             ,input logic [3:0] mux_i
			 ,input logic [1:0] sel_i);
				 
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

module mux8_1(output logic z_o
             	,input logic [7:0] mux_i
             ,input logic [2:0] sel_i);
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

module mux16_1(output logic z_o
             ,input logic [15:0] mux_i
             ,input logic [3:0] sel_i);
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

module mux32_1(output logic z_o
              ,input logic [31:0] mux_i
              ,input logic [4:0] sel_i);
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

module mux32_1x64(output logic [63:0] z_o
				 ,input logic [31:0][63:0] words_i 
				 ,input logic [4:0] sel_i);
	
	genvar i, j;
	generate 
		for (i = 0; i < 64; i++) begin : gen_muxes
			logic [31:0] word_i;
			for (j = 0; j < 32; j++) begin : gen_words
				assign word_i[j] = words_i[j][i];
			end
			mux32_1 m (.z_o(z_o[i])
					  ,.mux_i(word_i)
				      ,.sel_i(sel_i));
		end
	endgenerate
endmodule 
