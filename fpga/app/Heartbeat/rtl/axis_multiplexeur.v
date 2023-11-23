module axis_multiplexeur #(
    parameter IF_COUNT = 1,
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_ID_WIDTH = 1,
    parameter AXIS_DEST_WIDTH = 9,
    parameter AXIS_USER_WIDTH = 97
)(
    input wire grant_heartbeat1,
    input wire grant_heartbeat2,
    input wire grant_heartbeat3,
    input wire grant_SFP,

    output wire  [AXIS_DATA_WIDTH-1:0]          m_axis_mux_tdata,
    output wire  [AXIS_KEEP_WIDTH-1:0]          m_axis_mux_tkeep,
    output wire  [IF_COUNT-1:0]                 m_axis_mux_tvalid,
    input  wire  [IF_COUNT-1:0]                 m_axis_mux_tready,
    output wire  [IF_COUNT-1:0]                 m_axis_mux_tlast,
    output wire  [AXIS_USER_WIDTH-1:0]          m_axis_mux_tuser,
    output wire  [AXIS_ID_WIDTH-1:0]            m_axis_mux_tid,
    output wire  [AXIS_DEST_WIDTH-1:0]          m_axis_mux_tdest,

    input wire [IF_COUNT*AXIS_DATA_WIDTH-1:0]   s_axis_heartbeat1_tdata,
    input wire [IF_COUNT*AXIS_KEEP_WIDTH-1:0]   s_axis_heartbeat1_tkeep,
    input wire [IF_COUNT-1:0]                   s_axis_heartbeat1_tvalid,
    output wire[IF_COUNT-1:0]                   s_axis_heartbeat1_tready,
    input wire [IF_COUNT-1:0]                   s_axis_heartbeat1_tlast,
    input wire [IF_COUNT*AXIS_USER_WIDTH-1:0]   s_axis_heartbeat1_tuser,
    input wire [IF_COUNT*AXIS_ID_WIDTH-1:0]     s_axis_heartbeat1_tid,
    input wire [IF_COUNT*AXIS_DEST_WIDTH-1:0]   s_axis_heartbeat1_tdest,

    input wire [IF_COUNT*AXIS_DATA_WIDTH-1:0]   s_axis_heartbeat2_tdata,
    input wire [IF_COUNT*AXIS_KEEP_WIDTH-1:0]   s_axis_heartbeat2_tkeep,
    input wire [IF_COUNT-1:0]                   s_axis_heartbeat2_tvalid,
    output wire[IF_COUNT-1:0]                   s_axis_heartbeat2_tready,
    input wire [IF_COUNT-1:0]                   s_axis_heartbeat2_tlast,
    input wire [IF_COUNT*AXIS_USER_WIDTH-1:0]   s_axis_heartbeat2_tuser,
    input wire [IF_COUNT*AXIS_ID_WIDTH-1:0]     s_axis_heartbeat2_tid,
    input wire [IF_COUNT*AXIS_DEST_WIDTH-1:0]   s_axis_heartbeat2_tdest,

    input wire [IF_COUNT*AXIS_DATA_WIDTH-1:0]   s_axis_heartbeat3_tdata,
    input wire [IF_COUNT*AXIS_KEEP_WIDTH-1:0]   s_axis_heartbeat3_tkeep,
    input wire [IF_COUNT-1:0]                   s_axis_heartbeat3_tvalid,
    output wire[IF_COUNT-1:0]                   s_axis_heartbeat3_tready,
    input wire [IF_COUNT-1:0]                   s_axis_heartbeat3_tlast,
    input wire [IF_COUNT*AXIS_USER_WIDTH-1:0]   s_axis_heartbeat3_tuser,
    input wire [IF_COUNT*AXIS_ID_WIDTH-1:0]     s_axis_heartbeat3_tid,
    input wire [IF_COUNT*AXIS_DEST_WIDTH-1:0]   s_axis_heartbeat3_tdest,

    input wire [IF_COUNT*AXIS_DATA_WIDTH-1:0]   s_axis_SFP_tdata,
    input wire [IF_COUNT*AXIS_KEEP_WIDTH-1:0]   s_axis_SFP_tkeep,
    input wire [IF_COUNT-1:0]                   s_axis_SFP_tvalid,
    output wire[IF_COUNT-1:0]                   s_axis_SFP_tready,
    input wire [IF_COUNT-1:0]                   s_axis_SFP_tlast,
    input wire [IF_COUNT*AXIS_USER_WIDTH-1:0]   s_axis_SFP_tuser,
    input wire [IF_COUNT*AXIS_ID_WIDTH-1:0]     s_axis_SFP_tid,
    input wire [IF_COUNT*AXIS_DEST_WIDTH-1:0]   s_axis_SFP_tdest

);

    assign m_axis_mux_tdata =   grant_heartbeat1 ? s_axis_heartbeat1_tdata :
                                grant_heartbeat2 ? s_axis_heartbeat2_tdata :
                                grant_heartbeat3 ? s_axis_heartbeat3_tdata :
                                grant_SFP        ? s_axis_SFP_tdata        : 0;

    assign m_axis_mux_tkeep =   grant_heartbeat1 ? s_axis_heartbeat1_tkeep :
                                grant_heartbeat2 ? s_axis_heartbeat2_tkeep :
                                grant_heartbeat3 ? s_axis_heartbeat3_tkeep :
                                grant_SFP        ? s_axis_SFP_tkeep        : 0;

    assign m_axis_mux_tvalid =  grant_heartbeat1 ? s_axis_heartbeat1_tvalid :
                                grant_heartbeat2 ? s_axis_heartbeat2_tvalid :
                                grant_heartbeat3 ? s_axis_heartbeat3_tvalid :
                                grant_SFP        ? s_axis_SFP_tvalid        : 0;

    assign m_axis_mux_tlast =   grant_heartbeat1 ? s_axis_heartbeat1_tlast :
                                grant_heartbeat2 ? s_axis_heartbeat2_tlast :
                                grant_heartbeat3 ? s_axis_heartbeat3_tlast :
                                grant_SFP        ? s_axis_SFP_tlast        : 0;

    assign m_axis_mux_tuser =   grant_heartbeat1 ? s_axis_heartbeat1_tuser :
                                grant_heartbeat2 ? s_axis_heartbeat2_tuser :
                                grant_heartbeat3 ? s_axis_heartbeat3_tuser :
                                grant_SFP        ? s_axis_SFP_tuser        : 0;
                            
    assign m_axis_mux_tid =     grant_heartbeat1 ? s_axis_heartbeat1_tid :
                                grant_heartbeat2 ? s_axis_heartbeat2_tid :
                                grant_heartbeat3 ? s_axis_heartbeat3_tid :
                                grant_SFP        ? s_axis_SFP_tid        : 0;

    assign m_axis_mux_tdest =   grant_heartbeat1 ? s_axis_heartbeat1_tdest :
                                grant_heartbeat2 ? s_axis_heartbeat2_tdest :
                                grant_heartbeat3 ? s_axis_heartbeat3_tdest :
                                grant_SFP        ? s_axis_SFP_tdest        : 0;

    assign s_axis_SFP_tready        =  grant_SFP               ? m_axis_mux_tready        : 0;
    assign s_axis_heartbeat1_tready =  grant_heartbeat1        ? m_axis_mux_tready        : 0;
    assign s_axis_heartbeat2_tready =  grant_heartbeat2        ? m_axis_mux_tready        : 0;
    assign s_axis_heartbeat3_tready =  grant_heartbeat3        ? m_axis_mux_tready        : 0;

endmodule
