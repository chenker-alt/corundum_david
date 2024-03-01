module FSM_packet_dispatcher #(
    // Ethernet interface configuration
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 9,
    
    // Parser/Mat/deparser configuration
    parameter COUNT_META_DATA_MAX=5,
    parameter COUNTER_WIDTH= $clog2(COUNT_META_DATA_MAX+1),

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // State
    parameter STATE_WIDTH           = 3,

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

    input wire enable_dp,
    input wire rst_drop_counter,

    output reg [32-1:0] reg_drop_counter,

    input wire [AXIS_KEEP_WIDTH-1:0] s_axis_FSM_tkeep,
    input wire s_axis_FSM_tlast,
    input wire s_axis_FSM_tvalid,
    output reg s_axis_FSM_tready,

    output reg [AXIS_KEEP_WIDTH-1:0] m_axis_FSM_tkeep,
    output reg m_axis_FSM_tlast,
    output reg m_axis_FSM_tvalid,
    input wire m_axis_FSM_tready,

    input wire drop,

    output reg [STATE_WIDTH-1:0] state,
    output reg [COUNTER_WIDTH-1:0] count
);
    reg [STATE_WIDTH-1:0] next_state;
    reg [COUNTER_WIDTH-1:0]next_count;
    reg [31:0] next_reg_drop_counter;

    reg [COUNTER_WIDTH-1:0] early_tlast, next_early_tlast;
    reg valid_early_tlast,next_valid_early_tlast;
    reg [AXIS_KEEP_WIDTH-1:0] tkeep_reg;
                
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
            count<= next_count;
            early_tlast <= next_early_tlast;
            valid_early_tlast <= next_valid_early_tlast;
            if (rst_drop_counter)begin
                reg_drop_counter <= 0;
            end else begin
                reg_drop_counter <= next_reg_drop_counter;
            end
        end
    end

    always @(*) begin
        s_axis_FSM_tready= 1'b0;
        m_axis_FSM_tlast = 1'b0;
        m_axis_FSM_tvalid = 1'b0;
        m_axis_FSM_tkeep=s_axis_FSM_tkeep;
        next_state = IDLE;
        next_count = 0;
        next_early_tlast = 0;
        next_valid_early_tlast = 1'b0;
        next_reg_drop_counter = 1'b0;

        case (state)
            IDLE: begin
                if (s_axis_FSM_tvalid) begin
                    if (enable_dp==1) begin
                        next_state = PARSE_DATA;
                    end
                    else begin
                        next_state = SEND_REMAIN;
                    end
                end
            end

            PARSE_DATA: begin
                if (s_axis_FSM_tvalid) begin
                    s_axis_FSM_tready = 1'b1;

                    if (s_axis_FSM_tlast) begin
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
                    next_reg_drop_counter=reg_drop_counter+1;
                end else begin
                    next_state = SEND_ANALYSED_DATA;
                end
                next_early_tlast = early_tlast;
                next_valid_early_tlast = valid_early_tlast;
            end

            SEND_ANALYSED_DATA: begin
                m_axis_FSM_tvalid = 1'b1;
                if (m_axis_FSM_tready) begin
                    if (count == COUNT_META_DATA_MAX - 1) begin
                        next_state = SEND_REMAIN;
                    end else if (count == early_tlast && valid_early_tlast == 1) begin
                        m_axis_FSM_tlast = 1'b1;
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
                if (m_axis_FSM_tready && s_axis_FSM_tvalid) begin
                    s_axis_FSM_tready = 1'b1;
                    m_axis_FSM_tvalid = 1'b1;
                    if (s_axis_FSM_tlast) begin
                        m_axis_FSM_tlast = 1'b1;
                        next_state = IDLE;
                    end else begin
                        next_state = SEND_REMAIN;
                    end
                end
            end

            DROP: begin
                s_axis_FSM_tready = 1'b1;
                if (s_axis_FSM_tlast) begin
                    next_state = IDLE;
                    m_axis_FSM_tlast = 1'b1;
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



