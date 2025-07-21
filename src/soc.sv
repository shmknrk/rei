`resetall
`default_nettype none

module soc
    import rei_pkg::*;
(
    input  var logic clk_i  ,
    input  var logic rst_ni
);

    logic rst;
    synchronizer sync_rst (
        .clk_i          (clk_i                  ), // input  var logic
        .d_i            (!rst_ni                ), // input  var logic
        .q_o            (rst                    )  // output var logic
    );

    ibus_if #(IBUS_ADDR_WIDTH, IBUS_DATA_WIDTH) ibus_if(clk_i);
    dbus_if #(DBUS_ADDR_WIDTH, DBUS_DATA_WIDTH) dbus_if(clk_i);

    rei #(
        .Hartid         (0                      )
    ) rei (
        .clk_i          (clk_i                  ), // input  var logic
        .rst_i          (rst                    ), // input  var logic
        .ibus_if        (ibus_if                ), // ibus_if.mgr
        .dbus_if        (dbus_if                )  // dbus_if.mgr
    );

    sram #(
        .SRAM_SIZE      (IMEM_SIZE              ),
        .ADDR_WIDTH     (IBUS_ADDR_WIDTH        ),
        .DATA_WIDTH     (IBUS_DATA_WIDTH        )
    ) imem (
        .clk_i          (clk_i                  ), // input  var logic
        .wvalid_i       ('h0                    ), // input  var logic
        .awaddr_i       ('h0                    ), // input  var logic [ADDR_WIDTH-1:0]
        .wdata_i        ('h0                    ), // input  var logic [DATA_WIDTH-1:0]
        .wstrb_i        ('h0                    ), // input  var logic [STRB_WIDTH-1:0]
        .araddr_i       (ibus_if.araddr         ), // input  var logic [ADDR_WIDTH-1:0]
        .rdata_o        (ibus_if.rdata          )  // output var logic [DATA_WIDTH-1:0]
    );

    sram #(
        .SRAM_SIZE      (DMEM_SIZE              ),
        .ADDR_WIDTH     (DBUS_ADDR_WIDTH        ),
        .DATA_WIDTH     (DBUS_DATA_WIDTH        )
    ) dmem (
        .clk_i          (clk_i                  ), // input  var logic
        .wvalid_i       (dbus_if.wvalid         ), // input  var logic
        .awaddr_i       (dbus_if.awaddr         ), // input  var logic [ADDR_WIDTH-1:0]
        .wdata_i        (dbus_if.wdata          ), // input  var logic [DATA_WIDTH-1:0]
        .wstrb_i        (dbus_if.wstrb          ), // input  var logic [STRB_WIDTH-1:0]
        .araddr_i       (dbus_if.araddr         ), // input  var logic [ADDR_WIDTH-1:0]
        .rdata_o        (dbus_if.rdata          )  // output var logic [DATA_WIDTH-1:0]
    );

endmodule

`default_nettype wire
`resetall
