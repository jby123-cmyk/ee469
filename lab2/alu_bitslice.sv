`timescale 1ns/10ps

module alu_bitslice(input logic A, B, Cin,
                    input logic [2:0] cntrl,
                    output logic result,
                    output logic carry_out);
    // cntrl			Operation						Notes:
    // 000:			result = B						value of overflow and carry_out unimportant
    // 010:			result = A + B
    // 011:			result = A - B
    // 100:			result = bitwise A & B		value of overflow and carry_out unimportant
    // 101:			result = bitwise A | B		value of overflow and carry_out unimportant
    // 110:			result = bitwise A XOR B	value of overflow and carry_out unimportant

    logic and_res, or_res, xor_res;

    and #0.050 and_gate (and_res, A, B);
    or #0.050 or_gate (or_res, A, B);
    xor #0.050 xor_gate (xor_res, A, B);

    logic B_sel;
    xor #0.050 sub_sel (B_sel, B, cntrl[0]);
    
    logic adder_res;
    full_adder adder (.A(A), .B(B_sel), .Cin(Cin), .sum(adder_res), .carry_out(carry_out));

    logic [7:0] options;

    assign options[0] = B;
    assign options[1] = 64'bX; // unused
    assign options[2] = adder_res;
    assign options[3] = adder_res;
    assign options[4] = and_res;
    assign options[5] = or_res;
    assign options[6] = xor_res;
    assign options[7] = 64'bX; // unused


    mux8_1 mux (.z_o(result), .mux_i(options), .sel_i(cntrl));
endmodule

module full_adder(input logic A, B, Cin,
                  output logic sum, carry_out);
    
    logic s0, c0, c1;

    xor #0.050 xor_gate (s0, A, B);
    xor #0.050 xor_gate2 (sum, s0, Cin);
    and #0.050 and_gate (c0, A, B);
    and #0.050 and_gate2 (c1, s0, Cin);
    or #0.050 or_gate (carry_out, c0, c1);
endmodule