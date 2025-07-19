`ifndef DBUS_IF_SV
`define DBUS_IF_SV

interface dbus_if #(
    parameter  ADDR_WIDTH   = 0             ,
    parameter  DATA_WIDTH   = 0             ,
    localparam STRB_WIDTH   = DATA_WIDTH/8
) (
    input  logic clk_i
);

    // write request channel
    logic [ADDR_WIDTH-1:0] awaddr   ;

    // write data channel
    logic                  wvalid   ;
    logic [DATA_WIDTH-1:0] wdata    ;
    logic [STRB_WIDTH-1:0] wstrb    ;

    // write response channel

    // read request channel
    logic                  arvalid  ;
    logic [ADDR_WIDTH-1:0] araddr   ;

    // read data channel
    logic [DATA_WIDTH-1:0] rdata    ;

    // debug
    logic [ADDR_WIDTH-1:0] addr     ;

    // manager clocking block
    clocking mcb @(posedge clk_i);
        output awaddr   ;
        output wvalid   ;
        output wdata    ;
        output wstrb    ;
        output arvalid  ;
        output araddr   ;
        input  rdata    ;
        output addr     ; // debug
    endclocking

    // subordinate clocking block
    clocking scb @(posedge clk_i);
        input  awaddr   ;
        input  wvalid   ;
        input  wdata    ;
        input  wstrb    ;
        input  arvalid  ;
        input  araddr   ;
        output rdata    ;
        input  addr     ; // debug
    endclocking

    // manager
    modport mgr (
        output awaddr   ,
        output wvalid   ,
        output wdata    ,
        output wstrb    ,
        output arvalid  ,
        output araddr   ,
        input  rdata    ,
        output addr
    );

    // subordinate
    modport sub (
        input  awaddr   ,
        input  wvalid   ,
        input  wdata    ,
        input  wstrb    ,
        input  arvalid  ,
        input  araddr   ,
        output rdata    ,
        input  addr
    );

endinterface

`endif // DBUS_IF_SV
