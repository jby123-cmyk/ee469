`timescale 1ns/10ps

module check_equal_5(
    output logic       z_o,
    input  logic [4:0] a_i,
    input  logic [4:0] b_i
);
    logic [4:0] xor_res;

    xor #0.050 xor_cmp [4:0] (xor_res, a_i, b_i);
    nor #0.050 nor_eq (z_o, xor_res[4], xor_res[3], xor_res[2], xor_res[1], xor_res[0]);
endmodule

module check_not_equal_5(
    output logic       z_o,
    input  logic [4:0] a_i,
    input  logic [4:0] b_i
);
    logic [4:0] xor_res;

    xor #0.050 xor_cmp [4:0] (xor_res, a_i, b_i);
    or #0.050 or_neq (z_o, xor_res[4], xor_res[3], xor_res[2], xor_res[1], xor_res[0]);
endmodule
