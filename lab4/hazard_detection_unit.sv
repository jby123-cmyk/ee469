`timescale 1ns/10ps

module hazard_detection_unit(
    input  logic       id_ex_memread,
    input  logic       id_ex_regwrite,
    input  logic       ex_mem_regwrite,
    input  logic       id_ex_setflags,
    input  logic [4:0] id_ex_rd,
    input  logic [4:0] ex_mem_rd,
    input  logic [4:0] if_id_rn,
    input  logic [4:0] if_id_rm,
    input  logic       id_is_branch,
    input  logic       branch_uses_rm,
    input  logic       branch_uses_flags,
    input  logic       branch_taken,

    output logic pc_write_en,
    output logic if_id_write_en,
    output logic if_id_flush,
    output logic id_ex_flush,
    output logic ex_mem_flush
);

    // load-use hazard detect:
    // id_ex_memread & (id_ex_rd != 31) & ((id_ex_rd == if_id_rn) | (id_ex_rd == if_id_rm))
    logic eq_id_ex_rd_rn, eq_id_ex_rd_rm;
    logic rd_not_x31;
    logic load_use_hazard;

    // branch operand and flag hazards in ID stage
    logic eq_id_ex_rd_branch_rm, eq_ex_mem_rd_branch_rm;
    logic ex_mem_rd_not_x31;
    logic branch_src_hazard_id_ex;
    logic branch_src_hazard_ex_mem;
    logic branch_operand_hazard;
    logic branch_flag_hazard;
    logic stall_hazard;

    check_equal_5 eq_id_ex_rd_rn_cmp (.z_o(eq_id_ex_rd_rn), .a_i(id_ex_rd), .b_i(if_id_rn));
    check_equal_5 eq_id_ex_rd_rm_cmp (.z_o(eq_id_ex_rd_rm), .a_i(id_ex_rd), .b_i(if_id_rm));
    check_not_equal_5 rd_not_x31_cmp (.z_o(rd_not_x31), .a_i(id_ex_rd), .b_i(5'b11111));
    check_equal_5 eq_id_ex_rd_branch_rm_cmp (.z_o(eq_id_ex_rd_branch_rm), .a_i(id_ex_rd), .b_i(if_id_rm));

    check_equal_5 eq_ex_mem_rd_branch_rm_cmp (.z_o(eq_ex_mem_rd_branch_rm), .a_i(ex_mem_rd), .b_i(if_id_rm));
    check_not_equal_5 ex_mem_rd_not_x31_cmp (.z_o(ex_mem_rd_not_x31), .a_i(ex_mem_rd), .b_i(5'b11111));

    assign load_use_hazard = id_ex_memread
                           & rd_not_x31
                           & (eq_id_ex_rd_rn | eq_id_ex_rd_rm);

    assign branch_src_hazard_id_ex = id_is_branch
                                   & branch_uses_rm
                                   & id_ex_regwrite
                                   & rd_not_x31
                                   & eq_id_ex_rd_branch_rm;

    assign branch_src_hazard_ex_mem = id_is_branch
                                    & branch_uses_rm
                                    & ex_mem_regwrite
                                    & ex_mem_rd_not_x31
                                    & eq_ex_mem_rd_branch_rm;

    assign branch_operand_hazard = branch_src_hazard_id_ex | branch_src_hazard_ex_mem;
    assign branch_flag_hazard = id_is_branch & branch_uses_flags & id_ex_setflags;
    assign stall_hazard = load_use_hazard | branch_operand_hazard | branch_flag_hazard;

    // any hazard stalls PC/IF_ID and injects bubble in ID/EX
    assign pc_write_en = ~stall_hazard;
    assign if_id_write_en = ~stall_hazard;
    assign id_ex_flush = stall_hazard;

    // taken branch in ID flushes younger IF instruction when not stalled
    assign if_id_flush = branch_taken & ~stall_hazard;

    // retained for interface compatibility
    assign ex_mem_flush = 1'b0;

endmodule
