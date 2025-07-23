`ifndef REI_PKG_SV
`define REI_PKG_SV

`include "log.svh"

package rei_pkg;

    // cpu
    localparam                  ILEN            = 32                                ;
    localparam                  IALIGN          = 32                                ;
    localparam                  XLEN            = 64                                ;

    localparam                  XBYTES          = XLEN/8                            ;

    localparam                  VLEN            = (XLEN==64) ? 39 : 32              ; // virtual  address length
    localparam                  PLEN            = (XLEN==64) ? 56 : 34              ; // physical address length

    localparam                  MUL_PIPE_DEPTH  = 1                                 ; // > 0

    // soc
    localparam logic [XLEN-1:0] RESET_VECTOR    = 64'h80000000                      ;

    // memory
    localparam                  IMEM_SIZE       = 64*1024                           ;
    localparam                  IBUS_ADDR_WIDTH = XLEN                              ;
    localparam                  IBUS_DATA_WIDTH = ILEN                              ;

    localparam                  DMEM_SIZE       = 64*1024                           ;
    localparam                  DBUS_ADDR_WIDTH = XLEN                              ;
    localparam                  DBUS_DATA_WIDTH = XLEN                              ;
    localparam                  DBUS_STRB_WIDTH = DBUS_DATA_WIDTH/8                 ;

    // riscv
    localparam logic [ILEN-1:0] UNIMP           = 'hc0001073                        ;

    // privilege
    typedef enum logic [1:0] {
        PRIV_LVL_M  = 2'b11 ,
        PRIV_LVL_S  = 2'b01 ,
        PRIV_LVL_U  = 2'b00
    } priv_lvl_e;

    typedef enum logic [1:0] {
        XLEN_32     = 2'b01 ,
        XLEN_64     = 2'b10
    } xlen_e;

    // extention context status
    typedef enum logic [1:0] {
        XS_OFF      = 2'b00 ,
        XS_INITIAL  = 2'b01 ,
        XS_CLEAN    = 2'b10 ,
        XS_DIRTY    = 2'b11
    } xs_e;

    typedef struct packed {
        logic        sd         ;
        logic [19:0] wpri_62_43 ;
        logic        mdt        ; // m-mode-disable-trap
        logic        mpelp      ;
        logic        wpri_40    ;
        logic        mpv        ;
        logic        gva        ;
        logic        sbe        ;
        xlen_e       sxl        ;
        xlen_e       uxl        ;
        logic  [6:0] wpri_31_25 ;
        logic        sdt        ;
        logic        spelp      ;
        logic        tsr        ; // trap sret
        logic        tw         ; // timeout wait
        logic        tvm        ; // trap virtual memory
        logic        mxr        ; // meke executable readable
        logic        sum        ; // permit supervisor user memory access
        logic        mprv       ; // modify privilege
        xs_e         xs         ; // extention context status: the status of additional user-mode extentions and associate state
        xs_e         fs         ; // extention context status: the status of the floating-point unit state
        priv_lvl_e   mpp        ; // machine previous privilege mode
        xs_e         vs         ; // extention context status: the status of the vector extention state
        logic        spp        ; // supervisor privous privilege mode
        logic        mpie       ; // machine previous interrupt-enable
        logic        ube        ;
        logic        spie       ; // supervisor previous interrupt-enable
        logic        wpri_4     ;
        logic        mie        ; // machine global interrupt-enable
        logic        wpri_2     ;
        logic        sie        ; // supervisor global interrupt-enable
        logic        wpri_0     ;
    } mstatus_s;

    localparam logic [XLEN-1:0] MSTATUS_SXL         = 64'h0000000c_00000000 ;
    localparam logic [XLEN-1:0] MSTATUS_UXL         = 64'h00000003_00000000 ;
    localparam logic [XLEN-1:0] MSTATUS_MPP         = 64'h00000000_00001800 ;
    localparam logic [XLEN-1:0] MSTATUS_MPIE        = 64'h00000000_00000080 ;
    localparam logic [XLEN-1:0] MSTATUS_MIE         = 64'h00000000_00000008 ;

    localparam logic [XLEN-1:0] MSTATUS_READ_MASK   = MSTATUS_SXL | MSTATUS_UXL | MSTATUS_MPP | MSTATUS_MPIE | MSTATUS_MIE  ;
    localparam logic [XLEN-1:0] MSTATUS_WRITE_MASK  =                             MSTATUS_MPP | MSTATUS_MPIE | MSTATUS_MIE  ;

    localparam logic [XLEN-1:0] RESET_MSTATUS       = (XLEN == 64) ? {28'h0000000, XLEN_64, XLEN_64, 32'h00000000} : 'h00000000 ;

    // interrupt
    localparam                  IRQ_U_SOFT          = 0                     ;
    localparam                  IRQ_S_SOFT          = 1                     ;
    localparam                  IRQ_VS_SOFT         = 2                     ;
    localparam                  IRQ_M_SOFT          = 3                     ;
    localparam                  IRQ_U_TIMER         = 4                     ;
    localparam                  IRQ_S_TIMER         = 5                     ;
    localparam                  IRQ_VS_TIMER        = 6                     ;
    localparam                  IRQ_M_TIMER         = 7                     ;
    localparam                  IRQ_U_EXT           = 8                     ;
    localparam                  IRQ_S_EXT           = 9                     ;
    localparam                  IRQ_VS_EXT          = 10                    ;
    localparam                  IRQ_M_EXT           = 11                    ;
    localparam                  IRQ_S_GEXT          = 12                    ;
    localparam                  IRQ_COP             = 12                    ;
    localparam                  IRQ_LCOF            = 13                    ;

    localparam logic [XLEN-1:0] MIP_USIP            = 1 << IRQ_U_SOFT       ;
    localparam logic [XLEN-1:0] MIP_SSIP            = 1 << IRQ_S_SOFT       ;
    localparam logic [XLEN-1:0] MIP_VSSIP           = 1 << IRQ_VS_SOFT      ;
    localparam logic [XLEN-1:0] MIP_MSIP            = 1 << IRQ_M_SOFT       ;
    localparam logic [XLEN-1:0] MIP_UTIP            = 1 << IRQ_U_TIMER      ;
    localparam logic [XLEN-1:0] MIP_STIP            = 1 << IRQ_S_TIMER      ;
    localparam logic [XLEN-1:0] MIP_VSTIP           = 1 << IRQ_VS_TIMER     ;
    localparam logic [XLEN-1:0] MIP_MTIP            = 1 << IRQ_M_TIMER      ;
    localparam logic [XLEN-1:0] MIP_UEIP            = 1 << IRQ_U_EXT        ;
    localparam logic [XLEN-1:0] MIP_SEIP            = 1 << IRQ_S_EXT        ;
    localparam logic [XLEN-1:0] MIP_VSEIP           = 1 << IRQ_VS_EXT       ;
    localparam logic [XLEN-1:0] MIP_MEIP            = 1 << IRQ_M_EXT        ;
    localparam logic [XLEN-1:0] MIP_SGEIP           = 1 << IRQ_S_GEXT       ;
    localparam logic [XLEN-1:0] MIP_LCOFIP          = 1 << IRQ_LCOF         ;

    localparam logic [XLEN-1:0] MIP_S_MASK          = MIP_SSIP | MIP_STIP | MIP_SEIP;

    // exception cause
    localparam logic [XLEN-1:0] CAUSE_MISALIGNED_FETCH          = 0         ;
    localparam logic [XLEN-1:0] CAUSE_FETCH_ACCESS              = 1         ;
    localparam logic [XLEN-1:0] CAUSE_ILLEGAL_INSTRUCTION       = 2         ;
    localparam logic [XLEN-1:0] CAUSE_BREAKPOINT                = 3         ;
    localparam logic [XLEN-1:0] CAUSE_MISALIGNED_LOAD           = 4         ;
    localparam logic [XLEN-1:0] CAUSE_LOAD_ACCESS               = 5         ;
    localparam logic [XLEN-1:0] CAUSE_MISALIGNED_STORE          = 6         ;
    localparam logic [XLEN-1:0] CAUSE_STORE_ACCESS              = 7         ;
    localparam logic [XLEN-1:0] CAUSE_USER_ECALL                = 8         ;
    localparam logic [XLEN-1:0] CAUSE_SUPERVISOR_ECALL          = 9         ;
    localparam logic [XLEN-1:0] CAUSE_VIRTUAL_SUPERVISOR_ECALL  = 10        ;
    localparam logic [XLEN-1:0] CAUSE_MACHINE_ECALL             = 11        ;
    localparam logic [XLEN-1:0] CAUSE_FETCH_PAGE_FAULT          = 12        ;
    localparam logic [XLEN-1:0] CAUSE_LOAD_PAGE_FAULT           = 13        ;
    localparam logic [XLEN-1:0] CAUSE_STORE_PAGE_FAULT          = 15        ;
    localparam logic [XLEN-1:0] CAUSE_FETCH_GUEST_PAGE_FAULT    = 20        ;
    localparam logic [XLEN-1:0] CAUSE_LOAD_GUEST_PAGE_FAULT     = 21        ;
    localparam logic [XLEN-1:0] CAUSE_VIRTUAL_INSTRUCTION       = 22        ;
    localparam logic [XLEN-1:0] CAUSE_STORE_GUEST_PAGE_FAULT    = 23        ;

    typedef struct packed {
        logic            valid  ;
        logic [XLEN-1:0] cause  ;
        logic [XLEN-1:0] tval   ;
    } exc_s;

    // unprivilege
    typedef struct packed {
        logic itype         ;
        logic stype         ;
        logic btype         ;
        logic utype         ;
        logic jtype         ;
    } insn_type_s;

    typedef struct packed {
        logic use_uimm      ;
        logic use_pc        ;
    } src1_ctrl_s;

    typedef struct packed {
        logic use_imm       ;
    } src2_ctrl_s;

    typedef struct packed {
        logic is_ecall      ;
        logic is_ebreak     ;
        logic is_mret       ;
    } sys_ctrl_s;

    typedef struct packed {
        logic is_signed     ;
        logic is_beq        ;
        logic is_bne        ;
        logic is_blt        ;
        logic is_bge        ;
        logic is_jal_jalr   ;
        logic is_jalr       ;
    } bru_ctrl_s;

    typedef struct packed {
        logic is_signed     ;
        logic is_neg        ;
        logic is_add        ;
        logic is_less       ;
        logic is_xor        ;
        logic is_and        ;
        logic is_sl         ; // shift left
        logic is_sr         ; // shift right
        logic is_word       ;
    } alu_ctrl_s;

    typedef struct packed {
        logic is_csr        ;
        logic is_read       ;
        logic is_write      ;
        logic is_set        ;
        logic is_clear      ;
    } csr_ctrl_s;

    typedef struct packed {
        logic is_mul        ;
        logic is_src1_signed;
        logic is_src2_signed;
        logic is_high       ;
        logic is_word       ;
    } mul_ctrl_s;

    typedef struct packed {
        logic is_signed     ;
        logic is_load       ;
        logic is_store      ;
        logic is_byte       ;
        logic is_half       ;
        logic is_word       ;
        logic is_dword      ;
    } lsu_ctrl_s;

    function automatic void spike_commit_log (
        int                fd           ,
        logic   [XLEN-1:0] hartid       ,
        priv_lvl_e         priv_lvl     ,
        logic   [XLEN-1:0] pc           ,
        logic   [ILEN-1:0] ir           ,
        logic              rf_we        ,
        logic        [4:0] rd           ,
        logic   [XLEN-1:0] rf_wdata     ,
        logic   [XLEN-1:0] mem_addr     ,
        logic              mem_re       ,
        logic              mem_we       ,
        logic   [XLEN-1:0] mem_wdata    ,
        logic [XBYTES-1:0] mem_wstrb    ,
        logic              csr_we       ,
        logic       [11:0] csr_waddr    ,
        logic   [XLEN-1:0] csr_wdata
    );

        string rd_s ;

        $fwrite(fd, "core   %1d: %1d 0x%016x (0x%08x)", hartid, priv_lvl, pc, ir);

        if (rd < 10) rd_s   = $sformatf("%1d " , rd);
        else         rd_s   = $sformatf("%2d"  , rd);
        if (rf_we) $fwrite(fd, " x%s 0x%016x", rd_s, rf_wdata);

        if (mem_re) $fwrite(fd, " mem 0x%016x", mem_addr);

        if (mem_we) begin
            $fwrite(fd, " mem 0x%016x 0x", mem_addr);
            for (int i = XBYTES - 1; i >= 0; i--) begin
                if (mem_wstrb[i]) $fwrite(fd, "%02x", mem_wdata[8*i+:8]);
            end
        end

        if (csr_we) begin
            case (csr_waddr)
                12'hf14 : $fwrite(fd, " c%3d_mhartid 0x%016x"   , csr_waddr, csr_wdata);
                12'h300 : $fwrite(fd, " c%3d_mstatus 0x%016x"   , csr_waddr, csr_wdata);
                12'h304 : $fwrite(fd, " c%3d_mie 0x%016x"       , csr_waddr, csr_wdata);
                12'h305 : $fwrite(fd, " c%3d_mtvec 0x%016x"     , csr_waddr, csr_wdata);
                12'h341 : $fwrite(fd, " c%3d_mepc 0x%016x"      , csr_waddr, csr_wdata);
                12'h342 : $fwrite(fd, " c%3d_mcause 0x%016x"    , csr_waddr, csr_wdata);
                12'h343 : $fwrite(fd, " c%3d_mtval 0x%016x"     , csr_waddr, csr_wdata);
                default : `WARNING($sformatf("undefined csr: %3x", csr_waddr));
            endcase
        end

        $fdisplay(fd);

    endfunction

endpackage

`endif // REI_PKG_SV
