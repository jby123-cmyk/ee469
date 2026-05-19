`timescale 1ns/10ps

module forwarding_unit(
    // Source registers from current instruction in EX stage
    input logic [4:0] ReadRegister1,     // rn
    input logic [4:0] ReadRegister2,     // rm
    
    // Destination register from previous instruction in MEM stage
    input logic [4:0] WriteRegister_m,   // destination from EX/MEM pipeline
    input logic reg_write_en_m,          // write enable (1 = writes to register)
    
    // Forwarding control signals
    output logic [1:0] forward_alu_A,    // 00: from regfile, 01: from MEM result
    output logic [1:0] forward_alu_B     // 00: from regfile, 01: from MEM result
);

    // Compare source registers with MEM stage destination
    logic eq_rn_m, eq_rm_m;
    logic [4:0] xor_results_rn;
    logic [4:0] xor_results_rm;

    //assign eq_rn_m = (ReadRegister1 == WriteRegister_m);
    xor #0.050 eq_rn_m_xor [4:0] (xor_results_rn, ReadRegister1, WriteRegister_m);
    nor #0.050 eq_rn_m_xnor (eq_rn_m, xor_results_rn[0], xor_results_rn[1], xor_results_rn[2], xor_results_rn[3], xor_results_rn[4]);
    
    //assign eq_rm_m = (ReadRegister2 == WriteRegister_m);
    xor #0.050 eq_rm_m_xor [4:0] (xor_results_rm, ReadRegister2, WriteRegister_m);
    nor #0.050 eq_rm_m_xnor (eq_rm_m, xor_results_rm[0], xor_results_rm[1], xor_results_rm[2], xor_results_rm[3], xor_results_rm[4]);

    logic fwd_a, fwd_b;

    // assign fwd_a = eq_rn_m & reg_write_en_m;
    // assign fwd_b = eq_rm_m & reg_write_en_m;
    
    and #0.050 fwd_a_and (fwd_a, eq_rn_m, reg_write_en_m);
    and #0.050 fwd_b_and (fwd_b, eq_rm_m, reg_write_en_m);
    
    //----------------------------------------------------bookmark

    // 2'b00 = regfile, 2'b01 = MEM; sel[1] unused until WB forwarding added
    and #0.050 fwd_a_sel1_lo (forward_alu_A[1], 1'b0, 1'b0);
    or  #0.050 fwd_a_sel0    (forward_alu_A[0], fwd_a, 1'b0);
    and #0.050 fwd_b_sel1_lo (forward_alu_B[1], 1'b0, 1'b0);
    or  #0.050 fwd_b_sel0    (forward_alu_B[0], fwd_b, 1'b0);

endmodule
