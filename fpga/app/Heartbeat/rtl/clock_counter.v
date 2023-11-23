module clock_counter#(  
    parameter COUNTER_WIDTH = 32,
    parameter COUNTER_MAX = (5 * 250_000_000) / 1000
)
(
    input wire clk,
    input wire rst,

    input wire grant,

    output reg handshake=0
);
    localparam  COUNT = 1'b0,
                IDLE_GRANT = 1'b1;
    
    reg state, next_state=0;
    reg [COUNTER_WIDTH-1:0] counter, next_counter=0;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE_GRANT;
            counter <= 0;
        end
        else begin
            state <= next_state;
            counter <= next_counter;
        end
    end

    always @(*) begin
        case (state)
            COUNT: begin
            handshake =1'b0;
                if (counter == COUNTER_MAX-1) begin
                    next_state = IDLE_GRANT;
                    next_counter = 0;
                end
                else begin
                    next_state = COUNT;
                    next_counter = counter + 1;
                end
            end

            IDLE_GRANT: begin
                next_counter = 0;
                handshake =1'b1;
                if (grant) begin
                    next_state = COUNT;
                end
                else begin
                    next_state = IDLE_GRANT;
                end
            end

            default: begin
                handshake =1'b0;
                next_state = COUNT;
                next_counter = 0;
            end
        endcase
    end
endmodule
