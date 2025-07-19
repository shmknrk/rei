`resetall
`default_nettype none

`include "log.svh"

module rei
    import rei_pkg::*;
#(
    parameter  Hartid   = -1
) (
    input  var logic clk_i      ,
    input  var logic rst_i      ,
    ibus_if.mgr      ibus_if    ,
    dbus_if.mgr      dbus_if
);

    // DRC: design rule check
    initial begin
        if (Hartid == -1) `FATAL("specify a proper hartid");
    end

    logic rst = 1'b1;
    always_ff @(posedge clk_i) rst <= rst_i;

    priv_lvl_e priv_lvl ;

    // registers
    logic   [XLEN-1:0] pc               ;

    logic              ExCm_valid       ;
    logic   [XLEN-1:0] ExCm_pc          ;
    logic   [ILEN-1:0] ExCm_ir          ; // debug
    exc_s              ExCm_exc         ;
    logic              ExCm_mret        ;
    logic              ExCm_csr_we      ;
    logic       [11:0] ExCm_csr_addr    ;
    logic   [XLEN-1:0] ExCm_csr_rslt    ;
    logic              ExCm_rf_we       ;
    logic        [4:0] ExCm_rd          ;
    logic   [XLEN-1:0] ExCm_rslt        ;
    logic   [XLEN-1:0] ExCm_addr        ; // debug
    logic              ExCm_wvalid      ; // debug
    logic   [XLEN-1:0] ExCm_wdata       ; // debug
    logic [XBYTES-1:0] ExCm_wstrb       ; // debug
    logic              ExCm_arvalid     ; // debug

    // controller
    logic            valid      ;
    logic            Cm_valid   ;
    assign valid    = (rst || ExCm_valid && (ExCm_exc.valid || ExCm_mret)) ? 1'b0 : 1'b1        ;
    assign Cm_valid = (rst || ExCm_valid &&  ExCm_exc.valid              ) ? 1'b0 : ExCm_valid  ;

    // instruction fetch
    logic [XLEN-1:0] npc        ;
    logic            eret       ;
    logic [XLEN-1:0] epc        ;
    exc_s            Cm_exc     ;
    logic [XLEN-1:0] tvec       ;
    logic            tkn        ;
    logic [XLEN-1:0] tkn_pc     ;

    assign npc = (         rst) ? RESET_VECTOR :
                 (        eret) ? epc          :
                 (Cm_exc.valid) ? tvec         :
                 (         tkn) ? tkn_pc       :
                                  pc + 4       ;

    always_ff @(posedge clk_i) pc <= npc;

    assign ibus_if.araddr   = npc           ;

    // instruction decode
    logic [ILEN-1:0] ir     ;
    assign ir               = ibus_if.rdata ;

    logic            is_ill_insn    ;
    src1_ctrl_s      src1_ctrl      ;
    src2_ctrl_s      src2_ctrl      ;
    sys_ctrl_s       sys_ctrl       ;
    bru_ctrl_s       bru_ctrl       ;
    alu_ctrl_s       alu_ctrl       ;
    csr_ctrl_s       csr_ctrl       ;
    lsu_ctrl_s       lsu_ctrl       ;
    logic            rf_we          ;
    logic      [4:0] rd             ;
    logic      [4:0] rs1            ;
    logic      [4:0] rs2            ;
    logic [XLEN-1:0] imm            ;
    logic            csr_we         ;
    logic     [11:0] csr_addr       ;
    decoder decoder (
        .ir_i                   (ir                     ), // input  wire logic [ILEN-1:0]
        .is_ill_insn_o          (is_ill_insn            ), // output      logic
        .src1_ctrl_o            (src1_ctrl              ), // output src1_ctrl_s
        .src2_ctrl_o            (src2_ctrl              ), // output src2_ctrl_s
        .sys_ctrl_o             (sys_ctrl               ), // output sys_ctrl_s
        .bru_ctrl_o             (bru_ctrl               ), // output bru_ctrl_s
        .alu_ctrl_o             (alu_ctrl               ), // output alu_ctrl_s
        .csr_ctrl_o             (csr_ctrl               ), // output csr_ctrl_s
        .lsu_ctrl_o             (lsu_ctrl               ), // output lsu_ctrl_s
        .rf_we_o                (rf_we                  ), // output     logic
        .rd_o                   (rd                     ), // output     logic      [4:0]
        .rs1_o                  (rs1                    ), // output     logic      [4:0]
        .rs2_o                  (rs2                    ), // output     logic      [4:0]
        .imm_o                  (imm                    ), // output     logic [XLEN-1:0]
        .csr_we_o               (csr_we                 ), // output     logic
        .csr_addr_o             (csr_addr               )  // output     logic     [11:0]
    );

    logic [XLEN-1:0] xrs1       ;
    logic [XLEN-1:0] xrs2       ;
    logic            Cm_rf_we   ;
    logic [XLEN-1:0] Cm_rslt    ;

    assign Cm_rf_we = Cm_valid && ExCm_rf_we;

    regfile xregs (
        .clk_i                  (clk_i                  ), // input  wire logic
        .rs1_i                  (rs1                    ), // input  wire logic      [4:0]
        .rs2_i                  (rs2                    ), // input  wire logic      [4:0]
        .xrs1_o                 (xrs1                   ), // output      logic [XLEN-1:0]
        .xrs2_o                 (xrs2                   ), // output      logic [XLEN-1:0]
        .we_i                   (  Cm_rf_we             ), // input  wire logic
        .rd_i                   (ExCm_rd                ), // input  wire logic      [4:0]
        .wdata_i                (  Cm_rslt              )  // input  wire logic [XLEN-1:0]
    );

    logic            is_ill_acc ;
    logic [XLEN-1:0] csr_rdata  ;
    logic            Cm_csr_we  ;
    logic            Cm_mret    ;

    assign Cm_csr_we    =   Cm_valid && ExCm_csr_we     ;
    assign Cm_exc.valid = ExCm_valid && ExCm_exc.valid  ;
    assign Cm_exc.cause = ExCm_exc.cause                ;
    assign Cm_exc.tval  = ExCm_exc.tval                 ;
    assign Cm_mret      =   Cm_valid && ExCm_mret       ;

    csr_regfile #(
        .Hartid                 (Hartid                 )
    ) csr_regs (
        .clk_i                  (clk_i                  ), // input  wire logic
        .rst_i                  (rst                    ), // input  wire logic
        .priv_lvl_o             (priv_lvl               ), // output priv_lvl_e
        .csr_ctrl_i             (csr_ctrl               ), // input  csr_ctrl_s
        .is_ill_acc_o           (is_ill_acc             ), // output      logic
        .raddr_i                (csr_addr               ), // input  wire logic     [11:0]
        .rdata_o                (csr_rdata              ), // output      logic [XLEN-1:0]
        .we_i                   (ExCm_csr_we            ), // input  wire logic
        .waddr_i                (ExCm_csr_addr          ), // input  wire logic     [11:0]
        .wdata_i                (ExCm_csr_rslt          ), // input  wire logic [XLEN-1:0]
        .exc_i                  (  Cm_exc               ), // input  exc_s
        .pc_i                   (ExCm_pc                ), // input  wire logic [XLEN-1:0]
        .tvec_o                 (tvec                   ), // output      logic [XLEN-1:0]
        .mret_i                 (  Cm_mret              ), // input  wire logic
        .eret_o                 (eret                   ), // output      logic
        .epc_o                  (epc                    )  // output      logic [XLEN-1:0]
    );

    logic [XLEN-1:0] src1               ;
    logic [XLEN-1:0] src2               ;
    logic            fwd_rs1_Cm_to_Ex   ;
    logic            fwd_rs2_Cm_to_Ex   ;

    assign fwd_rs1_Cm_to_Ex    = ExCm_valid && ExCm_rf_we && (ExCm_rd == rs1)  ;
    assign fwd_rs2_Cm_to_Ex    = ExCm_valid && ExCm_rf_we && (ExCm_rd == rs2)  ;

    assign src1    = (src1_ctrl.use_uimm) ? {{XLEN-5{1'b0}}, rs1} :
                     (src1_ctrl.use_pc  ) ?                    pc :
                     (fwd_rs1_Cm_to_Ex  ) ?               Cm_rslt :
                                                             xrs1 ;
    assign src2    = (src2_ctrl.use_imm ) ?                   imm :
                     (fwd_rs2_Cm_to_Ex  ) ?               Cm_rslt :
                                                             xrs2 ;

    // exceptions
    exc_s exc   ;
    always_comb begin
        exc.valid   = 1'b0  ;
        exc.cause   = 'h0   ;
        exc.tval    = 'h0   ;
        if (valid && !exc.valid) begin
            if (is_ill_insn || is_ill_acc) begin // illegal instruction
                exc.valid   = 1'b1                                          ;
                exc.cause   = CAUSE_ILLEGAL_INSTRUCTION                     ;
                exc.tval    = {{XLEN-ILEN{1'b0}}, ir}                       ;
            end
            if (sys_ctrl.is_ecall) begin // environment call
                exc.valid   = 1'b1                                          ;
                exc.cause   = CAUSE_USER_ECALL + {{XLEN-2{1'b0}}, priv_lvl} ;
                exc.tval    = 'h0                                           ;
            end
            if (sys_ctrl.is_ebreak) begin // environment break
                exc.valid   = 1'b1                                          ;
                exc.cause   = CAUSE_BREAKPOINT                              ;
                exc.tval    = 'h0                                           ;
            end
        end
    end

    // execution
    logic [XLEN-1:0] bru_rslt   ;
    bru bru (
        .bru_ctrl_i             (bru_ctrl               ), // input  bru_ctrl_s
        .src1_i                 (src1                   ), // input  wire logic [XLEN-1:0]
        .src2_i                 (src2                   ), // input  wire logic [XLEN-1:0]
        .pc_i                   (pc                     ), // input  wire logic [XLEN-1:0]
        .imm_i                  (imm                    ), // input  wire logic [XLEN-1:0]
        .tkn_o                  (tkn                    ), // output      logic
        .tkn_pc_o               (tkn_pc                 ), // output      logic [XLEN-1:0]
        .rslt_o                 (bru_rslt               )  // output      logic [XLEN-1:0]
    );

    logic [XLEN-1:0] alu_rslt   ;
    alu alu (
        .alu_ctrl_i             (alu_ctrl               ), // input  alu_ctrl_s
        .src1_i                 (src1                   ), // input  wire logic [XLEN-1:0]
        .src2_i                 (src2                   ), // input  wire logic [XLEN-1:0]
        .rslt_o                 (alu_rslt               )  // output      logic [XLEN-1:0]
    );

    logic [XLEN-1:0] csr_rslt   ;
    csralu csralu (
        .csr_ctrl_i             (csr_ctrl               ), // input  csr_ctrl_s
        .csr_i                  (csr_rdata              ), // input  wire logic [XLEN-1:0]
        .src1_i                 (src1                   ), // input  wire logic [XLEN-1:0]
        .rslt_o                 (csr_rslt               )  // output      logic [XLEN-1:0]
    );

    logic [XLEN-1:0] rslt   ;
    assign rslt = bru_rslt | alu_rslt | csr_rdata   ;

    always_ff @(posedge clk_i) begin
        ExCm_valid      <= valid            ;
        ExCm_pc         <= pc               ;
        ExCm_ir         <= ir               ; // debug
        ExCm_csr_we     <= csr_we           ;
        ExCm_csr_addr   <= csr_addr         ;
        ExCm_csr_rslt   <= csr_rslt         ;
        ExCm_exc        <= exc              ;
        ExCm_mret       <= sys_ctrl.is_mret ;
        ExCm_rf_we      <= rf_we            ;
        ExCm_rd         <= rd               ;
        ExCm_rslt       <= rslt             ;
        ExCm_addr       <= dbus_if.addr     ; // debug
        ExCm_wvalid     <= dbus_if.wvalid   ; // debug
        ExCm_wdata      <= dbus_if.wdata    ; // debug
        ExCm_wstrb      <= dbus_if.wstrb    ; // debug
        ExCm_arvalid    <= dbus_if.arvalid  ; // debug
    end

    logic [XLEN-1:0] Cm_lsu_rslt;
    lsu lsu (
        .clk_i                  (clk_i                  ), // input  wire logic
        .lsu_ctrl_i             (lsu_ctrl               ), // input  lsu_ctrl_s
        .src1_i                 (src1                   ), // input  wire logic [XLEN-1:0]
        .src2_i                 (src2                   ), // input  wire logic [XLEN-1:0]
        .imm_i                  (imm                    ), // input  wire logic [XLEN-1:0]
        .dbus_if                (dbus_if                ), // dbus_if.mgr
        .rslt_o                 (  Cm_lsu_rslt          )  // output      logic [XLEN-1:0]
    );

    // commit
    assign Cm_rslt  = ExCm_rslt | Cm_lsu_rslt   ;

endmodule

`default_nettype wire
`resetall
