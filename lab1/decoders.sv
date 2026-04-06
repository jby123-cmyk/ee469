module decoder2_4(output [3:0] z_o
				 ,input [1:0] dec_i
				 ,input en);
						
	logic [1:0] dec_i_n;
	
	not n0 (dec_i_n[0], dec_i[0]);
	not n1 (dec_i_n[1], dec_i[1]);
	
	and a0 (z_o[0], dec_i_n[1], dec_i_n[0], en);
	and a1 (z_o[1], dec_i_n[1], dec_i[0], en);
	and a2 (z_o[2], dec_i[1], dec_i_n[0], en);
	and a3 (z_o[3], dec_i[1], dec_i[0], en);
endmodule 

module decoder3_8(output [7:0] z_o
				 ,input [2:0] dec_i
				 ,input en);
	
	logic [2:0] dec_i_n;
	
	not n0 (dec_i_n[0], dec_i[0]);
	not n1 (dec_i_n[1], dec_i[1]);
	not n2 (dec_i_n[2], dec_i[2]);

	and a0 (z_o[0], dec_i_n[2], dec_i_n[1], dec_i_n[0], en);
	and a1 (z_o[1], dec_i_n[2], dec_i_n[1], dec_i[0], en);
	and a2 (z_o[2], dec_i_n[2], dec_i[1], dec_i_n[0], en);
	and a3 (z_o[3], dec_i_n[2], dec_i[1], dec_i[0], en);
	and a4 (z_o[4], dec_i[2], dec_i_n[1], dec_i_n[0], en);
	and a5 (z_o[5], dec_i[2], dec_i_n[1], dec_i[0], en);
	and a6 (z_o[6], dec_i[2], dec_i[1], dec_i_n[0], en);
	and a7 (z_o[7], dec_i[2], dec_i[1], dec_i[0], en);
endmodule 


module decoder5_32(output [31:0] z_o
				  ,input [4:0] dec_i
				  ,input en);
	
	logic [3:0] d4_0_o;
	
	decoder2_4 d4_0 (.z_o(d4_0_o), .dec_i(dec_i[4:3]), .en(en)); 
	decoder3_8 d8_0 (.z_o(z_o[7:0]), .dec_i(dec_i[2:0]), .en(d4_0_o[0]));
	decoder3_8 d8_1 (.z_o(z_o[15:8]), .dec_i(dec_i[2:0]), .en(d4_0_o[1]));
	decoder3_8 d8_2 (.z_o(z_o[23:16]), .dec_i(dec_i[2:0]), .en(d4_0_o[2]));
	decoder3_8 d8_3 (.z_o(z_o[31:24]), .dec_i(dec_i[2:0]), .en(d4_0_o[3]));
endmodule 