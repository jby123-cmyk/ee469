`timescale 1ns/10ps

module forwarding_unit(
    input logic [4:0] ReadRegister1,
    input logic [4:0] ReadRegister2,
    input logic [4:0] ReadRegister2_id,

    input logic [4:0] WriteRegister_r,
    input logic reg_write_en_r,
    input logic id_ex_memread,

    input logic [4:0] WriteRegister_m,
    input logic reg_write_en_m,

    input logic [4:0] WriteRegister_w,
    input logic reg_write_en_w,
    input logic stur_en_m,

    output logic [1:0] forward_alu_A,
    output logic [1:0] forward_alu_B,
    output logic store_data_fwd_wb,
    output logic fwd_branch_ex_id,
    output logic [1:0] fwd_branch_sel
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

    assign ex_write_valid = reg_write_en_m & rd_m_not_x31;
    assign fwd_a_ex = eq_rn_m & ex_write_valid;
    assign fwd_b_ex = eq_rm_m & ex_write_valid;

    // MEM/WB pipeline comparisons
    logic eq_rn_w, eq_rm_w;

    check_equal_5 eq_rn_w_cmp (.z_o(eq_rn_w), .a_i(ReadRegister1), .b_i(WriteRegister_w));
    check_equal_5 eq_rm_w_cmp (.z_o(eq_rm_w), .a_i(ReadRegister2), .b_i(WriteRegister_w));

    logic wb_write_valid;
    logic fwd_a_wb_pre, fwd_b_wb_pre;
    logic not_fwd_a_ex, not_fwd_b_ex;
    logic fwd_a_wb, fwd_b_wb;

    assign wb_write_valid = reg_write_en_w & rd_w_not_x31;
    assign fwd_a_wb_pre = eq_rn_w & wb_write_valid;
    assign fwd_b_wb_pre = eq_rm_w & wb_write_valid;

    assign not_fwd_a_ex = ~fwd_a_ex;
    assign not_fwd_b_ex = ~fwd_b_ex;
    assign fwd_a_wb = fwd_a_wb_pre & not_fwd_a_ex;
    assign fwd_b_wb = fwd_b_wb_pre & not_fwd_b_ex;

    // output encoding, 00 = no forwarding, 01 = MEM/WB, 10 = EX/MEM
    assign forward_alu_A[1] = fwd_a_ex;
    assign forward_alu_A[0] = fwd_a_wb;
    assign forward_alu_B[1] = fwd_b_ex;
    assign forward_alu_B[0] = fwd_b_wb;

    // MEM-stage store forwarding from WB
    logic store_src_eq_wb;

    check_equal_5 store_src_eq_wb_cmp (.z_o(store_src_eq_wb), .a_i(WriteRegister_m), .b_i(WriteRegister_w));
    
    assign store_data_fwd_wb = stur_en_m & wb_write_valid & store_src_eq_wb;

    // ID-stage branch operand forwarding
    logic eq_wr_r_rm2, wr_r_not_x31, not_mem_ldur_ex, ex_branch_write_valid;
    logic eq_wr_m_rm2, wr_m_not_x31, mem_branch_write_valid;
    logic eq_wr_w_rm2, wr_w_not_x31, wb_branch_write_valid;
    logic fwd_branch_mem_id, fwd_branch_wb_pre, fwd_branch_wb_id;
    logic not_fwd_branch_ex, not_fwd_branch_mem;

    // EX-stage branch forwarding
    check_equal_5 eq_wr_r_rm2_cmp (.z_o(eq_wr_r_rm2), .a_i(WriteRegister_r), .b_i(ReadRegister2_id));
    check_not_equal_5 wr_r_not_x31_cmp (.z_o(wr_r_not_x31), .a_i(WriteRegister_r), .b_i(5'b11111));
    assign not_mem_ldur_ex = ~id_ex_memread;
    assign ex_branch_write_valid = reg_write_en_r & not_mem_ldur_ex & wr_r_not_x31;
    assign fwd_branch_ex_id = ex_branch_write_valid & eq_wr_r_rm2;

    // MEM-stage branch forwarding
    check_equal_5 eq_wr_m_rm2_cmp (.z_o(eq_wr_m_rm2), .a_i(WriteRegister_m), .b_i(ReadRegister2_id));
    check_not_equal_5 wr_m_not_x31_cmp (.z_o(wr_m_not_x31), .a_i(WriteRegister_m), .b_i(5'b11111));
    assign mem_branch_write_valid = reg_write_en_m & wr_m_not_x31;
    assign fwd_branch_mem_id = mem_branch_write_valid & eq_wr_m_rm2;

    // WB-stage branch forwarding
    check_equal_5 eq_wr_w_rm2_cmp (.z_o(eq_wr_w_rm2), .a_i(WriteRegister_w), .b_i(ReadRegister2_id));
    check_not_equal_5 wr_w_not_x31_cmp (.z_o(wr_w_not_x31), .a_i(WriteRegister_w), .b_i(5'b11111));
    assign wb_branch_write_valid = reg_write_en_w & wr_w_not_x31;
    assign fwd_branch_wb_pre = wb_branch_write_valid & eq_wr_w_rm2;
    assign not_fwd_branch_ex = ~fwd_branch_ex_id;
    assign not_fwd_branch_mem = ~fwd_branch_mem_id;
    assign fwd_branch_wb_id = fwd_branch_wb_pre & not_fwd_branch_ex & not_fwd_branch_mem;

    assign fwd_branch_sel[1] = fwd_branch_mem_id;
    assign fwd_branch_sel[0] = fwd_branch_wb_id;

endmodule
