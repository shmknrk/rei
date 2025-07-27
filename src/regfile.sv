`resetall
`default_nettype none

module regfile
    import rei_pkg::*;
(
    input  var logic            clk_i       ,
    input  var logic            rst_i       ,
    input  var logic            stall_i     ,
    input  var logic      [4:0] rd_i        ,
    input  var logic      [4:0] rs1_i       ,
    input  var logic      [4:0] rs2_i       ,
    output var logic            rd_ready_o  ,
    output var logic            rs1_ready_o ,
    output var logic            rs2_ready_o ,
    output var logic [XLEN-1:0] xrs1_o      ,
    output var logic [XLEN-1:0] xrs2_o      ,
    input  var logic            we_i        ,
    input  var logic      [4:0] waddr_i     ,
    input  var logic [XLEN-1:0] wdata_i
);

    logic           [31:0] ready_q  , ready_d   ;
    logic [31:0][XLEN-1:0] ram                  ;

    assign rd_ready_o   = ~|rd_i  || (we_i && (waddr_i == rd_i )) || ready_q[rd_i]  ;
    assign rs1_ready_o  = ~|rs1_i || (we_i && (waddr_i == rs1_i)) || ready_q[rs1_i] ;
    assign rs2_ready_o  = ~|rs2_i || (we_i && (waddr_i == rs2_i)) || ready_q[rs2_i] ;

    assign xrs1_o       = (~|rs1_i) ?  'h0 : (we_i && (waddr_i == rs1_i)) ? wdata_i : ram[rs1_i];
    assign xrs2_o       = (~|rs2_i) ?  'h0 : (we_i && (waddr_i == rs2_i)) ? wdata_i : ram[rs2_i];

    always_comb begin
        ready_d         = ready_q   ;
        if (we_i) begin
            ready_d[waddr_i]    = 1'b1  ;
        end
        if (rd_ready_o && rs1_ready_o && rs2_ready_o) begin
            ready_d[rd_i]       = 1'b0  ;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ready_q <= {32{1'b1}}   ;
        end else if (!stall_i) begin
            ready_q <= ready_d      ;
        end
    end

    always_ff @(posedge clk_i) begin
        if (!stall_i) begin
            if (we_i) begin
                ram[waddr_i]    <= wdata_i  ;
            end
        end
    end

endmodule

`default_nettype wire
`resetall
