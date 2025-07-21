`resetall
`default_nettype none

`include "log.svh"

module top;
    import rei_pkg::*;

    // clock
    bit clk; always #5 clk <= ~clk;
    default clocking cb @(posedge clk); endclocking

    // reset
    bit rst_n; initial #10 rst_n = 1'b1;

    // cycle
    longint unsigned cycle, max_cycles;
    initial if ($value$plusargs("max_cycles=%d", max_cycles));

    always_ff @(cb) begin
        cycle <= cycle + 'h1;
        if (cycle >= max_cycles) begin
            `INFO($sformatf("simulation timeout: cycle=[%-d]", cycle));
            $finish;
        end
    end

    // dut
    soc soc (
        .clk_i      (clk            ), // input var logic
        .rst_ni     (rst_n          )  // input var logic
    );

    initial $readmemh(get_filename_from_args("imem_file"), soc.imem.ram);
    initial $readmemh(get_filename_from_args("dmem_file"), soc.dmem.ram);

    string trace_fst_file;
    initial begin
        if ($value$plusargs("trace_fst_file=%s", trace_fst_file)) begin
            $dumpfile(trace_fst_file);
            $dumpvars(0);
        end
    end

    string commit_log_file;
    int    commit_log_fd  ;
    initial begin
        if ($value$plusargs("commit_log_file=%s", commit_log_file)) begin
            commit_log_fd = $fopen(commit_log_file, "w");
            if (commit_log_fd == 0) `FATAL($sformatf("failed to open commit_log_file: %s", commit_log_file));
        end
    end
    final if (|commit_log_fd) $fclose(commit_log_fd);

    always_ff @(cb) begin
        if (soc.rei.Cm_valid) begin
            spike_commit_log (
                .fd         (commit_log_fd          ), // int
                .hartid     (soc.rei.Hartid         ), // logic   [XLEN-1:0]
                .priv_lvl   (soc.rei.priv_lvl       ), // priv_lvl_e
                .pc         (soc.rei.ExCm_pc        ), // logic   [XLEN-1:0]
                .ir         (soc.rei.ExCm_ir        ), // logic   [ILEN-1:0]
                .rf_we      (soc.rei.Cm_rf_we       ), // logic
                .rd         (soc.rei.ExCm_rd        ), // logic        [4:0]
                .rf_wdata   (soc.rei.Cm_rslt        ), // logic   [XLEN-1:0]
                .mem_addr   (soc.rei.ExCm_addr      ), // logic   [XLEN-1:0]
                .mem_re     (soc.rei.ExCm_arvalid   ), // logic
                .mem_we     (soc.rei.ExCm_wvalid    ), // logic
                .mem_wdata  (soc.rei.ExCm_wdata     ), // logic   [XLEN-1:0]
                .mem_wstrb  (soc.rei.ExCm_wstrb     ), // logic [XBYTES-1:0]
                .csr_we     (soc.rei.ExCm_csr_we    ), // logic
                .csr_waddr  (soc.rei.ExCm_csr_addr  ), // logic       [11:0]
                .csr_wdata  (soc.rei.ExCm_csr_rslt  )  // logic   [XLEN-1:0]
            );
        end
    end

    // end of simulation
    always_ff @(cb) begin
        if (soc.rei.ExCm_valid && (soc.rei.ExCm_ir == UNIMP)) begin
            `INFO($sformatf("unimp instruction detected: pc=[%016x]", soc.rei.ExCm_pc));
            `INFO($sformatf("end of simulation reached : cycle=[%-d]", cycle));
            $finish;
        end
    end

endmodule

function automatic string get_filename_from_args(string args);

    string filename;

    if ($value$plusargs($sformatf("%s=%%s", args), filename)) begin
        int fd = $fopen(filename, "r");
        if (fd == 0) `FATAL($sformatf("+%s=%s not found", args, filename));
        $fclose(fd);
    end else begin
        `FATAL($sformatf("usage: obj_dir/<topname> +%s=<filename>", args));
    end

    return filename;

endfunction

`default_nettype wire
`resetall
