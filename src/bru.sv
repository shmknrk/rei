`resetall
`default_nettype none

module bru
    import rei_pkg::*;
(
    input  bru_ctrl_s           bru_ctrl_i  ,
    input  var logic [XLEN-1:0] src1_i      ,
    input  var logic [XLEN-1:0] src2_i      ,
    input  var logic [XLEN-1:0] pc_i        ,
    input  var logic [XLEN-1:0] imm_i       ,
    output var logic            tkn_o       ,
    output var logic [XLEN-1:0] tkn_pc_o    ,
    output var logic [XLEN-1:0] rslt_o
);

    logic signed [XLEN:0] sext_src1 ;
    logic signed [XLEN:0] sext_src2 ;
    assign sext_src1    = {bru_ctrl_i.is_signed && src1_i[XLEN-1], src1_i}  ;
    assign sext_src2    = {bru_ctrl_i.is_signed && src2_i[XLEN-1], src2_i}  ;

    logic beq_bne_tkn   ;
    logic blt_bge_tkn   ;
    assign beq_bne_tkn  = (   src1_i ==    src2_i) ? bru_ctrl_i.is_beq : bru_ctrl_i.is_bne  ;
    assign blt_bge_tkn  = (sext_src1 <  sext_src2) ? bru_ctrl_i.is_blt : bru_ctrl_i.is_bge  ;
    assign tkn_o        = beq_bne_tkn || blt_bge_tkn || bru_ctrl_i.is_jal_jalr              ;

    assign tkn_pc_o     = ((bru_ctrl_i.is_jalr) ? {src1_i[XLEN-1:1], 1'b0} : pc_i) + imm_i  ;

    assign rslt_o       = (bru_ctrl_i.is_jal_jalr) ? pc_i + 'h4 : 'h0                       ;

endmodule

`default_nettype wire
`resetall
