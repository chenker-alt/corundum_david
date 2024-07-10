module axis_dp_demultiplexeur #(
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

    input wire  [IF_COUNT*DATA_WIDTH-1:0] s_axis_dp_top_tdata,
    input wire  [IF_COUNT*KEEP_WIDTH-1:0] s_axis_dp_top_tkeep,
    input wire  [IF_COUNT*USER_WIDTH-1:0] s_axis_dp_top_tuser,
    input wire  [IF_COUNT*ID_WIDTH-1:0]   s_axis_dp_top_tid,
    input wire  [IF_COUNT*DEST_WIDTH-1:0] s_axis_dp_top_tdest,

    output wire [IF_COUNT*DATA_WIDTH-1:0]  m_axis_direct_source_tdata,
    output wire [IF_COUNT*KEEP_WIDTH-1:0]  m_axis_direct_source_tkeep,
    output wire [IF_COUNT*USER_WIDTH-1:0]  m_axis_direct_source_tuser,
    output wire [IF_COUNT*ID_WIDTH-1:0]    m_axis_direct_source_tid,
    output wire [IF_COUNT*DEST_WIDTH-1:0]  m_axis_direct_source_tdest,

    output wire [IF_COUNT*DATA_WIDTH-1:0]  m_axis_parser_tdata,
    output wire [IF_COUNT*KEEP_WIDTH-1:0]  m_axis_parser_tkeep,
    output wire [IF_COUNT*USER_WIDTH-1:0]  m_axis_parser_tuser,
    output wire [IF_COUNT*ID_WIDTH-1:0]    m_axis_parser_tid,
    output wire [IF_COUNT*DEST_WIDTH-1:0]  m_axis_parser_tdest
);
assign m_axis_direct_source_tdata = (state == SEND_REMAIN) ? s_axis_dp_top_tdata : 0;
assign m_axis_direct_source_tkeep = (state == SEND_REMAIN) ? s_axis_dp_top_tkeep : 0;
assign m_axis_direct_source_tuser = (state == SEND_REMAIN) ? s_axis_dp_top_tuser : 0;
assign m_axis_direct_source_tid = (state == SEND_REMAIN) ? s_axis_dp_top_tid : 0;
assign m_axis_direct_source_tdest = (state == SEND_REMAIN) ? s_axis_dp_top_tdest : 0;

assign m_axis_parser_tdata = (state == PARSE_DATA) ? s_axis_dp_top_tdata : 0;
assign m_axis_parser_tkeep = (state == PARSE_DATA) ? s_axis_dp_top_tkeep : 0;
assign m_axis_parser_tuser = (state == PARSE_DATA) ? s_axis_dp_top_tuser : 0;
assign m_axis_parser_tid = (state == PARSE_DATA) ? s_axis_dp_top_tid : 0;
assign m_axis_parser_tdest = (state == PARSE_DATA) ? s_axis_dp_top_tdest : 0;

endmodule
