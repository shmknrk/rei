`resetall
`default_nettype none

module alu
    import rei_pkg::*;
(
    input  alu_ctrl_s           alu_ctrl_i  ,
    input  var logic [XLEN-1:0] src1_i      ,
    input  var logic [XLEN-1:0] src2_i      ,
    output var logic [XLEN-1:0] rslt_o
);

    // adder
    logic [XLEN+1:0] adder_src1 ;
    logic [XLEN+1:0] adder_src2 ;
    logic [XLEN+1:0] adder_rslt ;
    logic [XLEN-1:0] add_rslt   ;
    assign adder_src1   = {alu_ctrl_i.is_signed && src1_i[XLEN-1], src1_i, 1'b1}                                                            ;
    assign adder_src2   = {alu_ctrl_i.is_signed && src2_i[XLEN-1], src2_i, 1'b0} ^ {XLEN+2{alu_ctrl_i.is_neg}}                              ;
    assign adder_rslt   = adder_src1 + adder_src2                                                                                           ;
    assign add_rslt     = (alu_ctrl_i.is_add) ? {(alu_ctrl_i.is_word) ? {32{adder_rslt[32]}} : adder_rslt[64:33], adder_rslt[32:1]} : 'h0   ;

    logic less_rslt ;
    assign less_rslt    = alu_ctrl_i.is_less && adder_rslt[XLEN+1]  ;

    // bitwise unit
    logic [XLEN-1:0] bitwise_rslt   ;
    assign bitwise_rslt = ((alu_ctrl_i.is_xor) ? src1_i ^ src2_i : 'h0) | ((alu_ctrl_i.is_and) ? src1_i & src2_i : 'h0) ;

    // shifter
    logic [$clog2(XLEN)-1:0] shamt  ;
    assign shamt        = {(alu_ctrl_i.is_word) ? 1'b0 : src2_i[5], src2_i[4:0]};

    // lsh: left shifter
    logic [XLEN-1:0] lsh_rslt   ;
    logic [XLEN-1:0] sl_rslt    ;
    assign lsh_rslt     = src1_i  <<  shamt                                                                                         ;
    assign sl_rslt      = (alu_ctrl_i.is_sl) ? {(alu_ctrl_i.is_word) ? {32{lsh_rslt[31]}} : lsh_rslt[63:32], lsh_rslt[31:0]} : 'h0  ;

    // rsh: right shifter
    logic signed [XLEN:0] rsh_src1  ;
    logic        [XLEN:0] rsh_rslt  ;
    logic      [XLEN-1:0] sr_rslt   ;
    assign rsh_src1     = {alu_ctrl_i.is_signed && ((alu_ctrl_i.is_word) ? src1_i[31] : src1_i[63]), (alu_ctrl_i.is_word) ? src1_i[31:0] : src1_i[63:32], src1_i[31:0]}   ;
    assign rsh_rslt     = rsh_src1 >>> shamt;
    assign sr_rslt      = (alu_ctrl_i.is_sr) ? ((alu_ctrl_i.is_word) ? {{32{rsh_rslt[63]}}, rsh_rslt[63:32]} : rsh_rslt[63:0]) : 'h0;

    assign rslt_o[63:32]    = add_rslt[63:32]             | bitwise_rslt[63:32] | sl_rslt[63:32] | sr_rslt[63:32]   ;
    assign rslt_o[31:1]     = add_rslt[31:1]              | bitwise_rslt[31:1]  | sl_rslt[31:1]  | sr_rslt[31:1]    ;
    assign rslt_o[0]        = add_rslt[0]     | less_rslt | bitwise_rslt[0]     | sl_rslt[0]     | sr_rslt[0]       ;

endmodule

`default_nettype wire
`resetall
