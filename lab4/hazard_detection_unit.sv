`timescale 1ns/10ps

module hazard_detection_unit(
    input  logic       id_ex_memread,
    input  logic [4:0] id_ex_rd,
    input  logic [4:0] if_id_rn,
    input  logic [4:0] if_id_rm,
    input  logic       reg_write_en_w,
    input  logic [4:0] write_register_w,
    input  logic       branch_taken,

    output logic pc_write_en,
    output logic if_id_write_en,
    output logic if_id_flush,
    output logic id_ex_flush
);

    logic eq_id_ex_rd_rn, eq_id_ex_rd_rm;
    logic rd_not_x31;
    logic load_use_hazard;

    logic wb_rd_not_x31;
    logic eq_wb_rd_rn, eq_wb_rd_rm;
    logic id_wb_read_hazard;

    logic stall_hazard;

    check_equal_5 eq_id_ex_rd_rn_cmp (.z_o(eq_id_ex_rd_rn), .a_i(id_ex_rd), .b_i(if_id_rn));
    check_equal_5 eq_id_ex_rd_rm_cmp (.z_o(eq_id_ex_rd_rm), .a_i(id_ex_rd), .b_i(if_id_rm));
    check_not_equal_5 rd_not_x31_cmp (.z_o(rd_not_x31), .a_i(id_ex_rd), .b_i(5'b11111));

    check_not_equal_5 wb_rd_not_x31_cmp (.z_o(wb_rd_not_x31), .a_i(write_register_w), .b_i(5'b11111));
    check_equal_5 eq_wb_rd_rn_cmp (.z_o(eq_wb_rd_rn), .a_i(write_register_w), .b_i(if_id_rn));
    check_equal_5 eq_wb_rd_rm_cmp (.z_o(eq_wb_rd_rm), .a_i(write_register_w), .b_i(if_id_rm));

    // LDUR in EX, dependent instruction in ID
    assign load_use_hazard = id_ex_memread
                           & rd_not_x31
                           & (eq_id_ex_rd_rn | eq_id_ex_rd_rm);

    // WB write completes after ID combinational read this cycle
    assign id_wb_read_hazard = reg_write_en_w
                             & wb_rd_not_x31
                             & (eq_wb_rd_rn | eq_wb_rd_rm);

    assign stall_hazard = load_use_hazard | id_wb_read_hazard;

    assign pc_write_en     = ~stall_hazard;
    assign if_id_write_en = ~stall_hazard;

    // Bubble ID/EX on any stall: load-use AND id-wb-read both leave a stale
    // (ReadData1_n, ReadData2_n) latched into ID/EX if not flushed. The held
    // instruction re-runs ID next cycle and gets fresh regfile reads.
    assign id_ex_flush = stall_hazard;

    assign if_id_flush = branch_taken & ~stall_hazard;

endmodule
