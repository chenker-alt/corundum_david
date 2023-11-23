module axis_simple_controller #(
    parameter IF_COUNT = 1,
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_ID_WIDTH = 1,
    parameter AXIS_DEST_WIDTH = 9,
    parameter AXIS_USER_WIDTH = 97
)
(
    input wire clk,
    input wire rst,

    input wire grant,
    
    input  wire [IF_COUNT*AXIS_DATA_WIDTH-1:0]    s_axis_simple_controller_tdata,
    input  wire [IF_COUNT*AXIS_KEEP_WIDTH-1:0]    s_axis_simple_controller_tkeep,
    input  wire [IF_COUNT-1:0]                    s_axis_simple_controller_tvalid,
    output reg  [IF_COUNT-1:0]                    s_axis_simple_controller_tready=0,
    input  wire [IF_COUNT-1:0]                    s_axis_simple_controller_tlast,
    input  wire [IF_COUNT*AXIS_USER_WIDTH-1:0]    s_axis_simple_controller_tuser,
    input  wire [IF_COUNT*AXIS_ID_WIDTH-1:0]      s_axis_simple_controller_tid,
    input  wire [IF_COUNT*AXIS_DEST_WIDTH-1:0]    s_axis_simple_controller_tdest,

    output reg  [IF_COUNT*AXIS_DATA_WIDTH-1:0]    m_axis_simple_controller_tdata=0,
    output reg  [IF_COUNT*AXIS_KEEP_WIDTH-1:0]    m_axis_simple_controller_tkeep=0,
    output reg  [IF_COUNT-1:0]                    m_axis_simple_controller_tvalid=0,
    input  wire [IF_COUNT-1:0]                    m_axis_simple_controller_tready,
    output reg  [IF_COUNT-1:0]                    m_axis_simple_controller_tlast=0,
    output reg  [IF_COUNT*AXIS_USER_WIDTH-1:0]    m_axis_simple_controller_tuser=0,
    output reg  [IF_COUNT*AXIS_ID_WIDTH-1:0]      m_axis_simple_controller_tid=0,
    output reg  [IF_COUNT*AXIS_DEST_WIDTH-1:0]    m_axis_simple_controller_tdest=0

);
localparam IDLE=0,
           RECEIVE_AND_SEND=1;
           
reg state,next_state=0;

always @(posedge clk) begin
    if (rst)begin
    state <=IDLE;
    end
    else begin
    state<=next_state;
    end
end

always @(*)begin
    case(state)
        IDLE:begin
            m_axis_simple_controller_tvalid = 1'b0;
            s_axis_simple_controller_tready=1'b0;
            
            m_axis_simple_controller_tdata  = 0;
            m_axis_simple_controller_tkeep  = 0;
            m_axis_simple_controller_tlast  = 0;
            m_axis_simple_controller_tuser  = 0;
            m_axis_simple_controller_tid   = 0;
            m_axis_simple_controller_tdest = 0;

            if(grant)begin
                next_state=RECEIVE_AND_SEND;
            end else begin
                next_state=IDLE;
            end
        end
        RECEIVE_AND_SEND:begin

            if (m_axis_simple_controller_tready & s_axis_simple_controller_tvalid) begin
                m_axis_simple_controller_tvalid=1'b1;
                s_axis_simple_controller_tready=1'b1;

                m_axis_simple_controller_tdata  = s_axis_simple_controller_tdata;
                m_axis_simple_controller_tkeep  = s_axis_simple_controller_tkeep;
                m_axis_simple_controller_tlast  = s_axis_simple_controller_tlast;
                m_axis_simple_controller_tuser  = s_axis_simple_controller_tuser;
                m_axis_simple_controller_tid   = s_axis_simple_controller_tid;
                m_axis_simple_controller_tdest = s_axis_simple_controller_tdest;

            end else begin
                m_axis_simple_controller_tvalid=1'b0;
                s_axis_simple_controller_tready=1'b0;
                
                m_axis_simple_controller_tdata  = 0;
                m_axis_simple_controller_tkeep  = 0;
                m_axis_simple_controller_tlast  = 0;
                m_axis_simple_controller_tuser  = 0;
                m_axis_simple_controller_tid   = 0;
                m_axis_simple_controller_tdest = 0;
                end
            
            if (s_axis_simple_controller_tlast) begin
                next_state=IDLE;

            end else begin
                next_state=RECEIVE_AND_SEND;
            end
        end
    endcase
end
endmodule