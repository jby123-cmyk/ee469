module cpu(input logic clk, reset);

    // PC circuit
    logic [25:0] imm;

    assign imm = instruction[25:0];
    
    logic [63:0] pc_add_4, pc_add_imm;
    logic [63:0] pc_r, pc_n;
    logic pc_sel;

    pc_adder(.pc_in(pc_r),
                    .pc_out(pc_add_4));

    branch_adder(.pc_in(pc_r),
                        .imm(imm),
                        .pc_out(pc_add_imm));
    
    mux2_1(.z_o(pc_n),
            .a_i(pc_add_4),
            .b_i(pc_add_imm),
            .sel_i(pc_sel));


    // Instruction memory circuit
    logic [31:0] instruction;

    instructmem (
	    .address(pc_r),
	    .instruction(instruction),
	    .clk(clk)
	);

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
    logic RegWrite;

    regfile (
        .ReadData1(ReadData1),
        .ReadData2(ReadData2),
        .WriteData(WriteData),
        .ReadRegister1(ReadRegister1),
        .ReadRegister2(ReadRegister2),
        .WriteRegister(WriteRegister),
        .RegWrite(RegWrite),
        .clk(clk)
    ); 

    logic [2:0] cntrl;
    logic [63:0] result;
    logic negative;
    logic zero;
    logic overflow;
    logic carry_out;

    // ALU circuit

    alu (
        .A(ReadData1),
        .B(ReadData2),
        .cntrl(cntrl),
        .result(result),
        .negative(negative),
        .zero(zero),
        .overflow(overflow),
        .carry_out(carry_out)
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