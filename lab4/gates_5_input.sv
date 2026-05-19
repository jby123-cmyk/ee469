`timescale 1ns/10ps

module or5_1(
    output logic z_o,
    input  logic [4:0] a_i
);
    logic mid_o;

    or #0.050 or_lo (mid_o, a_i[0], a_i[1], a_i[2], a_i[3]);
    or #0.050 or_hi (z_o, mid_o, a_i[4]);
endmodule

module nor5_1(
    output logic z_o,
    input  logic [4:0] a_i
);
    logic mid_o;

    or  #0.050 or_lo  (mid_o, a_i[0], a_i[1], a_i[2], a_i[3]);
    nor #0.050 nor_hi (z_o, mid_o, a_i[4]);
endmodule
