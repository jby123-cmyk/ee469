module control(input logic [10:0] opcode
              ,output logic [2:0] alu_cntrl
              ,output logic reg_write_en
              ,output logic ldur_en
              ,output logic stur_en
              ,output logic branch_imm_sel
              ,output logic branch_reg_sel
              ,output logic branch_cond_sel
              ,output logic branch_link_sel
              ,output logic branch_zero_sel
              ,output logic set_flags
              ,output logic alu_src
              ,output logic reg2loc
              );

    always_comb begin
        casez (opcode)
            // Branch unconditional
            11'b000_101?_????: begin
                alu_cntrl = 3'b000;
                reg_write_en = 1'b0;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b1;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b0;
                reg2loc = 1'b0;
            end
            // Branch less than
            11'b010_1010_0???: begin
                alu_cntrl = 3'b010;
                reg_write_en = 1'b0;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b1;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b0;
                reg2loc = 1'b0;
            end
            // Branch link
            11'b100_101?_????: begin
                alu_cntrl = 3'b000;
                reg_write_en = 1'b1;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b1;
                branch_zero_sel = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b0;
                reg2loc = 1'b0;
            end
            // Branch register
            11'b110_1011_0000: begin
                alu_cntrl = 3'b000;
                reg_write_en = 1'b0;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b1;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b0;
                reg2loc = 1'b0;
            end
            // Conditional branch zero
            11'b101_1010_0???: begin
                alu_cntrl = 3'b000;
                reg_write_en = 1'b0;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b1;
                set_flags = 1'b0;
                alu_src = 1'b0;
                reg2loc = 1'b1;
            end
            // Add immediate
            11'b100_0100_100?: begin
                alu_cntrl = 3'b010;
                reg_write_en = 1'b1;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b1;
                reg2loc = 1'b0;
            end
            // Add and set flags
            11'b101_0101_1000: begin
                alu_cntrl = 3'b010;
                reg_write_en = 1'b1;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b1;
                alu_src = 1'b0;
                reg2loc = 1'b0;
            end
            // Subtract and set flags
            11'b111_0101_1000: begin
                alu_cntrl = 3'b011;
                reg_write_en = 1'b1;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b1;
                alu_src = 1'b0;
                reg2loc = 1'b0;
            end
            // Load
            11'b111_1100_0010: begin
                alu_cntrl = 3'b000;
                reg_write_en = 1'b0;
                ldur_en = 1'b1;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b1;
                reg2loc = 1'b0;
            end
            // Store
            11'b111_1100_0000: begin    
                alu_cntrl = 3'b000;
                reg_write_en = 1'b0;
                ldur_en = 1'b0;
                stur_en = 1'b1;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b1;
                reg2loc = 1'b1;
            end
            default: begin
                alu_cntrl = 3'b000;
                reg_write_en = 1'b0;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                branch_imm_sel = 1'b0;
                branch_reg_sel = 1'b0;
                branch_cond_sel = 1'b0;
                branch_link_sel = 1'b0;
                branch_zero_sel = 1'b0;
                ldur_en = 1'b0;
                stur_en = 1'b0;
                set_flags = 1'b0;
                alu_src = 1'b0;
                reg2loc = 1'b0;
            end
        endcase
    end
endmodule