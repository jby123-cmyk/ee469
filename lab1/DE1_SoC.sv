module DE1_SoC(input clk
              ,input reset, write_en
              ,input [4:0] addr
              ,input [63:0] write_data
              ,input [4:0] read_addr_1, read_addr_2
              ,output [63:0] read_data_1, read_data_2);
    
    logic [31:0][63:0] reg_file;

    mux32_1x64 mux1 (.z_o(read_data_1), .words_i(reg_file), .sel_i(read_addr_1));
    mux32_1x64 mux2 (.z_o(read_data_2), .words_i(reg_file), .sel_i(read_addr_2));

    logic [31:0] row_en;

    decoder5_32 decoder (.z_o(row_en), .dec_i(addr), .en(write_en));

    D_FF_32x64 dffs (.q(reg_file), .d(write_data), .reset(reset), .clk(clk), .row_en(row_en));
endmodule 