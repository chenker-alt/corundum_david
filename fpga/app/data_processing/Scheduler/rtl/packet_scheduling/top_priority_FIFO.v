module top_priority_FIFO #(
    // Paramètres de configuration de l'interface Ethernet
    parameter PORT_COUNT_RX= 3,
    parameter PORT_COUNT_TX = 1,

    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 9,

    //////////packet_scheduling//////////

    //FIFO parameter
    parameter PACKET_SCHEDULING_ENABLE=1,

    parameter N_FIFO=3,
    
    parameter FIFO0_DEPTH = 4096*256,
    parameter FIFO1_DEPTH = 4096*256,
    parameter FIFO2_DEPTH = 4096*256,

    parameter FIFO_DATA_WIDTH = 64,
    parameter FIFO_KEEP_ENABLE = (FIFO_DATA_WIDTH>8),
    parameter FIFO_KEEP_WIDTH = ((FIFO_DATA_WIDTH+7)/8),
    parameter FIFO_LAST_ENABLE = 1,
    parameter FIFO_ID_ENABLE = 0,
    parameter FIFO_ID_WIDTH = 8,
    parameter FIFO_DEST_ENABLE = 0,
    parameter FIFO_DEST_WIDTH = 8,
    parameter FIFO_USER_ENABLE = 0,
    parameter FIFO_USER_WIDTH = 1,
    parameter FIFO_RAM_PIPELINE = 1,
    parameter FIFO_OUTPUT_FIFO_ENABLE = 1,
    parameter FIFO_FRAME_FIFO = 0,
    parameter FIFO_USER_BAD_FRAME_VALUE = 1'b1,
    parameter FIFO_USER_BAD_FRAME_MASK = 1'b1,
    parameter FIFO_DROP_OVERSIZE_FRAME = FIFO_FRAME_FIFO,
    parameter FIFO_DROP_BAD_FRAME = 0,
    parameter FIFO_DROP_WHEN_FULL = 0,
    parameter FIFO_MARK_WHEN_FULL = 0,
    parameter FIFO_PAUSE_ENABLE = 0,
    parameter FIFO_FRAME_PAUSE = FIFO_FRAME_FIFO
)
(
    input wire clk,
    input wire rst,

    // AXI Stream input
    input wire [PORT_COUNT_RX*AXIS_DATA_WIDTH-1:0]   s_axis_priority_fifo_tdata,
    input wire [PORT_COUNT_RX*AXIS_KEEP_WIDTH-1:0]   s_axis_priority_fifo_tkeep,
    input wire [PORT_COUNT_RX-1:0]                   s_axis_priority_fifo_tvalid,
    output wire [PORT_COUNT_RX-1:0]                  s_axis_priority_fifo_tready,
    input wire [PORT_COUNT_RX-1:0]                   s_axis_priority_fifo_tlast,

    // AXI Stream output
    output wire [AXIS_DATA_WIDTH*PORT_COUNT_TX-1:0] m_axis_priority_fifo_tdata,
    output wire [AXIS_KEEP_WIDTH*PORT_COUNT_TX-1:0] m_axis_priority_fifo_tkeep,
    output wire [PORT_COUNT_TX-1:0] m_axis_priority_fifo_tvalid,
    input wire [PORT_COUNT_TX-1:0] m_axis_priority_fifo_tready,
    output wire [PORT_COUNT_TX-1:0] m_axis_priority_fifo_tlast

);

    wire [AXIS_DATA_WIDTH-1:0]  s_axis_priority_fifo0_tdata;
    wire [AXIS_KEEP_WIDTH-1:0]  s_axis_priority_fifo0_tkeep;
    wire                        s_axis_priority_fifo0_tvalid;
    wire                        s_axis_priority_fifo0_tready;
    wire                        s_axis_priority_fifo0_tlast;

    assign s_axis_priority_fifo0_tdata  = s_axis_priority_fifo_tdata[AXIS_DATA_WIDTH-1:0];
    assign s_axis_priority_fifo0_tkeep  = s_axis_priority_fifo_tkeep[AXIS_KEEP_WIDTH-1:0];
    assign s_axis_priority_fifo0_tvalid = s_axis_priority_fifo_tvalid[0];
    assign s_axis_priority_fifo_tready[0]= s_axis_priority_fifo0_tready;
    assign s_axis_priority_fifo0_tlast = s_axis_priority_fifo_tlast[0];
    
    wire [AXIS_DATA_WIDTH-1:0]  s_axis_priority_fifo1_tdata;
    wire [AXIS_KEEP_WIDTH-1:0]  s_axis_priority_fifo1_tkeep;
    wire                        s_axis_priority_fifo1_tvalid;
    wire                        s_axis_priority_fifo1_tready;
    wire                        s_axis_priority_fifo1_tlast;

    assign s_axis_priority_fifo1_tdata  = s_axis_priority_fifo_tdata[AXIS_DATA_WIDTH*2-1-:AXIS_DATA_WIDTH];
    assign s_axis_priority_fifo1_tkeep  = s_axis_priority_fifo_tkeep[AXIS_KEEP_WIDTH*2-1-:AXIS_KEEP_WIDTH];
    assign s_axis_priority_fifo1_tvalid = s_axis_priority_fifo_tvalid[1];
    assign s_axis_priority_fifo_tready[1]= s_axis_priority_fifo1_tready;
    assign s_axis_priority_fifo1_tlast = s_axis_priority_fifo_tlast[1];

    wire [AXIS_DATA_WIDTH-1:0]  s_axis_priority_fifo2_tdata;
    wire [AXIS_KEEP_WIDTH-1:0]  s_axis_priority_fifo2_tkeep;
    wire                        s_axis_priority_fifo2_tvalid;
    wire                        s_axis_priority_fifo2_tready;
    wire                        s_axis_priority_fifo2_tlast;

    assign s_axis_priority_fifo2_tdata  = s_axis_priority_fifo_tdata[AXIS_DATA_WIDTH*3-1-:AXIS_DATA_WIDTH];
    assign s_axis_priority_fifo2_tkeep  = s_axis_priority_fifo_tkeep[AXIS_KEEP_WIDTH*3-1-:AXIS_KEEP_WIDTH];
    assign s_axis_priority_fifo2_tvalid = s_axis_priority_fifo_tvalid[2];
    assign s_axis_priority_fifo_tready[2]= s_axis_priority_fifo2_tready;
    assign s_axis_priority_fifo2_tlast = s_axis_priority_fifo_tlast[2];


    wire [AXIS_DATA_WIDTH-1:0] w_axis_fifo0_mult_tdata;
    wire [AXIS_KEEP_WIDTH-1:0] w_axis_fifo0_mult_tkeep;
    wire w_axis_fifo0_mult_tvalid;
    wire w_axis_fifo0_mult_tready;
    wire w_axis_fifo0_mult_tdest;

    wire status_overflow_fifo0;
    wire status_bad_frame_fifo0;
    wire status_good_frame_fifo0;

    reg pause_req=0;

    axis_fifo #(
    .DEPTH(FIFO0_DEPTH),
    .DATA_WIDTH(FIFO_DATA_WIDTH),
    .KEEP_ENABLE(FIFO_KEEP_ENABLE),
    .KEEP_WIDTH(FIFO_KEEP_WIDTH),
    .LAST_ENABLE(FIFO_LAST_ENABLE),
    .ID_ENABLE(FIFO_ID_ENABLE),
    .ID_WIDTH(FIFO_ID_WIDTH),
    .DEST_ENABLE(FIFO_DEST_ENABLE),
    .DEST_WIDTH(FIFO_DEST_WIDTH),
    .USER_ENABLE(FIFO_USER_ENABLE),
    .USER_WIDTH(FIFO_USER_WIDTH),
    .RAM_PIPELINE(FIFO_RAM_PIPELINE),
    .OUTPUT_FIFO_ENABLE(FIFO_OUTPUT_FIFO_ENABLE),
    .FRAME_FIFO(FIFO_FRAME_FIFO),
    .USER_BAD_FRAME_VALUE(FIFO_USER_BAD_FRAME_VALUE),
    .USER_BAD_FRAME_MASK(FIFO_USER_BAD_FRAME_MASK),
    .DROP_OVERSIZE_FRAME(FIFO_DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(FIFO_DROP_BAD_FRAME),
    .DROP_WHEN_FULL(FIFO_DROP_WHEN_FULL),
    .PAUSE_ENABLE(FIFO_PAUSE_ENABLE),
    .FRAME_PAUSE(FIFO_FRAME_PAUSE)
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


        .status_depth(w_status_depth_fifo0),
        .status_overflow(status_overflow_fifo0),
        .status_bad_frame(status_bad_frame_fifo0),
        .status_good_frame(status_good_frame_fifo0),

        .pause_req(pause_req)
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
    .DEPTH(FIFO1_DEPTH),
    .DATA_WIDTH(FIFO_DATA_WIDTH),
    .KEEP_ENABLE(FIFO_KEEP_ENABLE),
    .KEEP_WIDTH(FIFO_KEEP_WIDTH),
    .LAST_ENABLE(FIFO_LAST_ENABLE),
    .ID_ENABLE(FIFO_ID_ENABLE),
    .ID_WIDTH(FIFO_ID_WIDTH),
    .DEST_ENABLE(FIFO_DEST_ENABLE),
    .DEST_WIDTH(FIFO_DEST_WIDTH),
    .USER_ENABLE(FIFO_USER_ENABLE),
    .USER_WIDTH(FIFO_USER_WIDTH),
    .RAM_PIPELINE(FIFO_RAM_PIPELINE),
    .OUTPUT_FIFO_ENABLE(FIFO_OUTPUT_FIFO_ENABLE),
    .FRAME_FIFO(FIFO_FRAME_FIFO),
    .USER_BAD_FRAME_VALUE(FIFO_USER_BAD_FRAME_VALUE),
    .USER_BAD_FRAME_MASK(FIFO_USER_BAD_FRAME_MASK),
    .DROP_OVERSIZE_FRAME(FIFO_DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(FIFO_DROP_BAD_FRAME),
    .DROP_WHEN_FULL(FIFO_DROP_WHEN_FULL),
    .PAUSE_ENABLE(FIFO_PAUSE_ENABLE),
    .FRAME_PAUSE(FIFO_FRAME_PAUSE)
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

        .status_depth(w_status_depth_fifo1),
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
    .DEPTH(FIFO2_DEPTH),
    .DATA_WIDTH(FIFO_DATA_WIDTH),
    .KEEP_ENABLE(FIFO_KEEP_ENABLE),
    .KEEP_WIDTH(FIFO_KEEP_WIDTH),
    .LAST_ENABLE(FIFO_LAST_ENABLE),
    .ID_ENABLE(FIFO_ID_ENABLE),
    .ID_WIDTH(FIFO_ID_WIDTH),
    .DEST_ENABLE(FIFO_DEST_ENABLE),
    .DEST_WIDTH(FIFO_DEST_WIDTH),
    .USER_ENABLE(FIFO_USER_ENABLE),
    .USER_WIDTH(FIFO_USER_WIDTH),
    .RAM_PIPELINE(FIFO_RAM_PIPELINE),
    .OUTPUT_FIFO_ENABLE(FIFO_OUTPUT_FIFO_ENABLE),
    .FRAME_FIFO(FIFO_FRAME_FIFO),
    .USER_BAD_FRAME_VALUE(FIFO_USER_BAD_FRAME_VALUE),
    .USER_BAD_FRAME_MASK(FIFO_USER_BAD_FRAME_MASK),
    .DROP_OVERSIZE_FRAME(FIFO_DROP_OVERSIZE_FRAME),
    .DROP_BAD_FRAME(FIFO_DROP_BAD_FRAME),
    .DROP_WHEN_FULL(FIFO_DROP_WHEN_FULL),
    .PAUSE_ENABLE(FIFO_PAUSE_ENABLE),
    .FRAME_PAUSE(FIFO_FRAME_PAUSE)
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

        .status_depth(w_status_depth_fifo2),

        .status_overflow(w_status_overflow_fifo2),
        .status_bad_frame(w_status_bad_frame_fifo2),
        .status_good_frame(w_status_good_frame_fifo2)
    );
        wire [3*AXIS_DATA_WIDTH-1:0] w_axis_fifo_mult_tdata;
        wire [3*AXIS_KEEP_WIDTH-1:0] w_axis_fifo_mult_tkeep;
        wire [2:0] w_axis_fifo_mult_tvalid;
        wire [2:0] w_axis_fifo_mult_tready;
        wire [2:0] w_axis_fifo_mult_tlast;

        assign w_axis_fifo_mult_tdata = {w_axis_fifo2_mult_tdata,w_axis_fifo1_mult_tdata,w_axis_fifo0_mult_tdata};
        assign w_axis_fifo_mult_tkeep = {w_axis_fifo2_mult_tkeep,w_axis_fifo1_mult_tkeep,w_axis_fifo0_mult_tkeep};
        assign w_axis_fifo_mult_tvalid = {w_axis_fifo2_mult_tvalid,w_axis_fifo1_mult_tvalid,w_axis_fifo0_mult_tvalid};
        assign w_axis_fifo0_mult_tready = w_axis_fifo_mult_tready[0];
        assign w_axis_fifo1_mult_tready = w_axis_fifo_mult_tready[1];
        assign w_axis_fifo2_mult_tready = w_axis_fifo_mult_tready[2];
        assign w_axis_fifo_mult_tlast = {w_axis_fifo2_mult_tlast,w_axis_fifo1_mult_tlast,w_axis_fifo0_mult_tlast};

        wire [2:0] w_sel_fifo_mult;
        wire w_en_fifo_mult;
        
        axis_mux  #(
        // Number of AXI stream inputs
        .S_COUNT(N_FIFO),
        // Width of AXI stream interfaces in bits
        .DATA_WIDTH(AXIS_DATA_WIDTH),
        // Propagate tkeep signal
        .KEEP_ENABLE(AXIS_DATA_WIDTH>8),
        // tkeep signal width (words per cycle)
        .KEEP_WIDTH((AXIS_DATA_WIDTH+7)/8),
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
        .USER_WIDTH(1)
        )
        axis_mux_inst(
            .clk(clk),
            .rst(rst),

            .s_axis_tdata(w_axis_fifo_mult_tdata),
            .s_axis_tkeep(w_axis_fifo_mult_tkeep),
            .s_axis_tvalid(w_axis_fifo_mult_tvalid),
            .s_axis_tready(w_axis_fifo_mult_tready),
            .s_axis_tlast(w_axis_fifo_mult_tlast),
            
            .m_axis_tdata(m_axis_priority_fifo_tdata),
            .m_axis_tkeep(m_axis_priority_fifo_tkeep),
            .m_axis_tvalid(m_axis_priority_fifo_tvalid),
            .m_axis_tready(m_axis_priority_fifo_tready),
            .m_axis_tlast(m_axis_priority_fifo_tlast),

            .enable(w_en_fifo_mult),
            .select(w_sel_fifo_mult)
        );
    
    FIFO_sched #(

    )
    FIFO_sched_inst
    (
    .clk(clk),

    .sel(w_sel_fifo_mult),
    .en(w_en_fifo_mult),
    
    .s_axis_tvalid(w_axis_fifo_mult_tvalid),
    .m_axis_mult_tlast(m_axis_priority_fifo_tlast)
    );
        
    
endmodule