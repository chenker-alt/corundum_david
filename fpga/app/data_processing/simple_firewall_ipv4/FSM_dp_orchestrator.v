module FSM_dp_orchestrator #(
    parameter DATA_WIDTH = 64,

    parameter COUNT_META_DATA_MAX=1,
    parameter COUNTER_WIDTH=1,

    parameter IDLE                  = 0,
    parameter PARSE_DATA            = 1,
    parameter CONTROL               = 2,
    parameter SEND_ANALYSED_DATA    = 3,
    parameter SEND_REMAIN           = 4,
    parameter DROP                  = 5
)
(
    input wire clk,
    input wire rst,

    input wire s_axis_dp_top_tlast,
    input wire s_axis_dp_top_tvalid,
    output reg s_axis_dp_top_tready,

    output reg m_axis_dp_top_tlast,
    output reg m_axis_dp_top_tvalid,
    input wire m_axis_dp_top_tready,

    input wire drop,

    output wire [2:0] out_state,
    output wire [COUNTER_WIDTH-1:0] out_count

);
    reg [2:0]state,next_state = 0;
    reg [COUNTER_WIDTH-1:0]count,next_count=0;

    reg [7:0]early_tlast,next_early_tlast;
    reg valid_early_tlast,next_valid_early_tlast;

    assign out_state=state;
    assign out_count=count;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
            count<=next_count;
            early_tlast <= next_early_tlast;
            valid_early_tlast <= next_valid_early_tlast;
        end
    end

always @(*) begin
    s_axis_dp_top_tready = 1'b0;
    m_axis_dp_top_tlast = 1'b0;
    m_axis_dp_top_tvalid = 1'b0;
    next_state = IDLE;
    next_count = 0;
    next_early_tlast = 0;
    next_valid_early_tlast = 1'b0;

    case (state)
        IDLE: begin
            if (s_axis_dp_top_tvalid) begin
                next_state = PARSE_DATA;
            end
        end

        PARSE_DATA: begin
            if (s_axis_dp_top_tvalid) begin
                s_axis_dp_top_tready = 1'b1;
                if (s_axis_dp_top_tlast) begin
                    next_early_tlast = count;
                    next_valid_early_tlast = 1'b1;
                    next_state = CONTROL;
                end else if (count == COUNT_META_DATA_MAX - 1) begin
                    next_state = CONTROL;
                end else begin
                    next_state = PARSE_DATA;
                    next_count = count + 1;
                end
            end else begin
                next_count = count;
            end
        end

        CONTROL: begin
            if (drop) begin
                next_state = DROP;
            end else begin
                next_state = SEND_ANALYSED_DATA;
            end
            next_early_tlast = early_tlast;
            next_valid_early_tlast = valid_early_tlast;
        end

        SEND_ANALYSED_DATA: begin
            m_axis_dp_top_tvalid = 1'b1;
            if (m_axis_dp_top_tready) begin
                if (count == COUNT_META_DATA_MAX - 1) begin
                    next_state = SEND_REMAIN;
                end else if (count == early_tlast && valid_early_tlast == 1) begin
                    m_axis_dp_top_tlast = 1'b1;
                    next_state = IDLE;
                end else begin
                    next_count = count + 1;
                    next_state = SEND_ANALYSED_DATA;
                end
            end else begin
                next_count = count;
            end
            next_valid_early_tlast = valid_early_tlast;
            next_early_tlast = early_tlast;
        end

        SEND_REMAIN: begin
            if (m_axis_dp_top_tready && s_axis_dp_top_tvalid) begin
                s_axis_dp_top_tready = 1'b1;
                m_axis_dp_top_tvalid = 1'b1;
                if (s_axis_dp_top_tlast) begin
                    m_axis_dp_top_tlast = 1'b1;
                    next_state = IDLE;
                end else begin
                    next_state = SEND_REMAIN;
                end
            end
        end

        DROP: begin
            s_axis_dp_top_tready = 1'b1;
            if (s_axis_dp_top_tlast) begin
                next_state = IDLE;
                m_axis_dp_top_tlast = 1'b1;
            end else begin
                next_state = DROP;
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end
endmodule



