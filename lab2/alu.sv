`timescale 1ns/10ps

module alu (input logic [63:0] A, B
           ,input logic [2:0] cntrl
           ,output logic [63:0] result
           ,output logic negative, zero, overflow, carry_out);

    logic [64:0] carry_out_bitslice;
    assign carry_out_bitslice[0] = cntrl[0];

    genvar i;
    generate 
        for (i = 0; i < 64; i++) begin : gen_bitslices
            alu_bitslice bitslice (.A(A[i])
                                  ,.B(B[i])
                                  ,.Cin(carry_out_bitslice[i])
                                  ,.cntrl(cntrl)
                                  ,.result(result[i])
                                  ,.carry_out(carry_out_bitslice[i+1])
                                );
        end
    endgenerate

    
    assign negative = result[63];
    assign carry_out = carry_out_bitslice[64];
    check_zero zero_checker (.result(result), .zero(zero));

    xor #0.050 overflow_checker (overflow, carry_out_bitslice[64], carry_out_bitslice[63]);
endmodule

module check_zero(input logic [63:0] result,
                  output logic zero);
    
    logic [15:0] or_res_0;
    logic [3:0] or_res_1;

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_ors_1
            nor #0.050 or_gate_0 (or_res_0[i], result[i*4+3], result[i*4+2], result[i*4+1], result[i*4]);
        end
    endgenerate

    generate 
        for (i=0; i < 4; i++) begin : gen_nors_0
            nand #0.050 or_gate_1 (or_res_1[i], or_res_0[i*4+3], or_res_0[i*4+2], or_res_0[i*4+1], or_res_0[i*4]);
        end
    endgenerate

    nor #0.050 nor_gate (zero, or_res_1[3:0]);
endmodule
