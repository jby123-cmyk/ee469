`timescale 1ns/10ps

module cpu(input logic clk, reset);
//***************************************************************//
// Instruction fetch circuit
//***************************************************************//
    logic [31:0] instruction;
    logic [63:0] pc_r;
    logic [63:0] pc_n;

    instructmem instruction_memory (
	    .address(pc_r),
	    .instruction(instruction),
	    .clk(clk)
	);

    // Instruction decode circuit
    logic [10:0] opcode;
    assign opcode = instruction[31:21];

    logic [4:0] rd, rn, rm;
    assign rd = instruction[4:0];
    assign rn = instruction[9:5];
    assign rm = instruction[20:16];
    
    logic [63:0] addi_imm;
    assign addi_imm = {52'b0, instruction[21:10]};

    logic [63:0] d_imm;
    assign d_imm = {{55{instruction[20]}}, instruction[20:12]};

    logic [25:0] imm_26;
    assign imm_26 = instruction[25:0];

    logic [25:0] imm_19;
    assign imm_19 = {{7{instruction[23]}}, instruction[23:5]};


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
    logic alu_src;
    logic reg2loc;
    logic addi_en;

    control control_unit (.opcode(opcode)
              ,.alu_cntrl(alu_cntrl)
              ,.reg_write_en(reg_write_en)
              ,.ldur_en(ldur_en)
              ,.stur_en(stur_en)
              ,.branch_imm_sel(branch_imm_sel)
              ,.branch_reg_sel(branch_reg_sel)
              ,.branch_cond_sel(branch_cond_sel)
              ,.branch_link_sel(branch_link_sel)
              ,.branch_zero_sel(branch_zero_sel)
              ,.set_flags(set_flags)
              ,.alu_src(alu_src)
              ,.reg2loc(reg2loc)
              ,.addi_en(addi_en));


//***************************************************************//
// Register file circuit
//***************************************************************//

    logic [63:0] ReadData1;
    logic [63:0] ReadData2;
    logic [63:0] WriteData;
    logic [4:0] ReadRegister1;
    logic [4:0] ReadRegister2;
    logic [4:0] WriteRegister;

    assign ReadRegister1 = rn;
    assign ReadRegister2 = reg2loc? rd : rm;
    assign WriteRegister = branch_link_sel ? 5'b11110 : rd;

    regfile registers (
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

    logic [63:0] alu_A;
    logic [63:0] alu_B;
    logic [63:0] alu_result;
    logic negative_r, negative_n;
    logic zero_r, zero_n;
    logic overflow_r, overflow_n;
    logic carry_out_r, carry_out_n;

    assign alu_A = ReadData1;
    assign alu_B = (alu_src && (ldur_en || stur_en)) ? d_imm : 
                   (alu_src && (addi_en)) ? addi_imm :
                   ReadData2;

    alu alu (
        .A(alu_A),
        .B(alu_B),
        .cntrl(alu_cntrl),
        .result(alu_result),
        .negative(negative_n),
        .zero(zero_n),
        .overflow(overflow_n),
        .carry_out(carry_out_n)
    );

    D_FF_en dff_negative (.q(negative_r), .d(negative_n), .reset(reset), .clk(clk), .en_i(set_flags));
    D_FF_en dff_zero (.q(zero_r), .d(zero_n), .reset(reset), .clk(clk), .en_i(set_flags));
    D_FF_en dff_overflow (.q(overflow_r), .d(overflow_n), .reset(reset), .clk(clk), .en_i(set_flags));
    D_FF_en dff_carry_out (.q(carry_out_r), .d(carry_out_n), .reset(reset), .clk(clk), .en_i(set_flags));

//***************************************************************//
// PC circuit
//***************************************************************//

    // Standard PC + 4
    logic [63:0] pc_add_4;
    pc_adder pc_p4_adder(.pc_r(pc_r),
                    .pc_n(pc_add_4));

    // Standard branch, branch link
    logic [63:0] pc_add_imm_26;
    branch_adder pc_imm_26_adder (.pc_r(pc_r),
                        .imm(imm_26),
                        .pc_n(pc_add_imm_26));

    // Conditional branch, branch less than
    logic [63:0] pc_add_imm_19;
    branch_adder pc_imm_19_adder (.pc_r(pc_r),
                        .imm(imm_19),
                        .pc_n(pc_add_imm_19));

    // PC muxes 

    logic [63:0] pc_26_out;

    // Standard branch, branch link
    logic pc_26_sel;
    assign pc_26_sel = branch_imm_sel | branch_link_sel;

    assign pc_26_out = pc_26_sel ? pc_add_imm_26 : pc_add_4;

    // Conditional branch, branch less than
    logic [63:0] pc_19_out;

    logic pc_19_sel;
    assign pc_19_sel = (branch_cond_sel & (negative_r ^ overflow_r)) | (branch_zero_sel & zero_n);
    assign pc_19_out = pc_19_sel ? pc_add_imm_19 : pc_26_out;

    // Branch register
    assign pc_n = branch_reg_sel ? ReadData2 : pc_19_out;

//***************************************************************//
// Data memory circuit
//***************************************************************//

    logic [63:0] mem_addr;
    logic [63:0] stur_data;
    logic [3:0] xfer_size;
    logic [63:0] ldur_data;

    assign mem_addr = alu_result;
    assign stur_data = ReadData2;
    assign xfer_size = 4'd8;
    assign WriteData = ldur_en? ldur_data 
                    : branch_link_sel ? pc_add_4
                    : alu_result;

    datamem data_memory(
        .address(mem_addr),
        .write_enable(stur_en),
        .read_enable(ldur_en),
        .write_data(stur_data),
        .clk(clk),
        .xfer_size(xfer_size), 
        .read_data(ldur_data)
	);

    // PC update
    always_ff @(posedge clk) begin
        if (reset) begin
            pc_r <= 64'h0;
        end else begin
            pc_r <= pc_n;
        end
    end
endmodule 