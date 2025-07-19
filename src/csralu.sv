`resetall
`default_nettype none

module csralu
    import rei_pkg::*;
(
    input  csr_ctrl_s           csr_ctrl_i  ,
    input  var logic [XLEN-1:0] csr_i       ,
    input  var logic [XLEN-1:0] src1_i      ,
    output var logic [XLEN-1:0] rslt_o
);

    logic [XLEN-1:0] write_rslt ;
    logic [XLEN-1:0] set_rslt   ;
    logic [XLEN-1:0] clear_rslt ;
    assign write_rslt   = (csr_ctrl_i.is_write) ?          src1_i : 'h0 ;
    assign set_rslt     = (csr_ctrl_i.is_set  ) ? csr_i |  src1_i : 'h0 ;
    assign clear_rslt   = (csr_ctrl_i.is_clear) ? csr_i & ~src1_i : 'h0 ;

    assign rslt_o       = write_rslt | set_rslt | clear_rslt            ;

endmodule

`default_nettype wire
`resetall
