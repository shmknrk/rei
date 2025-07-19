`resetall
`default_nettype none

module regfile
    import rei_pkg::*;
(
    input  var logic            clk_i   ,
    input  var logic      [4:0] rs1_i   ,
    input  var logic      [4:0] rs2_i   ,
    output var logic [XLEN-1:0] xrs1_o  ,
    output var logic [XLEN-1:0] xrs2_o  ,
    input  var logic            we_i    ,
    input  var logic      [4:0] rd_i    ,
    input  var logic [XLEN-1:0] wdata_i
);

    logic [31:0][XLEN-1:0] ram;

    assign xrs1_o   = (~|rs1_i) ? 'h0 : ram[rs1_i]  ;
    assign xrs2_o   = (~|rs2_i) ? 'h0 : ram[rs2_i]  ;
    always_ff @(posedge clk_i) if (we_i) ram[rd_i]  <= wdata_i  ;

endmodule

`default_nettype wire
`resetall
