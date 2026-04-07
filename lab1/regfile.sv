module regfile(output logic [63:0] ReadData1, ReadData2
              ,input logic [63:0] WriteData
              ,input logic [4:0] ReadRegister1, ReadRegister2, WriteRegister
              ,input logic RegWrite, clk);
    logic [31:0][63:0] registers;

    mux32_1x64 mux1 (.z_o(ReadData1), .words_i(registers), .sel_i(ReadRegister1));
    mux32_1x64 mux2 (.z_o(ReadData2), .words_i(registers), .sel_i(ReadRegister2));

    logic [31:0] row_en;

    decoder5_32 decoder (.z_o(row_en), .dec_i(WriteRegister), .en_i(RegWrite));

    D_FF_32x64 dffs (.q(registers), .d(WriteData), .reset(1'b0), .clk(clk), .row_en(row_en));
endmodule 
