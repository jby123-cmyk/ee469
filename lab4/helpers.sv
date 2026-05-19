`timescale 1ns/10ps

module check_equal_5(
    output logic       z_o,
    input  logic [4:0] a_i,
    input  logic [4:0] b_i
);
    logic [4:0] xor_res;

    xor #0.050 xor_cmp [4:0] (xor_res, a_i, b_i);
    nor5_1 nor5_eq (.z_o(z_o), .a_i(xor_res));
endmodule

module check_not_equal_5(
    output logic       z_o,
    input  logic [4:0] a_i,
    input  logic [4:0] b_i
);
    logic [4:0] xor_res;

    xor #0.050 xor_cmp [4:0] (xor_res, a_i, b_i);
    or5_1 or5_neq (.z_o(z_o), .a_i(xor_res));
endmodule
