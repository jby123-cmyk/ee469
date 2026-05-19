`timescale 1ns/10ps

module hazard_detection_unit(
    input  logic       id_ex_memread,
    input  logic [4:0] id_ex_rd,
    input  logic [4:0] if_id_rn,
    input  logic [4:0] if_id_rm,
    input  logic       branch_taken,

    output logic pc_write_en,
    output logic if_id_write_en,
    output logic if_id_flush,
    output logic id_ex_flush,
    output logic ex_mem_flush
);

    // load-use hazard detect:
    // id_ex_memread & (id_ex_rd != 31) & ((id_ex_rd == if_id_rn) | (id_ex_rd == if_id_rm))

    logic eq_rd_rn, eq_rd_rm;
    logic rd_dep_match;
    logic rd_not_x31;
    logic load_use_hazard;
    logic not_load_use_hazard;

    check_equal_5 eq_rd_rn_cmp (.z_o(eq_rd_rn), .a_i(id_ex_rd), .b_i(if_id_rn));
    check_equal_5 eq_rd_rm_cmp (.z_o(eq_rd_rm), .a_i(id_ex_rd), .b_i(if_id_rm));
    check_not_equal_5 rd_not_x31_cmp (.z_o(rd_not_x31), .a_i(id_ex_rd), .b_i(5'b11111));

    or  #0.050 rd_dep_match_g (rd_dep_match, eq_rd_rn, eq_rd_rm);
    and #0.050 load_use_hazard_g (load_use_hazard, id_ex_memread, rd_not_x31, rd_dep_match);

    not #0.050 not_load_use_hazard_g (not_load_use_hazard, load_use_hazard);

    // load_use_hazard stalls PC/IF_ID and flushes ID/EX
    // branch flushes IF/ID only when no load-use hazard
    or  #0.050 pc_write_en_g (pc_write_en, not_load_use_hazard, 1'b0);
    or  #0.050 if_id_write_en_g (if_id_write_en, not_load_use_hazard, 1'b0);
    or  #0.050 id_ex_flush_g (id_ex_flush, load_use_hazard, 1'b0);
    and #0.050 if_id_flush_g (if_id_flush, branch_taken, not_load_use_hazard);
    and #0.050 ex_mem_flush_g (ex_mem_flush, 1'b0, 1'b0);

endmodule
