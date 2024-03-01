module axis_tdest_demux #(
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2
)(
    // AXI Stream input interface
    input wire [AXIS_DATA_WIDTH-1:0]    s_axis_demux_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0]    s_axis_demux_tkeep,
    input wire                          s_axis_demux_tvalid,
    output wire                         s_axis_demux_tready,
    input wire                          s_axis_demux_tlast,
    input wire [AXIS_DEST_WIDTH-1:0]    s_axis_demux_tdest,

    // FIFO interfaces
    output wire [AXIS_DATA_WIDTH-1:0]   m_axis_TX2_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]   m_axis_TX2_tkeep,
    output wire                         m_axis_TX2_tvalid,
    input wire                          m_axis_TX2_tready,
    output wire                         m_axis_TX2_tlast,

    output wire [AXIS_DATA_WIDTH-1:0]   m_axis_TX3_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]   m_axis_TX3_tkeep,
    output wire                         m_axis_TX3_tvalid,
    input wire                          m_axis_TX3_tready,
    output wire                         m_axis_TX3_tlast,

    output wire [AXIS_DATA_WIDTH-1:0]   m_axis_TX4_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]   m_axis_TX4_tkeep,
    output wire                         m_axis_TX4_tvalid,
    input wire                          m_axis_TX4_tready,
    output wire                         m_axis_TX4_tlast
);

assign m_axis_TX2_tdata = (s_axis_demux_tdest==0) ? s_axis_demux_tdata : 0;
assign m_axis_TX2_tkeep = (s_axis_demux_tdest==0) ? s_axis_demux_tkeep : 0;
assign m_axis_TX2_tvalid = (s_axis_demux_tdest==0) ? s_axis_demux_tvalid : 0;
assign m_axis_TX2_tlast = (s_axis_demux_tdest==0) ? s_axis_demux_tlast : 0;

assign m_axis_TX3_tdata = (s_axis_demux_tdest==1) ? s_axis_demux_tdata : 0;
assign m_axis_TX3_tkeep = (s_axis_demux_tdest==0) ? s_axis_demux_tkeep : 0;
assign m_axis_TX3_tvalid = (s_axis_demux_tdest==1) ? s_axis_demux_tvalid : 0;
assign m_axis_TX3_tlast = (s_axis_demux_tdest==1) ? s_axis_demux_tlast : 0;

assign m_axis_TX4_tdata = (s_axis_demux_tdest==2) ? s_axis_demux_tdata : 0;
assign m_axis_TX4_tkeep = (s_axis_demux_tdest==0) ? s_axis_demux_tkeep : 0;
assign m_axis_TX4_tvalid = (s_axis_demux_tdest==2) ? s_axis_demux_tvalid : 0;
assign m_axis_TX4_tlast = (s_axis_demux_tdest==2) ? s_axis_demux_tlast : 0;

assign s_axis_demux_tready =    (s_axis_demux_tdest == 0) ? m_axis_TX2_tready :
                                        (s_axis_demux_tdest == 1) ? m_axis_TX3_tready :
                                        (s_axis_demux_tdest == 2) ? m_axis_TX4_tready :
                                        0;

endmodule
