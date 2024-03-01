module top_scheduler_up #(
    // Ethernet interface configuration
    parameter IF_COUNT = 4,
    parameter IF_COUNT_UP_RX = 1,
    parameter IF_COUNT_UP_TX = 3,
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2,

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // Parser/Mat/deparser configuration
    parameter META_DATA_WIDTH_MAX=272,
    parameter COUNT_META_DATA_MAX=(META_DATA_WIDTH_MAX/AXIS_DATA_WIDTH)+1,
    parameter COUNTER_WIDTH= $clog2(COUNT_META_DATA_MAX+1),

    parameter BUFFER_DATA_WIDTH=COUNT_META_DATA_MAX*AXIS_DATA_WIDTH,


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
    // System (internal at interface module)
    input wire clk,
    input wire rst,

    /*
     * Ethernet (internal at interface module)
     */
    input wire  [IF_COUNT_UP_RX*AXIS_DATA_WIDTH-1:0]  s_axis_top_scheduler_up_tdata,
    input wire  [IF_COUNT_UP_RX*AXIS_KEEP_WIDTH-1:0]  s_axis_top_scheduler_up_tkeep,
    input wire  [IF_COUNT_UP_RX-1:0]                  s_axis_top_scheduler_up_tvalid,
    output wire [IF_COUNT_UP_RX-1:0]                  s_axis_top_scheduler_up_tready,
    input wire  [IF_COUNT_UP_RX-1:0]                  s_axis_top_scheduler_up_tlast,

    output wire [IF_COUNT_UP_TX*AXIS_DATA_WIDTH-1:0]  m_axis_top_scheduler_up_tdata,
    output wire [IF_COUNT_UP_TX*AXIS_KEEP_WIDTH-1:0]  m_axis_top_scheduler_up_tkeep,
    output wire [IF_COUNT_UP_TX-1:0]                  m_axis_top_scheduler_up_tvalid,
    input wire  [IF_COUNT_UP_TX-1:0]                  m_axis_top_scheduler_up_tready,
    output wire [IF_COUNT_UP_TX-1:0]                  m_axis_top_scheduler_up_tlast,

    /*
     * AXI-Lite input/output
     */

    input wire w_enable_dp,
    input wire [32-1:0]w_configurable_ipv4_address,
    input wire w_rst_drop_counter,
    output wire [31:0] w_drop_counter


);
    wire [IF_COUNT_UP_RX*AXIS_DATA_WIDTH-1:0] w_axis_packet_dispatcher_demux_tdata;
    wire [IF_COUNT_UP_RX*AXIS_KEEP_WIDTH -1:0] w_axis_packet_dispatcher_demux_tkeep;
    wire [IF_COUNT_UP_RX-1:0] w_axis_packet_dispatcher_demux_tvalid;
    wire [IF_COUNT_UP_RX-1:0] w_axis_packet_dispatcher_demux_tready;
    wire [IF_COUNT_UP_RX-1:0] w_axis_packet_dispatcher_demux_tlast;
    wire [IF_COUNT_UP_RX*AXIS_DEST_WIDTH-1:0] w_axis_packet_dispatcher_demux_tdest;


    top_packet_dispatcher #(
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

    .META_DATA_WIDTH_MAX(META_DATA_WIDTH_MAX),
    .COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .BUFFER_DATA_WIDTH(BUFFER_DATA_WIDTH),

    .STATE_WIDTH(STATE_WIDTH),
    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP)
    
    ) top_packet_dispatcher_inst (
        .clk(clk),
        .rst(rst),

        .s_axis_top_packet_dispatcher_tdata(s_axis_top_scheduler_up_tdata),
        .s_axis_top_packet_dispatcher_tkeep(s_axis_top_scheduler_up_tkeep),
        .s_axis_top_packet_dispatcher_tvalid(s_axis_top_scheduler_up_tvalid),
        .s_axis_top_packet_dispatcher_tready(s_axis_top_scheduler_up_tready),
        .s_axis_top_packet_dispatcher_tlast(s_axis_top_scheduler_up_tlast),

        .m_axis_top_packet_dispatcher_tdata(w_axis_packet_dispatcher_demux_tdata),
        .m_axis_top_packet_dispatcher_tkeep(w_axis_packet_dispatcher_demux_tkeep),
        .m_axis_top_packet_dispatcher_tvalid(w_axis_packet_dispatcher_demux_tvalid),
        .m_axis_top_packet_dispatcher_tready(w_axis_packet_dispatcher_demux_tready),
        .m_axis_top_packet_dispatcher_tlast(w_axis_packet_dispatcher_demux_tlast),
        .m_axis_top_packet_dispatcher_tdest(w_axis_packet_dispatcher_demux_tdest),

        .w_enable_dp(w_enable_dp),
        .w_configurable_ipv4_address(w_configurable_ipv4_address),
        .w_rst_drop_counter(w_rst_drop_counter),
        .w_drop_counter(w_drop_counter)
    );

    axis_tdest_demux #(
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
    )
    axis_tdest_demux_inst(
    // AXI Stream input interface
    .s_axis_demux_tdata(w_axis_packet_dispatcher_demux_tdata),
    .s_axis_demux_tkeep(w_axis_packet_dispatcher_demux_tkeep),
    .s_axis_demux_tvalid(w_axis_packet_dispatcher_demux_tvalid),
    .s_axis_demux_tready(w_axis_packet_dispatcher_demux_tready),
    .s_axis_demux_tlast(w_axis_packet_dispatcher_demux_tlast),
    .s_axis_demux_tdest(w_axis_packet_dispatcher_demux_tdest),

    // FIFO interfaces
    .m_axis_TX2_tdata(m_axis_top_scheduler_up_tdata[AXIS_DATA_WIDTH-1:0]),
    .m_axis_TX2_tkeep(m_axis_top_scheduler_up_tkeep[AXIS_KEEP_WIDTH-1:0]),
    .m_axis_TX2_tvalid(m_axis_top_scheduler_up_tvalid[0]),
    .m_axis_TX2_tready(m_axis_top_scheduler_up_tready[0]),
    .m_axis_TX2_tlast(m_axis_top_scheduler_up_tlast[0]),

    .m_axis_TX3_tdata(m_axis_top_scheduler_up_tdata[AXIS_DATA_WIDTH*2-1-:AXIS_DATA_WIDTH]),
    .m_axis_TX3_tkeep(m_axis_top_scheduler_up_tkeep[AXIS_KEEP_WIDTH*2-1-:AXIS_KEEP_WIDTH]),
    .m_axis_TX3_tvalid(m_axis_top_scheduler_up_tvalid[1]),
    .m_axis_TX3_tready(m_axis_top_scheduler_up_tready[1]),
    .m_axis_TX3_tlast(m_axis_top_scheduler_up_tlast[1]),

    .m_axis_TX4_tdata(m_axis_top_scheduler_up_tdata[(AXIS_DATA_WIDTH*3)-1-:AXIS_DATA_WIDTH]),
    .m_axis_TX4_tkeep(m_axis_top_scheduler_up_tkeep[(AXIS_KEEP_WIDTH*3)-1-:AXIS_KEEP_WIDTH]),
    .m_axis_TX4_tvalid(m_axis_top_scheduler_up_tvalid[2]),
    .m_axis_TX4_tready(m_axis_top_scheduler_up_tready[2]),
    .m_axis_TX4_tlast(m_axis_top_scheduler_up_tlast[2])
    );

endmodule
