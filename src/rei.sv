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

    priv_lvl_e priv_lvl ;

    // registers
    logic   [XLEN-1:0] pc                   ;

    logic   [XLEN-1:0] IfId_pc              ;

    logic              IdEx_valid           ;
    logic   [XLEN-1:0] IdEx_pc              ;
    logic   [ILEN-1:0] IdEx_ir              ; // debug
    exc_s              IdEx_exc             ;
    logic              IdEx_mret            ;
    bru_ctrl_s         IdEx_bru_ctrl        ;
    alu_ctrl_s         IdEx_alu_ctrl        ;
    csr_ctrl_s         IdEx_csr_ctrl        ;
    lsu_ctrl_s         IdEx_lsu_ctrl        ;
    logic              IdEx_csr_we          ;
    logic       [11:0] IdEx_csr_addr        ;
    logic   [XLEN-1:0] IdEx_csr_rdata       ;
    logic              IdEx_rf_we           ;
    logic        [4:0] IdEx_rd              ;
    logic   [XLEN-1:0] IdEx_src1            ;
    logic   [XLEN-1:0] IdEx_src2            ;
    logic   [XLEN-1:0] IdEx_imm             ;

    logic              ExCm_valid           ;
    logic   [XLEN-1:0] ExCm_pc              ;
    logic   [ILEN-1:0] ExCm_ir              ; // debug
    exc_s              ExCm_exc             ;
    logic              ExCm_mret            ;
    logic              ExCm_tkn             ;
    logic   [XLEN-1:0] ExCm_tkn_pc          ;
    logic              ExCm_rf_we           ;
    logic        [4:0] ExCm_rd              ;
    logic   [XLEN-1:0] ExCm_rslt            ;
    logic   [XLEN-1:0] ExCm_addr            ; // debug
    logic              ExCm_wvalid          ; // debug
    logic   [XLEN-1:0] ExCm_wdata           ; // debug
    logic [XBYTES-1:0] ExCm_wstrb           ; // debug
    logic              ExCm_arvalid         ; // debug
    logic              ExCm_csr_we          ;
    logic       [11:0] ExCm_csr_addr        ;
    logic   [XLEN-1:0] ExCm_csr_rslt        ;

    // controller
    logic Cm_bmisp  ;
    assign Cm_bmisp = ExCm_valid && ExCm_tkn;

    logic Id_ready      ;
    logic Id_rd_ready   ;
    logic Id_rs1_ready  ;
    logic Id_rs2_ready  ;
    assign Id_ready = Id_rd_ready && Id_rs1_ready && Id_rs2_ready ;

    logic frontend_stall;
    assign frontend_stall   = !Id_ready ;

    logic Id_valid      ;
    logic Ex_valid      ;
    logic Cm_valid      ;
    assign Id_valid = (rst_i || Cm_bmisp || ExCm_valid && (ExCm_exc.valid || ExCm_mret) || !Id_ready) ? 1'b0 : 1'b1        ;
    assign Ex_valid = (rst_i || Cm_bmisp || ExCm_valid && (ExCm_exc.valid || ExCm_mret)             ) ? 1'b0 : IdEx_valid  ;
    assign Cm_valid = (rst_i             || ExCm_valid &&  ExCm_exc.valid                           ) ? 1'b0 : ExCm_valid  ;

    // instruction fetch
    logic [XLEN-1:0] npc        ;
    logic            eret       ;
    logic [XLEN-1:0] epc        ;
    exc_s            Cm_exc     ;
    logic [XLEN-1:0] tvec       ;

    assign npc = (         rst_i) ? RESET_VECTOR :
                 (          eret) ? epc          :
                 (  Cm_exc.valid) ? tvec         :
                 (      Cm_bmisp) ? ExCm_tkn_pc  :
                 (frontend_stall) ? pc           :
                                    pc + 4       ;

    always_ff @(posedge clk_i) pc <= npc;

    assign ibus_if.araddr   = npc           ;

    always_ff @(posedge clk_i) begin
        IfId_pc     <= npc      ;
    end

    // instruction decode
    logic [ILEN-1:0] Id_ir  ;
    assign Id_ir            = ibus_if.rdata ;

    logic            Id_is_ill_insn ;
    src1_ctrl_s      Id_src1_ctrl   ;
    src2_ctrl_s      Id_src2_ctrl   ;
    sys_ctrl_s       Id_sys_ctrl    ;
    bru_ctrl_s       Id_bru_ctrl    ;
    alu_ctrl_s       Id_alu_ctrl    ;
    csr_ctrl_s       Id_csr_ctrl    ;
    lsu_ctrl_s       Id_lsu_ctrl    ;
    logic            Id_rf_we       ;
    logic      [4:0] Id_rd          ;
    logic      [4:0] Id_rs1         ;
    logic      [4:0] Id_rs2         ;
    logic [XLEN-1:0] Id_imm         ;
    logic            Id_csr_we      ;
    logic     [11:0] Id_csr_addr    ;
    decoder decoder (
        .ir_i                   (  Id_ir                ), // input  var logic [ILEN-1:0]
        .is_ill_insn_o          (  Id_is_ill_insn       ), // output var logic
        .src1_ctrl_o            (  Id_src1_ctrl         ), // output src1_ctrl_s
        .src2_ctrl_o            (  Id_src2_ctrl         ), // output src2_ctrl_s
        .sys_ctrl_o             (  Id_sys_ctrl          ), // output sys_ctrl_s
        .bru_ctrl_o             (  Id_bru_ctrl          ), // output bru_ctrl_s
        .alu_ctrl_o             (  Id_alu_ctrl          ), // output alu_ctrl_s
        .csr_ctrl_o             (  Id_csr_ctrl          ), // output csr_ctrl_s
        .lsu_ctrl_o             (  Id_lsu_ctrl          ), // output lsu_ctrl_s
        .rf_we_o                (  Id_rf_we             ), // output var logic
        .rd_o                   (  Id_rd                ), // output var logic      [4:0]
        .rs1_o                  (  Id_rs1               ), // output var logic      [4:0]
        .rs2_o                  (  Id_rs2               ), // output var logic      [4:0]
        .imm_o                  (  Id_imm               ), // output var logic [XLEN-1:0]
        .csr_we_o               (  Id_csr_we            ), // output var logic
        .csr_addr_o             (  Id_csr_addr          )  // output var logic     [11:0]
    );

    logic            rf_ready_rst   ;
    logic [XLEN-1:0] Id_xrs1        ;
    logic [XLEN-1:0] Id_xrs2        ;
    logic            Cm_rf_we       ;
    logic [XLEN-1:0] Cm_rslt        ;

    assign rf_ready_rst = rst_i || Cm_bmisp || ExCm_valid && (ExCm_exc.valid || ExCm_mret)  ;
    assign Cm_rf_we     = Cm_valid && ExCm_rf_we                                            ;

    regfile xregs (
        .clk_i                  (clk_i                  ), // input  var logic
        .rst_i                  (rf_ready_rst           ), // input  var logic
        .rd_i                   (  Id_rd                ), // input  var logic      [4:0]
        .rs1_i                  (  Id_rs1               ), // input  var logic      [4:0]
        .rs2_i                  (  Id_rs2               ), // input  var logic      [4:0]
        .rd_ready_o             (  Id_rd_ready          ), // output var logic
        .rs1_ready_o            (  Id_rs1_ready         ), // output var logic
        .rs2_ready_o            (  Id_rs2_ready         ), // output var logic
        .xrs1_o                 (  Id_xrs1              ), // output var logic [XLEN-1:0]
        .xrs2_o                 (  Id_xrs2              ), // output var logic [XLEN-1:0]
        .we_i                   (  Cm_rf_we             ), // input  var logic
        .waddr_i                (ExCm_rd                ), // input  var logic      [4:0]
        .wdata_i                (  Cm_rslt              )  // input  var logic [XLEN-1:0]
    );

    logic            Id_is_ill_csr_acc  ;
    logic [XLEN-1:0] Id_csr_rdata       ;
    logic            Cm_csr_we          ;
    logic            Cm_mret            ;

    assign Cm_csr_we    =   Cm_valid && ExCm_csr_we     ;
    assign Cm_exc.valid = ExCm_valid && ExCm_exc.valid  ;
    assign Cm_exc.cause = ExCm_exc.cause                ;
    assign Cm_exc.tval  = ExCm_exc.tval                 ;
    assign Cm_mret      =   Cm_valid && ExCm_mret       ;

    csr_regfile #(
        .Hartid                 (Hartid                 )
    ) csr_regs (
        .clk_i                  (clk_i                  ), // input  var logic
        .rst_i                  (rst_i                  ), // input  var logic
        .priv_lvl_o             (priv_lvl               ), // output priv_lvl_e
        .csr_ctrl_i             (  Id_csr_ctrl          ), // input  csr_ctrl_s
        .is_ill_acc_o           (  Id_is_ill_csr_acc    ), // output var logic
        .raddr_i                (  Id_csr_addr          ), // input  var logic     [11:0]
        .rdata_o                (  Id_csr_rdata         ), // output var logic [XLEN-1:0]
        .we_i                   (ExCm_csr_we            ), // input  var logic
        .waddr_i                (ExCm_csr_addr          ), // input  var logic     [11:0]
        .wdata_i                (ExCm_csr_rslt          ), // input  var logic [XLEN-1:0]
        .exc_i                  (  Cm_exc               ), // input  exc_s
        .pc_i                   (ExCm_pc                ), // input  var logic [XLEN-1:0]
        .tvec_o                 (tvec                   ), // output var logic [XLEN-1:0]
        .mret_i                 (  Cm_mret              ), // input  var logic
        .eret_o                 (eret                   ), // output var logic
        .epc_o                  (epc                    )  // output var logic [XLEN-1:0]
    );

    logic [XLEN-1:0] Id_src1    ;
    logic [XLEN-1:0] Id_src2    ;
    assign Id_src1  = (Id_src1_ctrl.use_uimm) ? {{XLEN-5{1'b0}}, Id_rs1} :
                      (Id_src1_ctrl.use_pc  ) ?                  IfId_pc :
                                                                 Id_xrs1 ;
    assign Id_src2  = (Id_src2_ctrl.use_imm ) ?                   Id_imm :
                                                                 Id_xrs2 ;

    // exceptions
    exc_s Id_exc;
    always_comb begin
        Id_exc.valid    = 1'b0  ;
        Id_exc.cause    = 'h0   ;
        Id_exc.tval     = 'h0   ;
        if (Id_valid && !Id_exc.valid) begin
            if (Id_is_ill_insn || Id_is_ill_csr_acc) begin // illegal instruction
                Id_exc.valid    = 1'b1                                          ;
                Id_exc.cause    = CAUSE_ILLEGAL_INSTRUCTION                     ;
                Id_exc.tval     = {{XLEN-ILEN{1'b0}}, Id_ir}                    ;
            end
            if (Id_sys_ctrl.is_ecall) begin // environment call
                Id_exc.valid    = 1'b1                                          ;
                Id_exc.cause    = CAUSE_USER_ECALL + {{XLEN-2{1'b0}}, priv_lvl} ;
                Id_exc.tval     = 'h0                                           ;
            end
            if (Id_sys_ctrl.is_ebreak) begin // environment break
                Id_exc.valid    = 1'b1                                          ;
                Id_exc.cause    = CAUSE_BREAKPOINT                              ;
                Id_exc.tval     = 'h0                                           ;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        IdEx_valid              <=   Id_valid           ;
        IdEx_pc                 <= IfId_pc              ;
        IdEx_ir                 <=   Id_ir              ; // debug
        IdEx_exc                <=   Id_exc             ;
        IdEx_mret               <=   Id_sys_ctrl.is_mret;
        IdEx_bru_ctrl           <=   Id_bru_ctrl        ;
        IdEx_alu_ctrl           <=   Id_alu_ctrl        ;
        IdEx_csr_ctrl           <=   Id_csr_ctrl        ;
        IdEx_lsu_ctrl           <=   Id_lsu_ctrl        ;
        IdEx_csr_we             <=   Id_csr_we          ;
        IdEx_csr_addr           <=   Id_csr_addr        ;
        IdEx_csr_rdata          <=   Id_csr_rdata       ;
        IdEx_rf_we              <=   Id_rf_we           ;
        IdEx_rd                 <=   Id_rd              ;
        IdEx_src1               <=   Id_src1            ;
        IdEx_src2               <=   Id_src2            ;
        IdEx_imm                <=   Id_imm             ;
    end

    // execution
    logic            Ex_tkn     ;
    logic [XLEN-1:0] Ex_tkn_pc  ;
    logic [XLEN-1:0] Ex_bru_rslt;
    bru bru (
        .bru_ctrl_i             (IdEx_bru_ctrl          ), // input  bru_ctrl_s
        .src1_i                 (IdEx_src1              ), // input  var logic [XLEN-1:0]
        .src2_i                 (IdEx_src2              ), // input  var logic [XLEN-1:0]
        .pc_i                   (IdEx_pc                ), // input  var logic [XLEN-1:0]
        .imm_i                  (IdEx_imm               ), // input  var logic [XLEN-1:0]
        .tkn_o                  (  Ex_tkn               ), // output var logic
        .tkn_pc_o               (  Ex_tkn_pc            ), // output var logic [XLEN-1:0]
        .rslt_o                 (  Ex_bru_rslt          )  // output var logic [XLEN-1:0]
    );

    logic [XLEN-1:0] Ex_alu_rslt;
    alu alu (
        .alu_ctrl_i             (IdEx_alu_ctrl          ), // input  alu_ctrl_s
        .src1_i                 (IdEx_src1              ), // input  var logic [XLEN-1:0]
        .src2_i                 (IdEx_src2              ), // input  var logic [XLEN-1:0]
        .rslt_o                 (  Ex_alu_rslt          )  // output var logic [XLEN-1:0]
    );

    logic [XLEN-1:0] Ex_csr_rslt;
    csralu csralu (
        .csr_ctrl_i             (IdEx_csr_ctrl          ), // input  csr_ctrl_s
        .csr_i                  (IdEx_csr_rdata         ), // input  var logic [XLEN-1:0]
        .src1_i                 (IdEx_src1              ), // input  var logic [XLEN-1:0]
        .rslt_o                 (  Ex_csr_rslt          )  // output var logic [XLEN-1:0]
    );

    logic [XLEN-1:0] Ex_rslt   ;
    assign Ex_rslt  = Ex_bru_rslt | Ex_alu_rslt | IdEx_csr_rdata;

    always_ff @(posedge clk_i) begin
        ExCm_valid      <=   Ex_valid       ;
        ExCm_pc         <= IdEx_pc          ;
        ExCm_ir         <= IdEx_ir          ; // debug
        ExCm_exc        <= IdEx_exc         ;
        ExCm_mret       <= IdEx_mret        ;
        ExCm_tkn        <=   Ex_tkn         ;
        ExCm_tkn_pc     <=   Ex_tkn_pc      ;
        ExCm_rf_we      <= IdEx_rf_we       ;
        ExCm_rd         <= IdEx_rd          ;
        ExCm_rslt       <=   Ex_rslt        ;
        ExCm_addr       <= dbus_if.addr     ; // debug
        ExCm_wvalid     <= dbus_if.wvalid   ; // debug
        ExCm_wdata      <= dbus_if.wdata    ; // debug
        ExCm_wstrb      <= dbus_if.wstrb    ; // debug
        ExCm_arvalid    <= dbus_if.arvalid  ; // debug
        ExCm_csr_we     <= IdEx_csr_we      ;
        ExCm_csr_addr   <= IdEx_csr_addr    ;
        ExCm_csr_rslt   <=   Ex_csr_rslt    ;
    end

    logic [XLEN-1:0] Cm_lsu_rslt;
    lsu lsu (
        .clk_i                  (clk_i                  ), // input  var logic
        .lsu_ctrl_i             (IdEx_lsu_ctrl          ), // input  lsu_ctrl_s
        .src1_i                 (IdEx_src1              ), // input  var logic [XLEN-1:0]
        .src2_i                 (IdEx_src2              ), // input  var logic [XLEN-1:0]
        .imm_i                  (IdEx_imm               ), // input  var logic [XLEN-1:0]
        .dbus_if                (dbus_if                ), // dbus_if.mgr
        .rslt_o                 (  Cm_lsu_rslt          )  // output var logic [XLEN-1:0]
    );

    // commit
    assign Cm_rslt  = ExCm_rslt | Cm_lsu_rslt   ;

endmodule

`default_nettype wire
`resetall
