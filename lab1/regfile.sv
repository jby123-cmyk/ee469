module regfile(logic [63:0] ReadData1, ReadData2, WriteData
              ,logic [4:0] ReadRegister1, ReadRegister2, WriteRegister
              ,logic RegWrite, clk);
    logic [31:0][63:0] registers;

    mux32_1x64 mux1 (.z_o(read_data_1), .words_i(registers), .sel_i(read_addr_1));
    mux32_1x64 mux2 (.z_o(read_data_2), .words_i(registers), .sel_i(read_addr_2));

    logic [31:0] row_en;

    decoder5_32 decoder (.z_o(row_en), .dec_i(addr), .en(write_en));

    D_FF_32x64 dffs (.q(registers), .d(write_data), .reset(reset), .clk(clk), .row_en(row_en));
endmodule 