`ifndef IBUS_IF_SV
`define IBUS_IF_SV

interface ibus_if #(
    parameter  ADDR_WIDTH   = 0             ,
    parameter  DATA_WIDTH   = 0
) (
    input  logic clk_i
);

    // write request channel

    // write data channel

    // write response channel

    // read request channel
    logic [ADDR_WIDTH-1:0] araddr   ;

    // read data channel
    logic [DATA_WIDTH-1:0] rdata    ;

    // manager clocking block
    clocking mcb @(posedge clk_i);
        output araddr   ;
        input  rdata    ;
    endclocking

    // subordinate clocking block
    clocking scb @(posedge clk_i);
        input  araddr   ;
        output rdata    ;
    endclocking

    // manager
    modport mgr (
        output araddr   ,
        input  rdata
    );

    // subordinate
    modport sub (
        input  araddr   ,
        output rdata
    );

endinterface

`endif // IBUS_IF_SV
