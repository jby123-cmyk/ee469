`timescale 1ns/10ps

module forwarding_unit(
    input logic [4:0] ReadRegister1,
    input logic [4:0] ReadRegister2,

    input logic [4:0] WriteRegister_m,
    input logic reg_write_en_m,

    input logic [4:0] WriteRegister_w,
    input logic reg_write_en_w,
    input logic stur_en_m,

    output logic [1:0] forward_alu_A,
    output logic [1:0] forward_alu_B,
    output logic store_data_fwd_wb
);

    // ignore X31 register forwarding
    logic rd_m_not_x31, rd_w_not_x31;
    check_not_equal_5 rd_m_not_x31_cmp (.z_o(rd_m_not_x31), .a_i(WriteRegister_m), .b_i(5'b11111));
    check_not_equal_5 rd_w_not_x31_cmp (.z_o(rd_w_not_x31), .a_i(WriteRegister_w), .b_i(5'b11111));

    // EX/MEM pipeline comparisons
    logic eq_rn_m, eq_rm_m;

    check_equal_5 eq_rn_m_cmp (.z_o(eq_rn_m), .a_i(ReadRegister1), .b_i(WriteRegister_m));
    check_equal_5 eq_rm_m_cmp (.z_o(eq_rm_m), .a_i(ReadRegister2), .b_i(WriteRegister_m));

    logic ex_write_valid;
    logic fwd_a_ex, fwd_b_ex;

    and #0.050 ex_write_valid_g (ex_write_valid, reg_write_en_m, rd_m_not_x31);
    and #0.050 fwd_a_ex_g (fwd_a_ex, eq_rn_m, ex_write_valid);
    and #0.050 fwd_b_ex_g (fwd_b_ex, eq_rm_m, ex_write_valid);

    // MEM/WB pipeline comparisons
    logic eq_rn_w, eq_rm_w;

    check_equal_5 eq_rn_w_cmp (.z_o(eq_rn_w), .a_i(ReadRegister1), .b_i(WriteRegister_w));
    check_equal_5 eq_rm_w_cmp (.z_o(eq_rm_w), .a_i(ReadRegister2), .b_i(WriteRegister_w));

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

    // MEM stage data forwarding
    logic store_src_eq_wb_dst;

    check_equal_5 store_src_eq_wb_dst_cmp (.z_o(store_src_eq_wb_dst), .a_i(WriteRegister_m), .b_i(WriteRegister_w));
    and #0.050 store_data_fwd_wb_g (store_data_fwd_wb, stur_en_m, wb_write_valid, store_src_eq_wb_dst);

endmodule
