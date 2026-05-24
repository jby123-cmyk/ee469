`timescale 1ns/10ps

module hazard_detection_unit(
    input  logic       id_ex_memread,
    input  logic       id_ex_regwrite,
    input  logic [4:0] id_ex_rd,
    input  logic       ex_mem_regwrite,
    input  logic [4:0] ex_mem_rd,
    input  logic [4:0] if_id_rn,
    input  logic [4:0] if_id_rm,
    input  logic       branch_zero_id,
    input  logic       branch_reg_id,
    input  logic       branch_lt_id,
    input  logic       set_flags_ex,
    input  logic       reg_write_en_w,
    input  logic [4:0] write_register_w,
    input  logic       branch_taken,

    output logic pc_write_en,
    output logic if_id_write_en,
    output logic if_id_flush,
    output logic id_ex_flush
);

    logic eq_id_ex_rd_rn, eq_id_ex_rd_rm;
    logic eq_id_ex_rd_rm_branch;
    logic eq_ex_mem_rd_rm_branch;
    logic eq_wb_rd_rm_branch;
    logic rd_not_x31;
    logic ex_mem_rd_not_x31;
    logic wb_rd_not_x31;
    logic load_use_hazard;

    logic is_reg_branch_id;
    logic branch_data_hazard_ex;
    logic branch_data_hazard_mem;
    logic branch_data_hazard_wb;
    logic branch_data_hazard;
    logic branch_flag_hazard;

    logic stall_hazard;

    check_equal_5 eq_id_ex_rd_rn_cmp (.z_o(eq_id_ex_rd_rn), .a_i(id_ex_rd), .b_i(if_id_rn));
    check_equal_5 eq_id_ex_rd_rm_cmp (.z_o(eq_id_ex_rd_rm), .a_i(id_ex_rd), .b_i(if_id_rm));
    check_equal_5 eq_id_ex_rd_rm_branch_cmp (.z_o(eq_id_ex_rd_rm_branch), .a_i(id_ex_rd), .b_i(if_id_rm));
    check_equal_5 eq_ex_mem_rd_rm_branch_cmp (.z_o(eq_ex_mem_rd_rm_branch), .a_i(ex_mem_rd), .b_i(if_id_rm));
    check_equal_5 eq_wb_rd_rm_branch_cmp (.z_o(eq_wb_rd_rm_branch), .a_i(write_register_w), .b_i(if_id_rm));

    check_not_equal_5 rd_not_x31_cmp (.z_o(rd_not_x31), .a_i(id_ex_rd), .b_i(5'b11111));
    check_not_equal_5 ex_mem_rd_not_x31_cmp (.z_o(ex_mem_rd_not_x31), .a_i(ex_mem_rd), .b_i(5'b11111));
    check_not_equal_5 wb_rd_not_x31_cmp (.z_o(wb_rd_not_x31), .a_i(write_register_w), .b_i(5'b11111));

    // LDUR in EX, dependent instruction in ID
    assign load_use_hazard = id_ex_memread
                           & rd_not_x31
                           & (eq_id_ex_rd_rn | eq_id_ex_rd_rm);

    // branch source register hazard for ID-stage branch with no branch forwarding
    assign is_reg_branch_id = branch_zero_id | branch_reg_id;

    assign branch_data_hazard_ex = is_reg_branch_id
                                 & id_ex_regwrite
                                 & rd_not_x31
                                 & eq_id_ex_rd_rm_branch;

    assign branch_data_hazard_mem = is_reg_branch_id
                                  & ex_mem_regwrite
                                  & ex_mem_rd_not_x31
                                  & eq_ex_mem_rd_rm_branch;

    assign branch_data_hazard_wb = is_reg_branch_id
                                 & reg_write_en_w
                                 & wb_rd_not_x31
                                 & eq_wb_rd_rm_branch;

    assign branch_data_hazard = branch_data_hazard_ex
                              | branch_data_hazard_mem
                              | branch_data_hazard_wb;

    // B.LT in ID must wait if EX stage is currently updating flags
    assign branch_flag_hazard = branch_lt_id & set_flags_ex;

    assign stall_hazard = load_use_hazard | branch_data_hazard | branch_flag_hazard;

    assign pc_write_en     = ~stall_hazard;
    assign if_id_write_en = ~stall_hazard;

    // Bubble ID/EX on stalls
    assign id_ex_flush = stall_hazard;

    // Flush IF/ID on branch taken
    assign if_id_flush = branch_taken & ~stall_hazard;

endmodule
