module top_priority_FIFO #(
    // Paramètres de configuration de l'interface Ethernet
    parameter IF_COUNT = 1,
    parameter IF_COUNT_DOWN_RX = 3,
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 9,

    // Paramètres de l'état
    parameter STATE_WIDTH=3,
    parameter IDLE = 0,
    parameter PARSE_DATA = 1,
    parameter CONTROL = 2,
    parameter SEND_ANALYSED_DATA = 3,
    parameter SEND_REMAIN = 4,
    parameter DROP = 5
)
(
    input wire clk,
    input wire rst,

    // AXI Stream input
    input wire [AXIS_DATA_WIDTH-1:0] s_axis_priority_fifo0_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0] s_axis_priority_fifo0_tkeep,
    input wire s_axis_priority_fifo0_tvalid,
    output wire s_axis_priority_fifo0_tready,
    input wire s_axis_priority_fifo0_tlast,

    input wire [AXIS_DATA_WIDTH-1:0] s_axis_priority_fifo1_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0] s_axis_priority_fifo1_tkeep,
    input wire s_axis_priority_fifo1_tvalid,
    output wire s_axis_priority_fifo1_tready,
    input wire s_axis_priority_fifo1_tlast,

    input wire [AXIS_DATA_WIDTH-1:0] s_axis_priority_fifo2_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0] s_axis_priority_fifo2_tkeep,
    input wire s_axis_priority_fifo2_tvalid,
    output wire s_axis_priority_fifo2_tready,
    input wire s_axis_priority_fifo2_tlast,

    // AXI Stream output
    output wire [AXIS_DATA_WIDTH-1:0] m_axis_priority_fifo_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0] m_axis_priority_fifo_tkeep,
    output wire m_axis_priority_fifo_tvalid,
    input wire m_axis_priority_fifo_tready,
    output wire m_axis_priority_fifo_tlast

);
    wire [AXIS_DATA_WIDTH-1:0] w_axis_fifo0_mult_tdata;
    wire [AXIS_KEEP_WIDTH-1:0] w_axis_fifo0_mult_tkeep;
    wire w_axis_fifo0_mult_tvalid;
    wire w_axis_fifo0_mult_tready;
    wire w_axis_fifo0_mult_tdest;

    wire status_overflow_fifo0;
    wire status_bad_frame_fifo0;
    wire status_good_frame_fifo0;

    axis_fifo #(
    // FIFO depth in words
    // KEEP_WIDTH words per cycle if KEEP_ENABLE set
    // Rounded up to nearest power of 2 cycles
    .DEPTH(4096),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(AXIS_DATA_WIDTH),
    // Propagate tkeep signal
    // If disabled, tkeep assumed to be 1'b1
    .KEEP_ENABLE(AXIS_DATA_WIDTH>8),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH((AXIS_DATA_WIDTH+7)/8),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(0),
    // tid signal width
    .ID_WIDTH(8),
    // Propagate tdest signal
    .DEST_ENABLE(0),
    // tdest signal width
    .DEST_WIDTH(8),
    // Propagate tuser signal
    .USER_ENABLE(0),
    // tuser signal width
    .USER_WIDTH(1),
    // number of RAM pipeline registers
    .RAM_PIPELINE(1),
    // use output FIFO
    // When set, the RAM read enable and pipeline clock enables are removed
    .OUTPUT_FIFO_ENABLE(0),
    // Frame FIFO mode - operate on frames instead of cycles
    // When set, m_axis_tvalid will not be deasserted within a frame
    // Requires LAST_ENABLE set
    .FRAME_FIFO(0),
    // tuser value for bad frame marker
    .USER_BAD_FRAME_VALUE(1'b1),
    // tuser mask for bad frame marker
    .USER_BAD_FRAME_MASK(1'b1),
    // Drop frames larger than FIFO
    // Requires FRAME_FIFO set
    .DROP_OVERSIZE_FRAME(0),
    // Drop frames marked bad
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_BAD_FRAME(0),
    // Drop incoming frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_WHEN_FULL(0)
    )
    fifo0_inst (
        .clk(clk),
        .rst(rst),

        .s_axis_tdata(s_axis_priority_fifo0_tdata),
        .s_axis_tkeep(s_axis_priority_fifo0_tkeep),
        .s_axis_tvalid(s_axis_priority_fifo0_tvalid),
        .s_axis_tready(s_axis_priority_fifo0_tready),
        .s_axis_tlast(s_axis_priority_fifo0_tlast),

        .m_axis_tdata(w_axis_fifo0_mult_tdata),
        .m_axis_tkeep(w_axis_fifo0_mult_tkeep),
        .m_axis_tvalid(w_axis_fifo0_mult_tvalid),
        .m_axis_tready(w_axis_fifo0_mult_tready),
        .m_axis_tlast(w_axis_fifo0_mult_tlast),

        .status_overflow(status_overflow_fifo0),
        .status_bad_frame(status_bad_frame_fifo0),
        .status_good_frame(status_good_frame_fifo0)
    );

    wire [AXIS_DATA_WIDTH-1:0] w_axis_fifo1_mult_tdata;
    wire [AXIS_KEEP_WIDTH-1:0] w_axis_fifo1_mult_tkeep;
    wire w_axis_fifo1_mult_tvalid;
    wire w_axis_fifo1_mult_tready;
    wire w_axis_fifo1_mult_tdest;

    wire status_overflow_fifo1;
    wire status_bad_frame_fifo1;
    wire status_good_frame_fifo1;

    axis_fifo #(
    .DATA_WIDTH(AXIS_DATA_WIDTH)
    )
    fifo1_inst (
        .clk(clk),
        .rst(rst),

        .s_axis_tdata(s_axis_priority_fifo1_tdata),
        .s_axis_tkeep(s_axis_priority_fifo1_tkeep),
        .s_axis_tvalid(s_axis_priority_fifo1_tvalid),
        .s_axis_tready(s_axis_priority_fifo1_tready),
        .s_axis_tlast(s_axis_priority_fifo1_tlast),

        .m_axis_tdata(w_axis_fifo1_mult_tdata),
        .m_axis_tkeep(w_axis_fifo1_mult_tkeep),
        .m_axis_tvalid(w_axis_fifo1_mult_tvalid),
        .m_axis_tready(w_axis_fifo1_mult_tready),
        .m_axis_tlast(w_axis_fifo1_mult_tlast),

        .status_overflow(status_overflow_fifo1),
        .status_bad_frame(status_bad_frame_fifo1),
        .status_good_frame(status_good_frame_fifo1)
    );

    wire [AXIS_DATA_WIDTH-1:0] w_axis_fifo2_mult_tdata;
    wire [AXIS_KEEP_WIDTH-1:0] w_axis_fifo2_mult_tkeep;
    wire w_axis_fifo2_mult_tvalid;
    wire w_axis_fifo2_mult_tready;
    wire w_axis_fifo2_mult_tdest;

    wire status_overflow_fifo2;
    wire status_bad_frame_fifo2;
    wire status_good_frame_fifo2;

    axis_fifo #(
    .DATA_WIDTH(AXIS_DATA_WIDTH)
    )
    fifo2_inst (
        .clk(clk),
        .rst(rst),

        .s_axis_tdata(s_axis_priority_fifo2_tdata),
        .s_axis_tkeep(s_axis_priority_fifo2_tkeep),
        .s_axis_tvalid(s_axis_priority_fifo2_tvalid),
        .s_axis_tready(s_axis_priority_fifo2_tready),
        .s_axis_tlast(s_axis_priority_fifo2_tlast),

        .m_axis_tdata(w_axis_fifo2_mult_tdata),
        .m_axis_tkeep(w_axis_fifo2_mult_tkeep),
        .m_axis_tvalid(w_axis_fifo2_mult_tvalid),
        .m_axis_tready(w_axis_fifo2_mult_tready),
        .m_axis_tlast(w_axis_fifo2_mult_tlast),

        .status_overflow(w_status_overflow_fifo2),
        .status_bad_frame(w_status_bad_frame_fifo2),
        .status_good_frame(w_status_good_frame_fifo2)
    );

        
        FIFO_mult  #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
        )
        FIFO_mult_inst(
            .s_axis_priority_fifo0_tdata(w_axis_fifo0_mult_tdata),
            .s_axis_priority_fifo0_tkeep(w_axis_fifo0_mult_tkeep),
            .s_axis_priority_fifo0_tvalid(w_axis_fifo0_mult_tvalid),
            .s_axis_priority_fifo0_tready(w_axis_fifo0_mult_tready),
            .s_axis_priority_fifo0_tlast(w_axis_fifo0_mult_tlast),

            .s_axis_priority_fifo1_tdata(w_axis_fifo1_mult_tdata),
            .s_axis_priority_fifo1_tkeep(w_axis_fifo1_mult_tkeep),
            .s_axis_priority_fifo1_tvalid(w_axis_fifo1_mult_tvalid),
            .s_axis_priority_fifo1_tready(w_axis_fifo1_mult_tready),
            .s_axis_priority_fifo1_tlast(w_axis_fifo1_mult_tlast),

            .s_axis_priority_fifo2_tdata(w_axis_fifo2_mult_tdata),
            .s_axis_priority_fifo2_tkeep(w_axis_fifo2_mult_tkeep),
            .s_axis_priority_fifo2_tvalid(w_axis_fifo2_mult_tvalid),
            .s_axis_priority_fifo2_tready(w_axis_fifo2_mult_tready),
            .s_axis_priority_fifo2_tlast(w_axis_fifo2_mult_tlast),
            
            .m_axis_priority_mult_fifo_tdata(m_axis_priority_fifo_tdata),
            .m_axis_priority_mult_fifo_tkeep(m_axis_priority_fifo_tkeep),
            .m_axis_priority_mult_fifo_tvalid(m_axis_priority_fifo_tvalid),
            .m_axis_priority_mult_fifo_tready(m_axis_priority_fifo_tready),
            .m_axis_priority_mult_fifo_tlast(m_axis_priority_fifo_tlast)
        );
        
    
endmodule