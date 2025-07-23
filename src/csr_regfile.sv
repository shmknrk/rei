`resetall
`default_nettype none

`include "log.svh"

module csr_regfile
    import rei_pkg::*;
#(
    parameter  Hartid   = -1
) (
    input  var logic            clk_i       ,
    input  var logic            rst_i       ,
    input  var logic            stall_i     ,
    output priv_lvl_e           priv_lvl_o  ,
    input  csr_ctrl_s           csr_ctrl_i  ,
    output var logic            is_ill_acc_o,
    input  var logic     [11:0] raddr_i     ,
    output var logic [XLEN-1:0] rdata_o     ,
    input  var logic            we_i        ,
    input  var logic     [11:0] waddr_i     ,
    input  var logic [XLEN-1:0] wdata_i     ,
    input  exc_s                exc_i       ,
    input  var logic [XLEN-1:0] pc_i        ,
    output var logic [XLEN-1:0] tvec_o      ,
    input  var logic            mret_i      ,
    output var logic            eret_o      ,
    output var logic [XLEN-1:0] epc_o
);

    // DRC: design rule check
    initial begin
        if (Hartid == -1) `FATAL("specify a proper Hartid");
    end

    // privilege level
    priv_lvl_e       priv_lvl_q , priv_lvl_d;

    // machine trap setup
    mstatus_s        mstatus_q  , mstatus_d ;
    logic [XLEN-1:0] mie_q      , mie_d     ;
    logic [XLEN-1:0] mtvec_q    , mtvec_d   ;

    // machine trap handling
    logic [XLEN-1:0] mepc_q     , mepc_d    ;
    logic [XLEN-1:0] mcause_q   , mcause_d  ;
    logic [XLEN-1:0] mtval_q    , mtval_d   ;

    assign priv_lvl_o   = priv_lvl_q    ;

    always_comb begin

        priv_lvl_d      = priv_lvl_q    ;
        mstatus_d       = mstatus_q     ;
        mie_d           = mie_q         ;
        mtvec_d         = mtvec_q       ;
        mepc_d          = mepc_q        ;
        mcause_d        = mcause_q      ;
        mtval_d         = mtval_q       ;
        is_ill_acc_o    = 1'b0          ;
        rdata_o         = 'h0           ;

        // read
        if (csr_ctrl_i.is_csr) begin
            unique case (raddr_i[9:8]) // privilege level
                2'b11   : begin // machine-level
                    if (priv_lvl_q == PRIV_LVL_M) begin
                        unique case (raddr_i[11:10]) // read/write accessibility
                            2'b00   : begin // read/write
                                unique case (raddr_i[7:0])
                                    8'h00   : for (int i = 0; i < XLEN; i++) rdata_o[i] = (MSTATUS_READ_MASK[i]) ? mstatus_q[i] : 1'b0  ;
                                    8'h04   : rdata_o   = mie_q                     ;
                                    8'h05   : rdata_o   = {mtvec_q[XLEN-1:2], 2'b00};
                                    8'h41   : rdata_o   = { mepc_q[XLEN-1:2], 2'b00};
                                    8'h42   : rdata_o   = mcause_q                  ;
                                    8'h43   : rdata_o   = mtval_q                   ;
                                    default : is_ill_acc_o  = 1'b1  ;
                                endcase
                            end
                            2'b11   : begin // read-only
                                unique case (raddr_i[7:0])
                                    8'h14   : rdata_o   = Hartid                    ; // hartid
                                    default : is_ill_acc_o  = 1'b1  ;
                                endcase
                            end
                            default : is_ill_acc_o  = 1'b1  ;
                        endcase
                    end
                end
                default : is_ill_acc_o  = 1'b1  ;
            endcase
        end

        // write
        if (we_i) begin
            unique case (waddr_i[9:8]) // privilege level
                2'b11   : begin // machine-level
                    if (priv_lvl_q == PRIV_LVL_M) begin
                        unique case (waddr_i[11:10]) // read/write accessibility
                            2'b00   : begin // read/write
                                unique case (waddr_i[7:0])
                                    8'h00   : for (int i = 0; i < XLEN; i++) mstatus_d[i] = (MSTATUS_WRITE_MASK[i]) ? wdata_i[i] : mstatus_q[i];
                                    8'h04   : mie_d     = wdata_i                   ;
                                    8'h05   : mtvec_d   = {wdata_i[XLEN-1:2], 2'b00};
                                    8'h41   : mepc_d    = {wdata_i[XLEN-1:2], 2'b00};
                                    8'h42   : mcause_d  = wdata_i                   ;
                                    8'h43   : mtval_d   = wdata_i                   ;
                                    default : ;
                                endcase
                            end
                            default : ;
                        endcase
                    end
                end
                default : ;
            endcase
        end

        tvec_o = mtvec_q    ;
        if (exc_i.valid) begin
            if (priv_lvl_q < PRIV_LVL_M) mstatus_d.mpp   = priv_lvl_q    ; // FIXME
            mstatus_d.mpie  = mstatus_q.mie ;
            mstatus_d.mie   = 1'b0          ;
            mepc_d          = pc_i          ;
            mcause_d        = exc_i.cause   ;
            mtval_d         = exc_i.tval    ;
            priv_lvl_d      = PRIV_LVL_M    ;
        end

        eret_o  = mret_i    ;
        epc_o   = mepc_q    ;
        if (mret_i) begin
            priv_lvl_d      = mstatus_q.mpp ;
            mstatus_d.mpp   = PRIV_LVL_U    ;
            mstatus_d.mie   = mstatus_q.mpie;
            mstatus_d.mpie  = 1'b1          ;
        end

    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            priv_lvl_q  <= PRIV_LVL_M   ;
            mstatus_q   <= 'h0          ;
            mie_q       <= 'h0          ;
            mtvec_q     <= 'h0          ;
            mepc_q      <= 'h0          ;
            mcause_q    <= 'h0          ;
            mtval_q     <= 'h0          ;
        end else if (!stall_i) begin
            priv_lvl_q  <= priv_lvl_d   ;
            mstatus_q   <= mstatus_d    ;
            mie_q       <= mie_d        ;
            mtvec_q     <= mtvec_d      ;
            mepc_q      <= mepc_d       ;
            mcause_q    <= mcause_d     ;
            mtval_q     <= mtval_d      ;
        end
    end

endmodule

`default_nettype wire
`resetall
