module FIFO_sched#(
    parameter IF_COUNT_DOWN_RX = 3
)
(
    input clk,

    input wire [IF_COUNT_DOWN_RX-1:0] s_axis_tvalid,
    input wire m_axis_mult_tlast,

    output reg [1:0] sel,
    output reg en=1
);
reg [1:0] next_sel=0;
reg iddle=1;
reg next_iddle=1;
always @(posedge clk) begin
    sel<=next_sel;
    iddle<=next_iddle;
end

always @(*)begin
    if (m_axis_mult_tlast==1) begin  
        next_iddle=1'b1;
    end
    if (iddle) begin
            if ( s_axis_tvalid[0]==1)begin
                next_iddle=1'b0;
                next_sel<=0;
            end
            else if (s_axis_tvalid[1]==1) begin
                next_iddle=1'b0;
                next_sel<=1;
            end
            else if (s_axis_tvalid[2]==1) begin
                next_iddle=1'b0;
                next_sel<=2;
            end
            else begin
                next_iddle=1'b1;
                next_sel<=0;
            end
    end
    else begin
    next_sel<=next_sel;
    next_iddle<=next_iddle;
    end
end

endmodule