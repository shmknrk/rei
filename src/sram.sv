`resetall
`default_nettype none

`include "log.svh"

module sram #(
    parameter  SRAM_SIZE    = 0             ,
    parameter  ADDR_WIDTH   = 0             ,
    parameter  DATA_WIDTH   = 0             ,
    localparam STRB_WIDTH   = DATA_WIDTH/8
) (
    input  var logic                  clk_i     ,
    input  var logic                  wvalid_i  ,
    input  var logic [ADDR_WIDTH-1:0] awaddr_i  ,
    input  var logic [DATA_WIDTH-1:0] wdata_i   ,
    input  var logic [STRB_WIDTH-1:0] wstrb_i   ,
    input  var logic [ADDR_WIDTH-1:0] araddr_i  ,
    output var logic [DATA_WIDTH-1:0] rdata_o
);

    // DRC: design rule check
    initial begin
        if (SRAM_SIZE ==0) `FATAL("specify a SRAM_SIZE" );
        if (ADDR_WIDTH==0) `FATAL("specify a ADDR_WIDTH");
        if (DATA_WIDTH==0) `FATAL("specify a DATA_WIDTH");
    end

    localparam OFFSET_WIDTH     = $clog2(DATA_WIDTH/8)          ;
    localparam VALID_ADDR_WIDTH = $clog2(SRAM_SIZE)-OFFSET_WIDTH;
    (* ram_style = "block" *) logic [DATA_WIDTH-1:0] ram[2**VALID_ADDR_WIDTH-1] ;

    logic [VALID_ADDR_WIDTH-1:0] valid_awaddr, valid_araddr;
    assign valid_awaddr = awaddr_i[VALID_ADDR_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];
    assign valid_araddr = araddr_i[VALID_ADDR_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];

    always_ff @(posedge clk_i) begin
        rdata_o <= ram[valid_araddr];
        if (wvalid_i) begin
            for (int i=0; i<STRB_WIDTH; i=i+1) begin
                if (wstrb_i[i]) ram[valid_awaddr][8*i+:8] <= wdata_i[8*i+:8];
            end
        end
    end

endmodule

`default_nettype wire
`resetall
