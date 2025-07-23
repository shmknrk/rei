`resetall
`default_nettype none

module lsu
    import rei_pkg::*;
(
    input  var logic            clk_i       ,
    input  var logic            valid_i     ,
    input  var logic            stall_i     ,
    input  lsu_ctrl_s           lsu_ctrl_i  ,
    input  var logic [XLEN-1:0] src1_i      ,
    input  var logic [XLEN-1:0] src2_i      ,
    input  var logic [XLEN-1:0] imm_i       ,
    dbus_if.mgr                 dbus_if     ,
    output var logic [XLEN-1:0] rslt_o
);

    assign dbus_if.wvalid   = valid_i && lsu_ctrl_i.is_store;
    assign dbus_if.arvalid  = valid_i && lsu_ctrl_i.is_load ;

    // addr
    logic [XLEN-1:0] addr   ;
    assign addr             = src1_i + imm_i;
    assign dbus_if.addr     = addr          ;
    assign dbus_if.awaddr   = addr          ;
    assign dbus_if.araddr   = addr          ;

    localparam OFFSET_WIDTH = $clog2(XBYTES);
    logic [OFFSET_WIDTH-1:0] dbus_offset_q, dbus_offset_d   ;
    assign dbus_offset_d    = addr[OFFSET_WIDTH-1:0];

    // wdata
    logic [XLEN-1:0] sb_wdata   ;
    logic [XLEN-1:0] sh_wdata   ;
    logic [XLEN-1:0] sw_wdata   ;
    logic [XLEN-1:0] sd_wdata   ;
    assign sb_wdata         = (lsu_ctrl_i.is_byte ) ? {XLEN/ 8{src2_i[ 7:0]}} : 'h0 ;
    assign sh_wdata         = (lsu_ctrl_i.is_half ) ? {XLEN/16{src2_i[15:0]}} : 'h0 ;
    assign sw_wdata         = (lsu_ctrl_i.is_word ) ? {XLEN/32{src2_i[31:0]}} : 'h0 ;
    assign sd_wdata         = (lsu_ctrl_i.is_dword) ? {XLEN/64{src2_i[63:0]}} : 'h0 ;
    assign dbus_if.wdata    = sb_wdata | sh_wdata | sw_wdata | sd_wdata             ;

    // wstrb
    logic [XBYTES-1:0] sb_wstrb ;
    logic [XBYTES-1:0] sh_wstrb ;
    logic [XBYTES-1:0] sw_wstrb ;
    logic [XBYTES-1:0] sd_wstrb ;
    assign sb_wstrb         = (lsu_ctrl_i.is_byte ) ? 'b00000001 <<  dbus_offset_d                           : 'h0  ;
    assign sh_wstrb         = (lsu_ctrl_i.is_half ) ? 'b00000011 << {dbus_offset_d[OFFSET_WIDTH-1:1], 1'b0 } : 'h0  ;
    assign sw_wstrb         = (lsu_ctrl_i.is_word ) ? 'b00001111 << {dbus_offset_d[OFFSET_WIDTH-1:2], 2'b00} : 'h0  ;
    assign sd_wstrb         = (lsu_ctrl_i.is_dword) ? 'b11111111                                             : 'h0  ;
    assign dbus_if.wstrb    = sb_wstrb | sh_wstrb | sw_wstrb | sd_wstrb                                             ;

    lsu_ctrl_s lsu_ctrl_q;
    always_ff @(posedge clk_i) begin
        if (!stall_i) begin
            dbus_offset_q   <= dbus_offset_d;
            lsu_ctrl_q      <= lsu_ctrl_i   ;
        end
    end

    logic     [63:0] ld_rdata   ;
    logic     [31:0] lw_rdata   ;
    logic     [15:0] lh_rdata   ;
    logic      [7:0] lb_rdata   ;
    assign ld_rdata =                                         dbus_if.rdata ;
    assign lw_rdata = (dbus_offset_q[2]) ? ld_rdata[63:32] : ld_rdata[31:0] ;
    assign lh_rdata = (dbus_offset_q[1]) ? lw_rdata[31:16] : lw_rdata[15:0] ;
    assign lb_rdata = (dbus_offset_q[0]) ? lh_rdata[15: 8] : lh_rdata[ 7:0] ;

    logic [XLEN-1:0] lb_rslt    ;
    logic [XLEN-1:0] lh_rslt    ;
    logic [XLEN-1:0] lw_rslt    ;
    logic [XLEN-1:0] ld_rslt    ;
    assign lb_rslt  = (lsu_ctrl_q.is_byte ) ? {{XLEN- 8{lsu_ctrl_q.is_signed && lb_rdata[ 7]}}, lb_rdata} : 'h0 ;
    assign lh_rslt  = (lsu_ctrl_q.is_half ) ? {{XLEN-16{lsu_ctrl_q.is_signed && lh_rdata[15]}}, lh_rdata} : 'h0 ;
    assign lw_rslt  = (lsu_ctrl_q.is_word ) ? {{XLEN-32{lsu_ctrl_q.is_signed && lw_rdata[31]}}, lw_rdata} : 'h0 ;
    assign ld_rslt  = (lsu_ctrl_q.is_dword) ?                                                   ld_rdata  : 'h0 ;

    logic [XLEN-1:0] load_rslt  ;
    assign load_rslt    = (lsu_ctrl_q.is_load) ? lb_rslt | lh_rslt | lw_rslt | ld_rslt : 'h0;

    assign rslt_o       = load_rslt                                                         ;

endmodule

`default_nettype wire
`resetall
