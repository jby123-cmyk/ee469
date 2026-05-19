`timescale 1ns/10ps

module forwarding_unit(
    input logic [4:0] ReadRegister1,
    input logic [4:0] ReadRegister2,

    input logic [4:0] WriteRegister_m,
    input logic reg_write_en_m,

    input logic [4:0] WriteRegister_w,
    input logic reg_write_en_w,

    output logic [1:0] forward_alu_A,
    output logic [1:0] forward_alu_B
);

    // ignore X31 register forwarding
    logic [4:0] x31_const;
    logic [4:0] xor_rd_m_x31, xor_rd_w_x31;
    logic rd_m_not_x31, rd_w_not_x31;

    assign x31_const = 5'b11111;

    xor #0.050 xor_rd_m_x31_g [4:0] (xor_rd_m_x31, WriteRegister_m, x31_const);
    or  #0.050 rd_m_not_x31_g (rd_m_not_x31, xor_rd_m_x31[0], xor_rd_m_x31[1], xor_rd_m_x31[2], xor_rd_m_x31[3], xor_rd_m_x31[4]);

    xor #0.050 xor_rd_w_x31_g [4:0] (xor_rd_w_x31, WriteRegister_w, x31_const);
    or  #0.050 rd_w_not_x31_g (rd_w_not_x31, xor_rd_w_x31[0], xor_rd_w_x31[1], xor_rd_w_x31[2], xor_rd_w_x31[3], xor_rd_w_x31[4]);

    // EX/MEM pipeline comparisons

    logic [4:0] xor_rn_m, xor_rm_m;
    logic eq_rn_m, eq_rm_m;

    xor #0.050 xor_rn_m_g [4:0] (xor_rn_m, ReadRegister1, WriteRegister_m);
    nor #0.050 nor_rn_m_g (eq_rn_m, xor_rn_m[0], xor_rn_m[1], xor_rn_m[2], xor_rn_m[3], xor_rn_m[4]);

    xor #0.050 xor_rm_m_g [4:0] (xor_rm_m, ReadRegister2, WriteRegister_m);
    nor #0.050 nor_rm_m_g (eq_rm_m, xor_rm_m[0], xor_rm_m[1], xor_rm_m[2], xor_rm_m[3], xor_rm_m[4]);

    logic ex_write_valid;
    logic fwd_a_ex, fwd_b_ex;

    and #0.050 ex_write_valid_g (ex_write_valid, reg_write_en_m, rd_m_not_x31);
    and #0.050 fwd_a_ex_g (fwd_a_ex, eq_rn_m, ex_write_valid);
    and #0.050 fwd_b_ex_g (fwd_b_ex, eq_rm_m, ex_write_valid);

    // MEM/WB pipeline comparisons

    logic [4:0] xor_rn_w, xor_rm_w;
    logic eq_rn_w, eq_rm_w;

    xor #0.050 xor_rn_w_g [4:0] (xor_rn_w, ReadRegister1, WriteRegister_w);
    nor #0.050 nor_rn_w_g (eq_rn_w, xor_rn_w[0], xor_rn_w[1], xor_rn_w[2], xor_rn_w[3], xor_rn_w[4]);

    xor #0.050 xor_rm_w_g [4:0] (xor_rm_w, ReadRegister2, WriteRegister_w);
    nor #0.050 nor_rm_w_g (eq_rm_w, xor_rm_w[0], xor_rm_w[1], xor_rm_w[2], xor_rm_w[3], xor_rm_w[4]);

    logic wb_write_valid;
    logic fwd_a_wb_pre, fwd_b_wb_pre;
    logic not_fwd_a_ex, not_fwd_b_ex;
    logic fwd_a_wb, fwd_b_wb;

    and #0.050 wb_write_valid_g (wb_write_valid, reg_write_en_w, rd_w_not_x31);
    and #0.050 fwd_a_wb_pre_g (fwd_a_wb_pre, eq_rn_w, wb_write_valid);
    and #0.050 fwd_b_wb_pre_g (fwd_b_wb_pre, eq_rm_w, wb_write_valid);

    not #0.050 not_fwd_a_ex_g (not_fwd_a_ex, fwd_a_ex);
    not #0.050 not_fwd_b_ex_g (not_fwd_b_ex, fwd_b_ex);
    and #0.050 fwd_a_wb_g (fwd_a_wb, fwd_a_wb_pre, not_fwd_a_ex);
    and #0.050 fwd_b_wb_g (fwd_b_wb, fwd_b_wb_pre, not_fwd_b_ex);

    // output encoding, 00 = no forwarding, 01 = MEM/WB, 10 = EX/MEM
    or  #0.050 fwd_a_hi (forward_alu_A[1], fwd_a_ex, 1'b0);
    or  #0.050 fwd_a_lo (forward_alu_A[0], fwd_a_wb, 1'b0);
    or  #0.050 fwd_b_hi (forward_alu_B[1], fwd_b_ex, 1'b0);
    or  #0.050 fwd_b_lo (forward_alu_B[0], fwd_b_wb, 1'b0);

endmodule
