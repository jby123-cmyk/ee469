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

    logic [4:0] rd, rn, rm;
    assign rd = instruction[4:0];
    assign rn = instruction[9:5];
    assign rm = instruction[20:16];
    
    logic [12:0] imm12;
    assign imm12 = {{52{instruction[21]}}, instruction[21:10]};

    logic [25:0] imm_26;
    assign imm_26 = instruction[25:0];

    logic [18:0] imm_19;
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
// Register file circuit
//***************************************************************//

    logic [63:0] ReadData1;
    logic [63:0] ReadData2;
    logic [63:0] WriteData;
    logic [4:0] ReadRegister1;
    logic [4:0] ReadRegister2;
    logic [4:0] WriteRegister;
    logic reg_write_en;

    assign ReadRegister1 = rn;
    assign ReadRegister2 = reg2loc? rd : rm;
    assign WriteRegister = rd;

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

    logic [63:0] alu_A;
    logic [63:0] alu_B;
    logic [2:0] alu_cntrl;
    logic [63:0] alu_result;
    logic negative_r, negative_n;
    logic zero_r, zero_n;
    logic overflow_r, overflow_n;
    logic carry_out_r, carry_out_n;

    assign alu_A = ReadData1;
    assign alu_B = alu_src? imm12 : ReadData2;

    alu (
        .A(alu_A),
        .B(alu_b),
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
    assign pc_19_sel = (branch_cond_sel & (negative_r ^ overflow_r)) | (branch_zero_sel & zero_r);
    mux2_1(.z_o(pc_19_out),
            .a_i(pc_26_out),
            .b_i(pc_add_imm_19),
            .sel_i(pc_19_sel));

    // Branch register
    mux2_1(.z_o(pc_n),
            .a_i(pc_19_out),
            .b_i(ReadData1),
            .sel_i(branch_reg_sel));

//***************************************************************//
// Data memory circuit
//***************************************************************//

    logic stur_en;
    logic ldur_en;
    logic [63:0] mem_addr;
    logic [63:0] stur_data;
    logic [3:0] xfer_size;
    logic [63:0] ldur_data;

    assign mem_addr = alu_result;
    assign stur_data = ReadData2;
    assign xfer_size = 7'b1000000;
    assign WriteData = ldur_en? ldur_data : alu_result;

    datamem (
        .address(mem_addr),
        .write_enable(stur_en),
        .read_enable(ldur_en),
        .write_data(stur_data),
        .clk(clk),
        .xfer_size(xfer_size), 
        .read_data(ldur_data)
	);

    // PC update
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_r <= 64'h0;
        end else begin
            pc_r <= pc_n;
        end
    end
endmodule 