`resetall
`default_nettype none

module decoder
    import rei_pkg::*;
(
    input  var logic [ILEN-1:0] ir_i            ,
    output var logic            is_ill_insn_o   ,
    output src1_ctrl_s          src1_ctrl_o     ,
    output src2_ctrl_s          src2_ctrl_o     ,
    output sys_ctrl_s           sys_ctrl_o      ,
    output bru_ctrl_s           bru_ctrl_o      ,
    output alu_ctrl_s           alu_ctrl_o      ,
    output csr_ctrl_s           csr_ctrl_o      ,
    output mul_ctrl_s           mul_ctrl_o      ,
    output lsu_ctrl_s           lsu_ctrl_o      ,
    output var logic            rf_we_o         ,
    output var logic      [4:0] rd_o            ,
    output var logic      [4:0] rs1_o           ,
    output var logic      [4:0] rs2_o           ,
    output var logic [XLEN-1:0] imm_o           ,
    output var logic            csr_we_o        ,
    output var logic     [11:0] csr_addr_o
);

    logic [ILEN-1:0] ir         ;
    logic      [6:0] opcode     ;
    logic      [2:0] funct3     ;
    logic      [6:0] funct7     ;

    insn_type_s      insn_type  ;

    logic            imm_0      ;
    logic      [3:0] imm_4_1    ;
    logic      [5:0] imm_10_5   ;
    logic            imm_11     ;
    logic      [7:0] imm_19_12  ;
    logic     [10:0] imm_30_20  ;

    assign ir           = ir_i      ;
    assign opcode       = ir[6:0]   ;
    assign funct3       = ir[14:12] ;
    assign funct7       = ir[31:25] ;

    assign rf_we_o      = |rd_o     ;
    assign imm_o        = {{XLEN-31{ir[31]}}, imm_30_20, imm_19_12, imm_11, imm_10_5, imm_4_1, imm_0};
    assign csr_we_o     = csr_ctrl_o.is_csr && !csr_ctrl_o.is_read  ;
    assign csr_addr_o   = (csr_ctrl_o.is_csr) ? ir[31:20] : 12'h000 ;

    always_comb begin

        insn_type           = 'h0   ;
        is_ill_insn_o       = 1'b0  ;
        src1_ctrl_o         = 'h0   ;
        src2_ctrl_o         = 'h0   ;
        sys_ctrl_o          = 'h0   ;
        bru_ctrl_o          = 'h0   ;
        alu_ctrl_o          = 'h0   ;
        csr_ctrl_o          = 'h0   ;
        mul_ctrl_o          = 'h0   ;
        lsu_ctrl_o          = 'h0   ;

        unique case (opcode[1:0])
            2'b11   : begin
                unique case (opcode[6:2])
                    5'b11100: begin // SYSTEM
                        unique case (funct3)
                            3'b000  : begin
                                unique case ({ir[31:25], ir[11:7]})
                                    12'b000000000000: begin // ecall/ebreak
                                        unique case (ir[24:15])
                                            10'b0000000000  : sys_ctrl_o.is_ecall   = 1'b1  ; // ecall
                                            10'b0000100000  : sys_ctrl_o.is_ebreak  = 1'b1  ; // ebreak
                                            default         : is_ill_insn_o         = 1'b1  ;
                                        endcase
                                    end
                                    12'b001100000000: begin // mret
                                        if (ir[24:15] == 10'b0001000000) sys_ctrl_o.is_mret = 1'b1  ; // mret
                                        else                             is_ill_insn_o      = 1'b1  ;
                                    end
                                    default         : is_ill_insn_o = 1'b1  ;
                                endcase
                            end
                            3'b001  : begin                              csr_ctrl_o.is_csr = 1'b1; if (|ir[19:15]) csr_ctrl_o.is_write = 1'b1; else csr_ctrl_o.is_read = 1'b1; end // csrrw
                            3'b010  : begin                              csr_ctrl_o.is_csr = 1'b1; if (|ir[19:15]) csr_ctrl_o.is_set   = 1'b1; else csr_ctrl_o.is_read = 1'b1; end // csrrs
                            3'b011  : begin                              csr_ctrl_o.is_csr = 1'b1; if (|ir[19:15]) csr_ctrl_o.is_clear = 1'b1; else csr_ctrl_o.is_read = 1'b1; end // csrrc
                            3'b101  : begin src1_ctrl_o.use_uimm = 1'b1; csr_ctrl_o.is_csr = 1'b1; if (|ir[19:15]) csr_ctrl_o.is_write = 1'b1; else csr_ctrl_o.is_read = 1'b1; end // csrrwi
                            3'b110  : begin src1_ctrl_o.use_uimm = 1'b1; csr_ctrl_o.is_csr = 1'b1; if (|ir[19:15]) csr_ctrl_o.is_set   = 1'b1; else csr_ctrl_o.is_read = 1'b1; end // csrrsi
                            3'b111  : begin src1_ctrl_o.use_uimm = 1'b1; csr_ctrl_o.is_csr = 1'b1; if (|ir[19:15]) csr_ctrl_o.is_clear = 1'b1; else csr_ctrl_o.is_read = 1'b1; end // csrrci
                            default : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b00011: begin // MISC-MEM
                        insn_type.itype         = 1'b1  ;
                        unique case (funct3)
                            3'b000  : ; // fence
                            default : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b01101: begin // LUI
                        insn_type.utype         = 1'b1  ;
                        src2_ctrl_o.use_imm     = 1'b1  ;
                        alu_ctrl_o.is_add       = 1'b1  ;
                    end
                    5'b00101: begin // AUIPC
                        insn_type.utype         = 1'b1  ;
                        src1_ctrl_o.use_pc      = 1'b1  ;
                        src2_ctrl_o.use_imm     = 1'b1  ;
                        alu_ctrl_o.is_add       = 1'b1  ;
                    end
                    5'b11011: begin // JAL
                        insn_type.jtype         = 1'b1  ;
                        bru_ctrl_o.is_jal_jalr  = 1'b1  ;
                    end
                    5'b11001: begin // JALR
                        insn_type.itype         = 1'b1  ;
                        bru_ctrl_o.is_jal_jalr  = 1'b1  ;
                        bru_ctrl_o.is_jalr      = 1'b1  ;
                    end
                    5'b11000: begin // BRANCH
                        insn_type.btype         = 1'b1  ;
                        unique case (funct3)
                            3'b000  : begin                              bru_ctrl_o.is_beq = 1'b1; end // beq
                            3'b001  : begin                              bru_ctrl_o.is_bne = 1'b1; end // bne
                            3'b100  : begin bru_ctrl_o.is_signed = 1'b1; bru_ctrl_o.is_blt = 1'b1; end // blt
                            3'b101  : begin bru_ctrl_o.is_signed = 1'b1; bru_ctrl_o.is_bge = 1'b1; end // bge
                            3'b110  : begin                              bru_ctrl_o.is_blt = 1'b1; end // bltu
                            3'b111  : begin                              bru_ctrl_o.is_bge = 1'b1; end // bgeu
                            default : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b00000: begin // LOAD
                        insn_type.itype         = 1'b1  ;
                        lsu_ctrl_o.is_load      = 1'b1  ;
                        unique case (funct3)
                            3'b000  : begin lsu_ctrl_o.is_signed    = 1'b1; lsu_ctrl_o.is_byte  = 1'b1; end // lb
                            3'b001  : begin lsu_ctrl_o.is_signed    = 1'b1; lsu_ctrl_o.is_half  = 1'b1; end // lh
                            3'b010  : begin lsu_ctrl_o.is_signed    = 1'b1; lsu_ctrl_o.is_word  = 1'b1; end // lw
                            3'b011  : begin                                 lsu_ctrl_o.is_dword = 1'b1; end // ld
                            3'b100  : begin                                 lsu_ctrl_o.is_byte  = 1'b1; end // lb
                            3'b101  : begin                                 lsu_ctrl_o.is_half  = 1'b1; end // lh
                            3'b110  : begin                                 lsu_ctrl_o.is_word  = 1'b1; end // lw
                            default : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b01000: begin // STORE
                        insn_type.stype         = 1'b1  ;
                        lsu_ctrl_o.is_store     = 1'b1  ;
                        unique case (funct3)
                            3'b000  : begin lsu_ctrl_o.is_byte  = 1'b1; end // sb
                            3'b001  : begin lsu_ctrl_o.is_half  = 1'b1; end // sh
                            3'b010  : begin lsu_ctrl_o.is_word  = 1'b1; end // sw
                            3'b011  : begin lsu_ctrl_o.is_dword = 1'b1; end // sd
                            default : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b00100: begin // OP-IMM
                        insn_type.itype         = 1'b1  ;
                        src2_ctrl_o.use_imm     = 1'b1  ;
                        unique case (funct3)
                            3'b000  : begin                                                           alu_ctrl_o.is_add  = 1'b1; end // addi
                            3'b010  : begin alu_ctrl_o.is_signed = 1'b1; alu_ctrl_o.is_neg    = 1'b1; alu_ctrl_o.is_less = 1'b1; end // slti
                            3'b011  : begin                              alu_ctrl_o.is_neg    = 1'b1; alu_ctrl_o.is_less = 1'b1; end // sltiu
                            3'b100  : begin alu_ctrl_o.is_xor    = 1'b1;                                                         end // xori
                            3'b110  : begin alu_ctrl_o.is_xor    = 1'b1; alu_ctrl_o.is_and    = 1'b1;                            end // ori
                            3'b111  : begin                              alu_ctrl_o.is_and    = 1'b1;                            end // andi
                            3'b001  : begin // slli
                                if (ir[31:26] == 6'b000000) alu_ctrl_o.is_sl    = 1'b1  ; // slli
                                else                        is_ill_insn_o       = 1'b1  ;
                            end
                            3'b101  : begin // srli/srai
                                unique case (ir[31:26])
                                    6'b000000   : begin                              alu_ctrl_o.is_sr = 1'b1; end // srli
                                    6'b010000   : begin alu_ctrl_o.is_signed = 1'b1; alu_ctrl_o.is_sr = 1'b1; end // srai
                                    default     : is_ill_insn_o = 1'b1  ;
                                endcase
                            end
                            default : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b01100: begin // OP
                        unique case ({funct7, funct3})
                            10'b0000000000  : begin                                                         alu_ctrl_o.is_add  = 1'b1; end // add
                            10'b0100000000  : begin                              alu_ctrl_o.is_neg  = 1'b1; alu_ctrl_o.is_add  = 1'b1; end // sub
                            10'b0000000001  : begin                                                         alu_ctrl_o.is_sl   = 1'b1; end // sll
                            10'b0000000010  : begin alu_ctrl_o.is_signed = 1'b1; alu_ctrl_o.is_neg  = 1'b1; alu_ctrl_o.is_less = 1'b1; end // slt
                            10'b0000000011  : begin                              alu_ctrl_o.is_neg  = 1'b1; alu_ctrl_o.is_less = 1'b1; end // sltu
                            10'b0000000100  : begin                              alu_ctrl_o.is_xor  = 1'b1;                            end // xor
                            10'b0000000101  : begin                                                         alu_ctrl_o.is_sr   = 1'b1; end // srl
                            10'b0100000101  : begin alu_ctrl_o.is_signed = 1'b1;                            alu_ctrl_o.is_sr   = 1'b1; end // sra
                            10'b0000000110  : begin                              alu_ctrl_o.is_xor  = 1'b1; alu_ctrl_o.is_and  = 1'b1; end // or
                            10'b0000000111  : begin                                                         alu_ctrl_o.is_and  = 1'b1; end // and
                            10'b0000001000  : begin mul_ctrl_o.is_mul = 1'b1;                                                                                                end // mul
                            10'b0000001001  : begin mul_ctrl_o.is_mul = 1'b1; mul_ctrl_o.is_src1_signed = 1'b1; mul_ctrl_o.is_src2_signed = 1'b1; mul_ctrl_o.is_high = 1'b1; end // mulh
                            10'b0000001010  : begin mul_ctrl_o.is_mul = 1'b1; mul_ctrl_o.is_src1_signed = 1'b1;                                   mul_ctrl_o.is_high = 1'b1; end // mulhsu
                            10'b0000001011  : begin mul_ctrl_o.is_mul = 1'b1;                                                                     mul_ctrl_o.is_high = 1'b1; end // mulhu
                            default         : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b00110: begin // OP-IMM-32
                        insn_type.itype         = 1'b1  ;
                        src2_ctrl_o.use_imm     = 1'b1  ;
                        alu_ctrl_o.is_word      = 1'b1  ;
                        unique case (funct3)
                            3'b000  : begin alu_ctrl_o.is_add = 1'b1; end // addiw
                            3'b001  : begin // slliw
                                if (funct7 == 7'b0000000) alu_ctrl_o.is_sl  = 1'b1  ; // slliw
                                else                      is_ill_insn_o     = 1'b1  ;
                            end
                            3'b101  : begin // srliw/sraiw
                                unique case (funct7)
                                    7'b0000000  : begin                              alu_ctrl_o.is_sr = 1'b1; end // srliw
                                    7'b0100000  : begin alu_ctrl_o.is_signed = 1'b1; alu_ctrl_o.is_sr = 1'b1; end // sraiw
                                    default     : is_ill_insn_o = 1'b1  ;
                                endcase
                            end
                            default : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    5'b01110: begin // OP-32
                        alu_ctrl_o.is_word  = 1'b1  ;
                        unique case ({funct7, funct3})
                            10'b0000000000  : begin                              alu_ctrl_o.is_add  = 1'b1; end // addw
                            10'b0100000000  : begin alu_ctrl_o.is_neg    = 1'b1; alu_ctrl_o.is_add  = 1'b1; end // subw
                            10'b0000000001  : begin                              alu_ctrl_o.is_sl   = 1'b1; end // sllw
                            10'b0000000101  : begin                              alu_ctrl_o.is_sr   = 1'b1; end // srlw
                            10'b0100000101  : begin alu_ctrl_o.is_signed = 1'b1; alu_ctrl_o.is_sr   = 1'b1; end // sraw
                            10'b0000001000  : begin mul_ctrl_o.is_mul    = 1'b1; mul_ctrl_o.is_word = 1'b1; end // mul
                            default         : is_ill_insn_o = 1'b1  ;
                        endcase
                    end
                    default : is_ill_insn_o = 1'b1  ;
                endcase
            end
            default : is_ill_insn_o = 1'b1  ;
        endcase

        // register
        unique case (1'b1)
            insn_type.stype, insn_type.btype                    : rd_o  = 5'h0      ;
            default                                             : rd_o  = ir[11:7]  ;
        endcase
        unique case (1'b1)
            insn_type.utype, insn_type.jtype                    : rs1_o = 5'h0      ;
            default                                             : rs1_o = ir[19:15] ;
        endcase
        unique case (1'b1)
            insn_type.itype, insn_type.utype, insn_type.jtype   : rs2_o = 5'h0      ;
            default                                             : rs2_o = ir[24:20] ;
        endcase

        // immediate value
        unique case (1'b1)
            insn_type.itype                     : imm_0     = ir[20]        ;
            insn_type.stype                     : imm_0     = ir[7]         ;
            default                             : imm_0     = 1'b0          ;
        endcase
        unique case (1'b1)
            insn_type.stype, insn_type.btype    : imm_4_1   = ir[11:8]      ;
            insn_type.utype                     : imm_4_1   = 4'h0          ;
            default                             : imm_4_1   = ir[24:21]     ;
        endcase
        unique case (1'b1)
            insn_type.utype                     : imm_10_5  = 6'h0          ;
            default                             : imm_10_5  = ir[30:25]     ;
        endcase
        unique case (1'b1)
            insn_type.btype                     : imm_11    = ir[7]         ;
            insn_type.utype                     : imm_11    = 1'b0          ;
            insn_type.jtype                     : imm_11    = ir[20]        ;
            default                             : imm_11    = ir[31]        ;
        endcase
        unique case (1'b1)
            insn_type.utype, insn_type.jtype    : imm_19_12 = ir[19:12]     ;
            default                             : imm_19_12 = {8{ir[31]}}   ;
        endcase
        unique case (1'b1)
            insn_type.utype                     : imm_30_20 = ir[30:20]     ;
            default                             : imm_30_20 = {11{ir[31]}}  ;
        endcase

    end

endmodule

`default_nettype none
`resetall
