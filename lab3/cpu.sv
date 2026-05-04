module cpu(input logic clk, reset);
//***************************************************************//
// Instruction fetch circuit
//***************************************************************//
    logic [31:0] instruction;

    instructmem (
	    .address(pc_r),
	    .instruction(instruction),
	    .clk(clk)
	);

    // Instruction decode circuit
    logic [10:0] opcode;
    assign opcode = instruction[31:21];

    logic [2:0] alu_cntrl;
    logic reg_write_en;
    logic ldur_en;
    logic stur_en;
    logic branch_imm_sel;
    logic branch_reg_sel;
    logic branch_cond_sel;
    logic branch_link_sel;
    logic branch_zero_sel;
    logic set_flags;

    control(.opcode(opcode)
              ,.alu_cntrl(alu_cntrl)
              ,.reg_write_en(reg_write_en)
              ,.ldur_en(ldur_en)
              ,.stur_en(stur_en)
              ,.branch_imm_sel(branch_imm_sel)
              ,.branch_reg_sel(branch_reg_sel)
              ,.branch_cond_sel(branch_cond_sel)
              ,.branch_link_sel(branch_link_sel)
              ,.branch_zero_sel(branch_zero_sel)
              ,.set_flags(set_flags));

//***************************************************************//
// PC circuit
//***************************************************************//

    logic [25:0] imm_26;
    assign imm_26 = instruction[25:0];

    logic [18:0] imm_19;
    assign imm_19 = {{7{instruction[23]}}, instruction[23:5]};

    // Standard PC + 4
    logic [63:0] pc_add_4;
    pc_adder(.pc_r(pc_r),
                    .pc_n(pc_add_4));

    // Standard branch, branch link
    logic [63:0] pc_add_imm_26;
    branch_adder(.pc_r(pc_r),
                        .imm(imm_26),
                        .pc_n(pc_add_imm_26));

    // Conditional branch, branch less than
    logic [63:0] pc_add_imm_19;
    branch_adder(.pc_r(pc_r),
                        .imm(imm_19),
                        .pc_n(pc_add_imm_19));

    // PC muxes 

    logic [63:0] pc_26_out;

    // Standard branch, branch link
    logic pc_26_sel;
    assign pc_26_sel = branch_imm_sel | branch_link_sel;

    mux2_1(.z_o(pc_26_out),
            .a_i(pc_add_4),
            .b_i(pc_add_imm_26),
            .sel_i(pc_26_sel));

    // Conditional branch, branch less than
    logic [63:0] pc_19_out;

    logic pc_19_sel;
    assign pc_19_sel = (branch_cond_sel & (negative ^ overflow)) | (branch_zero_sel & zero);
    mux2_1(.z_o(pc_19_out),
            .a_i(pc_26_out),
            .b_i(pc_add_imm_19),
            .sel_i(pc_19_sel));

    // Branch register
    mux2_1(.z_o(pc_n),
            .a_i(pc_19_out),
            .b_i(ReadData1),
            .sel_i(branch_reg_sel));
    
    // Data memory circuit
    logic stur_enable;
    logic ldur_enable;
    logic [63:0] stur_data;
    logic [3:0] xfer_size;
    logic [63:0] ldur_data;

    datamem (
        .address(pc),
        .write_enable(stur_enable),
        .read_enable(ldur_enable),
        .write_data(stur_data),
        .clk(clk),
        .xfer_size(xfer_size),
        .read_data(ldur_data)
	);

    // Register file circuit

    logic [63:0] ReadData1;
    logic [63:0] ReadData2;
    logic [63:0] WriteData;
    logic [4:0] ReadRegister1;
    logic [4:0] ReadRegister2;
    logic [4:0] WriteRegister;
    logic reg_write_en;

    regfile (
        .ReadData1(ReadData1),
        .ReadData2(ReadData2),
        .WriteData(WriteData),
        .ReadRegister1(ReadRegister1),
        .ReadRegister2(ReadRegister2),
        .WriteRegister(WriteRegister),
        .RegWrite(reg_write_en),
        .clk(clk)
    ); 

//***************************************************************//
// ALU circuit
//***************************************************************//

    logic [2:0] alu_cntrl;
    logic [63:0] result;
    logic negative;
    logic zero;
    logic overflow;
    logic carry_out;

    alu (
        .A(ReadData1),
        .B(ReadData2),
        .cntrl(alu_cntrl),
        .result(result),
        .negative(negative),
        .zero(zero),
        .overflow(overflow),
        .carry_out(carry_out)
    );

    D_FF_en dff_negative (.q(negative), .d(negative), .reset(reset), .clk(clk), .en_i(set_flags));
    D_FF_en dff_zero (.q(zero), .d(zero), .reset(reset), .clk(clk), .en_i(set_flags));
    D_FF_en dff_overflow (.q(overflow), .d(overflow), .reset(reset), .clk(clk), .en_i(set_flags));
    D_FF_en dff_carry_out (.q(carry_out), .d(carry_out), .reset(reset), .clk(clk), .en_i(set_flags));

    // PC update
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_r <= 64'h0;
        end else begin
            pc_r <= pc_n;
        end
    end
endmodule 