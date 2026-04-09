module and_64(input logic [63:0] a_i, input logic [63:0] b_i, output logic [63:0] c_o);
    genvar i; 
    generate 
        for (i = 0; i < 64; i++) begin : gen_and_gates
            and and_inst (.a(a_i[i]), .b(b_i[i]), .c(c_o[i]), .en_i(en_i));
        end
    endgenerate
endmodule

module or_64(input logic [63:0] a_i, input logic [63:0] b_i, output logic [63:0] c_o);
    genvar i; 
    generate 
        for (i = 0; i < 64; i++) begin : gen_or_gates
            or or_inst (.a(a_i[i]), .b(b_i[i]), .c(c_o[i]), .en_i(en_i));
        end
    endgenerate
endmodule

module xor_64(input logic [63:0] a_i, input logic [63:0] b_i, output logic [63:0] c_o);
    genvar i; 
    generate 
        for (i = 0; i < 64; i++) begin : gen_xor_gates
            xor xor_inst (.a(a_i[i]), .b(b_i[i]), .c(c_o[i]), .en_i(en_i));
        end
    endgenerate
endmodule

module add_64(input logic [63:0] a_i, input logic [63:0] b_i, output logic [63:0] c_o);

module sub_64(input logic [63:0] a_i, input logic [63:0] b_i, output logic [63:0] c_o);