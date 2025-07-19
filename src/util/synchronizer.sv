`resetall
`default_nettype none

module synchronizer (
    input  var logic clk_i  ,
    input  var logic d_i    ,
    output var logic q_o
);

    logic ff_q1, ff_q2      ;

    always_ff @(posedge clk_i) begin
        ff_q1   <= d_i      ;
        ff_q2   <= ff_q1    ;
    end

    assign q_o  = ff_q2     ;

endmodule

`default_nettype wire
`resetall
