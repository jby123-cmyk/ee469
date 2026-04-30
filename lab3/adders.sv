`timescale 1ns/10ps

module branch_adder(input logic [63:0] pc_r,
                    input logic [25:0] imm,
                    output logic [63:0] pc_n);
    
    logic [64:0] carry_out_bitslice;
    assign carry_out_bitslice[0] = 1'b0;
    
    logic [63:0] imm_shifted;
    assign imm_shifted = {36'b0, imm[25:0], 2'b00};

    genvar i;
    generate 
        for (i = 0; i < 64; i++) begin : gen_bitslices
            full_adder adder (.A(pc_n[i])
                                  ,.B(imm_shifted[i])
                                  ,.Cin(carry_out_bitslice[i])
                                  ,.sum(pc_n[i])
                                  ,.carry_out(carry_out_bitslice[i+1])
                                );
        end
    endgenerate
endmodule

module pc_adder(input logic [63:0] pc_r,
                output logic [63:0] pc_n);
    

    logic [64:0] carry_out_bitslice;

    assign carry_out_bitslice[0] = 1'b0;

    logic [63:0] const_4;
    assign const_4 = 64'h4;

    genvar i;
    generate 
        for (i = 0; i < 64; i++) begin : gen_bitslices
            full_adder adder (.A(pc_n[i])
                                  ,.B(const_4[i])
                                  ,.Cin(carry_out_bitslice[i])
                                  ,.sum(pc_n[i])
                                  ,.carry_out(carry_out_bitslice[i+1])
                                );
        end
    endgenerate
endmodule