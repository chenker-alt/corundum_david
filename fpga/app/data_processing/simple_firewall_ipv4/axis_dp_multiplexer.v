module axis_dp_multiplexeur #(
    parameter IF_COUNT = 1,
    parameter DATA_WIDTH = 64,
    parameter KEEP_WIDTH = DATA_WIDTH/8,
    parameter ID_WIDTH =1,
    parameter DEST_WIDTH = 9,
    parameter USER_WIDTH = 97,

    parameter IDLE                  = 0,
    parameter PARSE_DATA            = 1,
    parameter CONTROL               = 2,
    parameter SEND_ANALYSED_DATA    = 3,
    parameter SEND_REMAIN           = 4,
    parameter DROP                  = 5
)(
    input wire [2:0] state,

    output wire  [IF_COUNT*DATA_WIDTH-1:0]  m_axis_dp_top_tdata,
    output wire  [IF_COUNT*KEEP_WIDTH-1:0]  m_axis_dp_top_tkeep,
    output wire  [IF_COUNT*USER_WIDTH-1:0]  m_axis_dp_top_tuser,
    output wire  [IF_COUNT*ID_WIDTH-1:0]    m_axis_dp_top_tid,
    output wire  [IF_COUNT*DEST_WIDTH-1:0]  m_axis_dp_top_tdest,

    input wire [IF_COUNT*DATA_WIDTH-1:0]   s_axis_direct_source_tdata,
    input wire [IF_COUNT*KEEP_WIDTH-1:0]   s_axis_direct_source_tkeep,
    input wire [IF_COUNT*USER_WIDTH-1:0]   s_axis_direct_source_tuser,
    input wire [IF_COUNT*ID_WIDTH-1:0]     s_axis_direct_source_tid,
    input wire [IF_COUNT*DEST_WIDTH-1:0]   s_axis_direct_source_tdest,

    input wire [IF_COUNT*DATA_WIDTH-1:0]   s_axis_deparser_tdata,
    input wire [IF_COUNT*KEEP_WIDTH-1:0]   s_axis_deparser_tkeep,
    input wire [IF_COUNT*USER_WIDTH-1:0]   s_axis_deparser_tuser,
    input wire [IF_COUNT*ID_WIDTH-1:0]     s_axis_deparser_tid,
    input wire [IF_COUNT*DEST_WIDTH-1:0]   s_axis_deparser_tdest
);
assign m_axis_dp_top_tdata = (state == SEND_ANALYSED_DATA) ? s_axis_deparser_tdata :
                             (state == SEND_REMAIN) ? s_axis_direct_source_tdata : 0;

assign m_axis_dp_top_tkeep = (state == SEND_ANALYSED_DATA) ? s_axis_deparser_tkeep :
                             (state == SEND_REMAIN) ? s_axis_direct_source_tkeep : 0;

assign m_axis_dp_top_tuser = (state == SEND_ANALYSED_DATA) ? s_axis_deparser_tuser :
                             (state == SEND_REMAIN) ? s_axis_direct_source_tuser : 0;

assign m_axis_dp_top_tid = (state == SEND_ANALYSED_DATA) ? s_axis_deparser_tid :
                           (state == SEND_REMAIN) ? s_axis_direct_source_tid : 0;

assign m_axis_dp_top_tdest = (state == SEND_ANALYSED_DATA) ? s_axis_deparser_tdest :
                             (state == SEND_REMAIN) ? s_axis_direct_source_tdest : 0;

endmodule
