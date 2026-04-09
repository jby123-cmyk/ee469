module alu (input logic [63:0] A, B
           ,input logic [2:0] cntrl
           ,output logic [63:0] result
           ,output logic negative, zero, overflow, carry_out);

    logic [8:0][63:0] words_i;
    assign words_i[0] = B;
    assign words_i[1] = ;
    assign words_i[2] = ;
    assign words_i[3] = A | B;
    assign words_i[4] = A ^ B;
    assign words_i[5] = A + B;
    assign words_i[6] = A - B;
    assign words_i[7] = A & B;

    mux_8_1x64 output_sel (.z_o(result), .words_i(words_i), .sel_i(cntrl));
endmodule
