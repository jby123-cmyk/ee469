`timescale 1ns/10ps

module cpu(input logic clk, reset);
//***************************************************************//
// Instruction fetch stage 
//***************************************************************//
    logic [31:0] instruction;
    logic [63:0] pc_r;
    logic [63:0] pc_n;

    // PC = PC + 4
    logic [63:0] pc_add_4;
    pc_adder pc_p4_adder(.pc_r(pc_r),
                    .pc_n(pc_add_4));

    instructmem instruction_memory (
	    .address(pc_r),
	    .instruction(instruction),
	    .clk(clk)
	);

    logic [95:0] pipeline_if_id_r, pipeline_if_id_n;

    assign pipeline_if_id_n = {pc_r, instruction};

    D_FF_param #(96) pipeline_if_id_dff 
                (.q(pipeline_if_id_r), 
                 .d(pipeline_if_id_n), 
                 .reset(reset), 
                 .clk(clk));
//***************************************************************//
// Instruction decode and register read
//***************************************************************//

    // instruction decode + control
    logic [31:0] instruction_r;

    assign instruction_r = pipeline_if_id_r[31:0];

    logic [10:0] opcode;
    assign opcode = instruction_r[31:21];

    logic [4:0] rd, rn, rm;
    assign rd = instruction_r[4:0];
    assign rn = instruction_r[9:5];
    assign rm = instruction_r[20:16];
    
    logic [63:0] addi_imm;
    assign addi_imm = {52'b0, instruction_r[21:10]};

    logic [63:0] d_imm;
    assign d_imm = {{55{instruction_r[20]}}, instruction_r[20:12]};

    logic [63:0] imm_26;
    assign imm_26 = {{38{instruction_r[25]}}, instruction_r[25:0]};

    logic [63:0] imm_19;
    assign imm_19 = {{45{instruction_r[23]}}, instruction_r[23:5]};

    logic [63:0] alu_imm;
    logic [63:0] branch_imm;
    logic [63:0] imm_value_n;
    logic branch_imm_sel_n;
    logic branch_any_sel_n;

    logic [2:0] alu_cntrl_n;
    logic reg_write_en_n;
    logic ldur_en_n;
    logic stur_en_n;
    logic branch_uncond_n;
    logic branch_zero_n;
    logic branch_lt_n;
    logic branch_reg_sel_n;
    logic branch_link_sel_n;
    logic set_flags_n;
    logic alu_src_n;
    logic reg2loc_n;
    logic addi_en_n;

    control control_unit (.opcode(opcode)
              ,.alu_cntrl(alu_cntrl_n)
              ,.reg_write_en(reg_write_en_n)
              ,.ldur_en(ldur_en_n)
              ,.stur_en(stur_en_n)
              ,.branch_uncond(branch_uncond_n)
              ,.branch_zero(branch_zero_n)
              ,.branch_lt(branch_lt_n)
              ,.branch_reg_sel(branch_reg_sel_n)
              ,.branch_link_sel(branch_link_sel_n)
              ,.set_flags(set_flags_n)
              ,.alu_src(alu_src_n)
              ,.reg2loc(reg2loc_n)
              ,.addi_en(addi_en_n));

    mux2_1x64 alu_imm_sel_mux (
        .z_o(alu_imm),
        .a_i(d_imm),
        .b_i(addi_imm),
        .sel_i(addi_en_n)
    );

    assign branch_imm_sel_n = branch_uncond_n | branch_link_sel_n;
    assign branch_any_sel_n = branch_uncond_n | branch_link_sel_n | branch_zero_n | branch_lt_n;

    mux2_1x64 branch_imm_sel_mux (
        .z_o(branch_imm),
        .a_i(imm_19),
        .b_i(imm_26),
        .sel_i(branch_imm_sel_n)
    );

    mux2_1x64 imm_value_mux (
        .z_o(imm_value_n),
        .a_i(alu_imm),
        .b_i(branch_imm),
        .sel_i(branch_any_sel_n)
    );

    logic [63:0] ReadData1_n;
    logic [63:0] ReadData2_n;
    logic [63:0] WriteData_w;
    logic [4:0] ReadRegister1;
    logic [4:0] ReadRegister2;
    logic [4:0] WriteRegister_n;
    logic [4:0] WriteRegister_w;
    logic [4:0] read_register2_x5;
    logic reg_write_en_w;

    assign ReadRegister1 = rn;

    mux2_1x5 read_register2_mux (
        .z_o(read_register2_x5),
        .a_i(rm),
        .b_i(rd),
        .sel_i(reg2loc_n)
    );

    mux2_1x5 write_register_mux (
        .z_o(WriteRegister_n),
        .a_i(rd),
        .b_i(5'b11110),
        .sel_i(branch_link_sel_n)
    );

    assign ReadRegister2 = read_register2_x5;

    regfile registers (
        .ReadData1(ReadData1_n),
        .ReadData2(ReadData2_n),
        .WriteData(WriteData_w),
        .ReadRegister1(ReadRegister1),
        .ReadRegister2(ReadRegister2),
        .WriteRegister(WriteRegister_w),
        .RegWrite(reg_write_en_w),
        .clk(clk)
    ); 

    logic [284:0] pipeline_id_ex_r, pipeline_id_ex_n;
    logic [2:0] wb_ctl_n;
    logic [1:0] mem_ctl_n;
    logic [8:0] ex_ctl_n;

    assign wb_ctl_n = {reg_write_en_n, branch_link_sel_n, ldur_en_n};
    assign mem_ctl_n = {ldur_en_n, stur_en_n};
    assign ex_ctl_n = {alu_cntrl_n, alu_src_n, branch_uncond_n, branch_zero_n, branch_lt_n, branch_reg_sel_n, set_flags_n};

    assign pipeline_id_ex_n = {wb_ctl_n, mem_ctl_n, ex_ctl_n, pipeline_if_id_r[95:32], ReadData1_n, ReadData2_n, imm_value_n, WriteRegister_n, rn, rm};

    D_FF_param #(285) pipeline_id_ex_dff 
                (.q(pipeline_id_ex_r), 
                 .d(pipeline_id_ex_n), 
                 .reset(reset), 
                 .clk(clk));

//***************************************************************//
// Execute stage: ALU and PC register calculations
//***************************************************************//
    logic [2:0] wb_ctl_r;
    logic [1:0] mem_ctl_r;
    logic [8:0] ex_ctl_r;
    logic [63:0] pc_r_ex;
    logic [63:0] ReadData1_r;
    logic [63:0] ReadData2_r;
    logic [63:0] imm_value_r;
    logic [4:0] WriteRegister_r;
    logic [4:0] rn_r, rm_r;

    assign wb_ctl_r = pipeline_id_ex_r[284:282];
    assign mem_ctl_r = pipeline_id_ex_r[281:280];
    assign ex_ctl_r = pipeline_id_ex_r[279:271];
    assign pc_r_ex = pipeline_id_ex_r[270:207];
    assign ReadData1_r = pipeline_id_ex_r[206:143];
    assign ReadData2_r = pipeline_id_ex_r[142:79];
    assign imm_value_r = pipeline_id_ex_r[78:15];
    assign WriteRegister_r = pipeline_id_ex_r[14:10];
    assign rn_r = pipeline_id_ex_r[9:5];
    assign rm_r = pipeline_id_ex_r[4:0];

    logic [2:0] alu_cntrl_r;
    logic alu_src_r;
    logic branch_uncond_r;
    logic branch_zero_r;
    logic branch_lt_r;
    logic branch_reg_sel_r;
    logic set_flags_r;
    logic branch_link_sel_r;

    assign alu_cntrl_r = ex_ctl_r[8:6];
    assign alu_src_r = ex_ctl_r[5];
    assign branch_uncond_r = ex_ctl_r[4];
    assign branch_zero_r = ex_ctl_r[3];
    assign branch_lt_r = ex_ctl_r[2];
    assign branch_reg_sel_r = ex_ctl_r[1];
    assign set_flags_r = ex_ctl_r[0];
    assign branch_link_sel_r = wb_ctl_r[1];

    // Extract data from EX/MEM pipeline for forwarding unit
    logic [4:0] WriteRegister_mem_fwd;
    logic [63:0] alu_result_mem_fwd;
    logic reg_write_en_mem_fwd;
    
    assign WriteRegister_mem_fwd = pipeline_ex_mem_r[68:64];
    assign alu_result_mem_fwd = pipeline_ex_mem_r[196:133];
    assign reg_write_en_mem_fwd = pipeline_ex_mem_r[272];

    // Forwarding unit and multiplexers
    logic [1:0] forward_alu_A, forward_alu_B;
    logic [63:0] alu_A_forwarded, alu_B_forwarded;

    forwarding_unit fwd_unit (
        .ReadRegister1(rn_r),
        .ReadRegister2(rm_r),
        .WriteRegister_m(WriteRegister_mem_fwd),
        .reg_write_en_m(reg_write_en_mem_fwd),
        .forward_alu_A(forward_alu_A),
        .forward_alu_B(forward_alu_B)
    );

    mux3_1x64 alu_a_fwd_mux (
        .z_o(alu_A_forwarded),
        .a_i(ReadData1_r),
        .b_i(alu_result_mem_fwd),
        .c_i(64'h0),
        .sel_i(forward_alu_A)
    );

    mux3_1x64 alu_b_fwd_mux (
        .z_o(alu_B_forwarded),
        .a_i(ReadData2_r),
        .b_i(alu_result_mem_fwd),
        .c_i(64'h0),
        .sel_i(forward_alu_B)
    );

    // ALU circuit
    logic [63:0] alu_A;
    logic [63:0] alu_B;
    logic [63:0] alu_result_n;
    logic negative_r, negative_n;
    logic zero_r, zero_n;
    logic overflow_r, overflow_n;
    logic carry_out_r, carry_out_n;

    assign alu_A = alu_A_forwarded;

    mux2_1x64 alu_b_mux (
        .z_o(alu_B),
        .a_i(alu_B_forwarded),
        .b_i(imm_value_r),
        .sel_i(alu_src_r)
    );

    alu alu (
        .A(alu_A),
        .B(alu_B),
        .cntrl(alu_cntrl_r),
        .result(alu_result_n),
        .negative(negative_n),
        .zero(zero_n),
        .overflow(overflow_n),
        .carry_out(carry_out_n)
    );

    D_FF_en dff_negative (.q(negative_r), .d(negative_n), .reset(reset), .clk(clk), .en_i(set_flags_r));
    D_FF_en dff_zero (.q(zero_r), .d(zero_n), .reset(reset), .clk(clk), .en_i(set_flags_r));
    D_FF_en dff_overflow (.q(overflow_r), .d(overflow_n), .reset(reset), .clk(clk), .en_i(set_flags_r));
    D_FF_en dff_carry_out (.q(carry_out_r), .d(carry_out_n), .reset(reset), .clk(clk), .en_i(set_flags_r));

    // PC calculations 
    logic [63:0] branch_imm_shifted;
    logic [63:0] pc_add_imm_n;
    logic [63:0] pc_add_4_ex;

    assign branch_imm_shifted = {imm_value_r[61:0], 2'b00};

    pc_adder ex_pc_p4_adder(.pc_r(pc_r_ex),
                            .pc_n(pc_add_4_ex));
    
    branch_adder ex_branch_adder(.pc_r(pc_r_ex),
                                .imm(branch_imm_shifted),
                                .pc_n(pc_add_imm_n));

    logic [272:0] pipeline_ex_mem_r, pipeline_ex_mem_n;
    assign pipeline_ex_mem_n = {wb_ctl_r, mem_ctl_r, branch_uncond_r, branch_zero_r, branch_lt_r, branch_reg_sel_r, pc_add_imm_n, zero_n, negative_r, overflow_r, alu_result_n, ReadData2_r, WriteRegister_r, pc_add_4_ex};

    D_FF_param #(273) pipeline_ex_mem_dff 
                (.q(pipeline_ex_mem_r), 
                 .d(pipeline_ex_mem_n), 
                 .reset(reset), 
                 .clk(clk));

//***************************************************************//
// MEM stage
//***************************************************************//

    logic [2:0] wb_ctl_m;
    logic [1:0] mem_ctl_m;
    logic branch_uncond_m;
    logic branch_zero_m;
    logic branch_lt_m;
    logic branch_reg_sel_m;
    logic [63:0] pc_add_imm_m;
    logic zero_eval_m;
    logic negative_eval_m;
    logic overflow_eval_m;
    logic [63:0] alu_result_m;
    logic [63:0] ReadData2_m;
    logic [4:0] WriteRegister_m;
    logic [63:0] pc_add_4_m;
    logic ldur_en_m, stur_en_m;
    logic branch_link_sel_m;
    logic branch_taken_m;
    logic [63:0] pc_non_reg_m;

    assign wb_ctl_m = pipeline_ex_mem_r[272:270];
    assign mem_ctl_m = pipeline_ex_mem_r[269:268];
    assign branch_uncond_m = pipeline_ex_mem_r[267];
    assign branch_zero_m = pipeline_ex_mem_r[266];
    assign branch_lt_m = pipeline_ex_mem_r[265];
    assign branch_reg_sel_m = pipeline_ex_mem_r[264];
    assign pc_add_imm_m = pipeline_ex_mem_r[263:200];
    assign zero_eval_m = pipeline_ex_mem_r[199];
    assign negative_eval_m = pipeline_ex_mem_r[198];
    assign overflow_eval_m = pipeline_ex_mem_r[197];
    assign alu_result_m = pipeline_ex_mem_r[196:133];
    assign ReadData2_m = pipeline_ex_mem_r[132:69];
    assign WriteRegister_m = pipeline_ex_mem_r[68:64];
    assign pc_add_4_m = pipeline_ex_mem_r[63:0];

    assign ldur_en_m = mem_ctl_m[1];
    assign stur_en_m = mem_ctl_m[0];
    assign branch_link_sel_m = wb_ctl_m[1];
    assign branch_taken_m = branch_uncond_m | branch_link_sel_m |
                            (branch_zero_m & zero_eval_m) |
                            (branch_lt_m & (negative_eval_m ^ overflow_eval_m));

    logic [63:0] mem_addr;
    logic [3:0] xfer_size;
    logic [63:0] ldur_data_m;

    assign mem_addr = alu_result_m;
    assign xfer_size = 4'd8;

    datamem data_memory(
        .address(mem_addr),
        .write_enable(stur_en_m),
        .read_enable(ldur_en_m),
        .write_data(ReadData2_m),
        .clk(clk),
        .xfer_size(xfer_size), 
        .read_data(ldur_data_m)
	);

    mux2_1x64 pc_branch_mux (
        .z_o(pc_non_reg_m),
        .a_i(pc_add_4),
        .b_i(pc_add_imm_m),
        .sel_i(branch_taken_m)
    );

    mux2_1x64 pc_n_mux (
        .z_o(pc_n),
        .a_i(pc_non_reg_m),
        .b_i(ReadData2_m),
        .sel_i(branch_reg_sel_m)
    );

    logic [199:0] pipeline_mem_wb_r, pipeline_mem_wb_n;
    assign pipeline_mem_wb_n = {wb_ctl_m, alu_result_m, ldur_data_m, WriteRegister_m, pc_add_4_m};

    D_FF_param #(200) pipeline_mem_wb_dff 
                (.q(pipeline_mem_wb_r), 
                 .d(pipeline_mem_wb_n), 
                 .reset(reset), 
                 .clk(clk));
//***************************************************************//
// WB stage
//***************************************************************//

    logic [2:0] wb_ctl_w;
    logic [63:0] alu_result_w;
    logic [63:0] ldur_data_w;
    logic [63:0] pc_add_4_w;
    logic [63:0] writeback_non_mem;
    logic branch_link_sel_w;
    logic ldur_en_w;

    assign wb_ctl_w = pipeline_mem_wb_r[199:197];
    assign alu_result_w = pipeline_mem_wb_r[196:133];
    assign ldur_data_w = pipeline_mem_wb_r[132:69];
    assign WriteRegister_w = pipeline_mem_wb_r[68:64];
    assign pc_add_4_w = pipeline_mem_wb_r[63:0];

    assign reg_write_en_w = wb_ctl_w[2];
    assign branch_link_sel_w = wb_ctl_w[1];
    assign ldur_en_w = wb_ctl_w[0];

    mux2_1x64 writeback_link_mux (
        .z_o(writeback_non_mem),
        .a_i(alu_result_w),
        .b_i(pc_add_4_w),
        .sel_i(branch_link_sel_w)
    );

    mux2_1x64 writeback_mem_mux (
        .z_o(WriteData_w),
        .a_i(writeback_non_mem),
        .b_i(ldur_data_w),
        .sel_i(ldur_en_w)
    );

    // IF stage: PC state register
    D_FF_64 pc_ff (
        .d(pc_n),
        .reset(reset),
        .en_i(1'b1),
        .clk(clk),
        .q(pc_r)
    );


endmodule 