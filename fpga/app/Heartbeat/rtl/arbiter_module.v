module arbiter_module(
    input wire clk,
    input wire rst,

    input wire s_axis_arbiter_tlast,

    input wire handshake_heartbeat1,
    input wire handshake_heartbeat2,
    input wire handshake_heartbeat3,
    input wire handshake_SFP,

    output reg grant_SFP=1,
    output reg grant_heartbeat1=0,
    output reg grant_heartbeat2=0,
    output reg grant_heartbeat3=0
);
    localparam  IDLE=0,
                SFP=1,
                heartbeat1=2,
                heartbeat2=3,
                heartbeat3=4;

    reg [3:0]current_speaker, next_speaker=0;

    always @(posedge clk) begin
        if (rst) begin
            current_speaker <= IDLE;
        end else begin
            current_speaker <= next_speaker;
        end
    end

    always @(*) begin
        case (current_speaker)
            IDLE: begin
                grant_SFP=1'b0;
                grant_heartbeat1=1'b0;
                grant_heartbeat2=1'b0;
                grant_heartbeat3=1'b0;

                if (handshake_heartbeat1) begin
                    next_speaker = heartbeat1;
                end else if (handshake_heartbeat2) begin
                    next_speaker = heartbeat2;
                end else if (handshake_heartbeat3) begin
                    next_speaker = heartbeat3;
                end else if (handshake_SFP) begin
                    next_speaker = SFP;
                end else begin
                    next_speaker = IDLE;
                end
            end

            SFP: begin
                grant_SFP = 1'b1;
                grant_heartbeat1 = 1'b0;
                grant_heartbeat2 = 1'b0;
                grant_heartbeat3 = 1'b0;
                next_speaker = s_axis_arbiter_tlast ? IDLE : SFP;
            end
            heartbeat1: begin
                grant_heartbeat1 = 1'b1;
                grant_SFP = 1'b0;
                grant_heartbeat2 = 1'b0;
                grant_heartbeat3 = 1'b0;
                next_speaker = s_axis_arbiter_tlast ? IDLE : heartbeat1;
            end
            heartbeat2: begin
                grant_heartbeat2 = 1'b1;
                grant_SFP = 1'b0;
                grant_heartbeat1 = 1'b0;
                grant_heartbeat3 = 1'b0;
                next_speaker = s_axis_arbiter_tlast ? IDLE : heartbeat2;
            end
            heartbeat3: begin
                grant_heartbeat3 = 1'b1;
                grant_SFP = 1'b0;
                grant_heartbeat1 = 1'b0;
                grant_heartbeat2 = 1'b0;
                next_speaker = s_axis_arbiter_tlast ? IDLE : heartbeat3;
            end
            default: begin
                grant_SFP = 1'b0;
                grant_heartbeat1 = 1'b0;
                grant_heartbeat2 = 1'b0;
                grant_heartbeat3 = 1'b0;
                next_speaker = IDLE;
            end
        endcase
    end

endmodule