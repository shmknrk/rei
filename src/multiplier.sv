`resetall
`default_nettype none

`include "log.svh"

module multiplier
    import rei_pkg::*;
(
    input  var logic            clk_i       ,
    input  var logic            valid_i     ,
    output var logic            stall_o     ,
    input  mul_ctrl_s           mul_ctrl_i  ,
    input  var logic [XLEN-1:0] src1_i      ,
    input  var logic [XLEN-1:0] src2_i      ,
    output var logic [XLEN-1:0] rslt_o
);

    initial begin
        if (MUL_PIPE_DEPTH < 1) `FATAL($sformatf("MUL_PIPE_DEPTH must be at least 1: %-d", MUL_PIPE_DEPTH));
    end

    logic [$clog2(MUL_PIPE_DEPTH+1)-1:0] cntr_q , cntr_d;
    assign cntr_d       = (cntr_q == MUL_PIPE_DEPTH) ? 'h0 : (|cntr_q) ? cntr_q + 'h1 : valid_i && mul_ctrl_i.is_mul;
    assign stall_o      = |cntr_q   ;

    mul_ctrl_s                 [MUL_PIPE_DEPTH:0] mul_ctrl_q    , mul_ctrl_d    ;
    logic signed                         [XLEN:0] sext_src1_q   , sext_src1_d   ;
    logic signed                         [XLEN:0] sext_src2_q   , sext_src2_d   ;
    logic signed [MUL_PIPE_DEPTH-1:0][XLEN*2+1:0] prod_q        , prod_d        ;

    assign sext_src1_d  = {mul_ctrl_i.is_src1_signed && src1_i[XLEN-1], src1_i} ;
    assign sext_src2_d  = {mul_ctrl_i.is_src2_signed && src2_i[XLEN-1], src2_i} ;

    always_comb begin
        mul_ctrl_d[0]   = mul_ctrl_i                ;
        for (int i = 1; i <= MUL_PIPE_DEPTH; i++) begin
            mul_ctrl_d[i]   = mul_ctrl_q[i-1]           ;
        end
        prod_d[0]       = sext_src1_q * sext_src2_q ;
        for (int i = 1; i < MUL_PIPE_DEPTH; i++) begin
            prod_d[i]       = prod_q[i-1]               ;
        end
    end

    always_ff @(posedge clk_i) begin
        cntr_q      <= cntr_d       ;
        for (int i = 0; i <= MUL_PIPE_DEPTH; i++) begin
            mul_ctrl_q[i]   <= mul_ctrl_d[i];
        end
        sext_src1_q <= sext_src1_d  ;
        sext_src2_q <= sext_src2_d  ;
        for (int i = 0; i < MUL_PIPE_DEPTH; i++) begin
            prod_q[i]       <= prod_d[i]    ;
        end
    end

    mul_ctrl_s         mul_ctrl ;
    logic [XLEN*2-1:0] prod     ;
    assign mul_ctrl = mul_ctrl_q[MUL_PIPE_DEPTH]            ;
    assign prod     = prod_q[MUL_PIPE_DEPTH-1][XLEN*2-1:0]  ;

    logic   [XLEN-1:0] mul_rslt ;
    assign mul_rslt = (mul_ctrl.is_high) ? prod[2*XLEN-1:XLEN] : {(mul_ctrl.is_word) ? {XLEN-32{prod[31]}} : prod[XLEN-1:32], prod[31:0]};
    assign rslt_o   = (mul_ctrl.is_mul) ? mul_rslt : 'h0;

endmodule

`default_nettype wire
`resetall
