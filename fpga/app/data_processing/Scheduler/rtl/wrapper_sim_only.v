module wrapper_sim_only #(

    parameter IF_COUNT = 4,

    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    
    // Ethernet interface configuration
    parameter PORT_COUNT_RX_DOWN = 3,
    parameter PORT_COUNT_TX_DOWN = 1,
    parameter PORT_COUNT_RX_UP = IF_COUNT-PORT_COUNT_RX_DOWN,
    parameter PORT_COUNT_TX_UP = IF_COUNT-PORT_COUNT_TX_DOWN,
    parameter AXIS_DEST_WIDTH = 2,

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),
    
    ////////////packet_processing///////////

    // Buffer configuration
    parameter META_DATA_WIDTH_MAX=96,
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
    parameter DROP                  = 5,
    parameter TCAM_INIT             = 6,

    //TCAM parameter
    parameter TCAM_ADDR_WIDTH=4,
    parameter TCAM_KEY_WIDTH =96,
    parameter TCAM_DATA_WIDTH=4,
    parameter TCAM_MASK_DISABLE=0,
    parameter TCAM_RAM_STYLE="block",

    ///////////Switch//////////
    parameter S_COUNT=3,
    parameter M_COUNT=3,
    parameter KEEP_ENABLE=(AXIS_DATA_WIDTH>8),
    parameter ID_ENABLE=0,
    parameter S_ID_WIDTH=8,
    parameter M_ID_WIDTH=8,
    parameter USER_ENABLE=0,
    parameter USER_WIDTH=1,
    parameter M_BASE=0,
    parameter M_TOP=0,
    parameter M_CONNECT=({3{{3{1'b1}}}}),
    parameter UPDATE_TID=0,
    parameter S_REG_TYPE=0,
    parameter M_REG_TYPE=2,
    parameter ARB_TYPE_ROUND_ROBIN=1,
    parameter ARB_LSB_HIGH_PRIORITY=1,

    //////////packet_scheduling//////////

    //FIFO parameter
    parameter PACKET_SCHEDULING_ENABLE_DOWN=1,
    parameter PACKET_SCHEDULING_ENABLE_UP=0,

    parameter N_FIFO=3,
    
    parameter FIFO0_DEPTH = 4096*256,
    parameter FIFO1_DEPTH = 4096*256,
    parameter FIFO2_DEPTH = 4096*256,

    parameter FIFO_DATA_WIDTH = 64,
    parameter FIFO_KEEP_ENABLE = (AXIS_DATA_WIDTH>8),
    parameter FIFO_KEEP_WIDTH = ((AXIS_DATA_WIDTH+7)/8),
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
    )(
    
    input wire clk,
    input wire rst,
    
    /*
     * Ethernet (internal at interface module)
     */

    //port1
    output wire [AXIS_DATA_WIDTH-1:0]           m_axis_port1_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]           m_axis_port1_tkeep,
    output wire                                 m_axis_port1_tvalid,
    input  wire                                 m_axis_port1_tready,
    output wire                                 m_axis_port1_tlast,

    input  wire [AXIS_DATA_WIDTH-1:0]           s_axis_port1_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]           s_axis_port1_tkeep,
    input  wire                                 s_axis_port1_tvalid,
    output wire                                 s_axis_port1_tready,
    input  wire                                 s_axis_port1_tlast,

    //Port2
    output wire [AXIS_DATA_WIDTH-1:0]           m_axis_port2_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]           m_axis_port2_tkeep,
    output wire                                 m_axis_port2_tvalid,
    input  wire                                 m_axis_port2_tready,
    output wire                                 m_axis_port2_tlast,

    input  wire [AXIS_DATA_WIDTH-1:0]           s_axis_port2_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]           s_axis_port2_tkeep,
    input  wire                                 s_axis_port2_tvalid,
    output wire                                 s_axis_port2_tready,
    input  wire                                 s_axis_port2_tlast,

    //port3
    output wire [AXIS_DATA_WIDTH-1:0]           m_axis_port3_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]           m_axis_port3_tkeep,
    output wire                                 m_axis_port3_tvalid,
    input  wire                                 m_axis_port3_tready,
    output wire                                 m_axis_port3_tlast,

    input  wire [AXIS_DATA_WIDTH-1:0]           s_axis_port3_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]           s_axis_port3_tkeep,
    input  wire                                 s_axis_port3_tvalid,
    output wire                                 s_axis_port3_tready,
    input  wire                                 s_axis_port3_tlast,

    //port4
    output wire [AXIS_DATA_WIDTH-1:0]           m_axis_port4_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]           m_axis_port4_tkeep,
    output wire                                 m_axis_port4_tvalid,
    input  wire                                 m_axis_port4_tready,
    output wire                                 m_axis_port4_tlast,

    input  wire [AXIS_DATA_WIDTH-1:0]           s_axis_port4_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]           s_axis_port4_tkeep,
    input  wire                                 s_axis_port4_tvalid,
    output wire                                 s_axis_port4_tready,
    input  wire                                 s_axis_port4_tlast
    );

    //s_axis
    wire [AXIS_DATA_WIDTH*IF_COUNT-1:0] s_axis_tdata = {s_axis_port4_tdata,s_axis_port3_tdata,s_axis_port2_tdata,s_axis_port1_tdata};
    wire [AXIS_KEEP_WIDTH*IF_COUNT-1:0] s_axis_tkeep = {s_axis_port4_tkeep,s_axis_port3_tkeep,s_axis_port2_tkeep,s_axis_port1_tkeep};
    wire [IF_COUNT-1:0] s_axis_tvalid = {s_axis_port4_tvalid,s_axis_port3_tvalid,s_axis_port2_tvalid,s_axis_port1_tvalid};
    wire [IF_COUNT-1:0] s_axis_tlast = {s_axis_port4_tlast,s_axis_port3_tlast,s_axis_port2_tlast,s_axis_port1_tlast};

    wire [IF_COUNT-1:0] s_axis_tready;
    assign s_axis_port1_tready = s_axis_tready[0];
    assign s_axis_port2_tready = s_axis_tready[1];
    assign s_axis_port3_tready = s_axis_tready[2];
    assign s_axis_port4_tready = s_axis_tready[3];

    //m_axis
    wire [AXIS_DATA_WIDTH*IF_COUNT-1:0] m_axis_tdata;
    assign m_axis_port1_tdata = m_axis_tdata[AXIS_DATA_WIDTH-1:0];
    assign m_axis_port2_tdata = m_axis_tdata[AXIS_DATA_WIDTH*2-1-:AXIS_DATA_WIDTH];
    assign m_axis_port3_tdata = m_axis_tdata[AXIS_DATA_WIDTH*3-1-:AXIS_DATA_WIDTH];
    assign m_axis_port4_tdata = m_axis_tdata[AXIS_DATA_WIDTH*4-1-:AXIS_DATA_WIDTH];
    wire [AXIS_KEEP_WIDTH*IF_COUNT-1:0] m_axis_tkeep;
    assign m_axis_port1_tkeep = m_axis_tkeep[AXIS_KEEP_WIDTH-1:0];
    assign m_axis_port2_tkeep = m_axis_tkeep[AXIS_KEEP_WIDTH*2-1-:AXIS_KEEP_WIDTH];
    assign m_axis_port3_tkeep = m_axis_tkeep[AXIS_KEEP_WIDTH*3-1-:AXIS_KEEP_WIDTH];
    assign m_axis_port4_tkeep = m_axis_tkeep[AXIS_KEEP_WIDTH*4-1-:AXIS_KEEP_WIDTH];
    wire [IF_COUNT-1:0] m_axis_tvalid;
    assign m_axis_port1_tvalid = m_axis_tvalid[0];
    assign m_axis_port2_tvalid = m_axis_tvalid[1];
    assign m_axis_port3_tvalid = m_axis_tvalid[2];
    assign m_axis_port4_tvalid = m_axis_tvalid[3];
    wire [IF_COUNT-1:0] m_axis_tlast;
    assign m_axis_port1_tlast = m_axis_tlast[0];
    assign m_axis_port2_tlast = m_axis_tlast[1];
    assign m_axis_port3_tlast = m_axis_tlast[2];
    assign m_axis_port4_tlast = m_axis_tlast[3];

    wire [IF_COUNT-1:0] m_axis_tready = {m_axis_port4_tready,m_axis_port3_tready,m_axis_port2_tready,m_axis_port1_tready};

    mqnic_app_block#(
    .PORT_COUNT_RX_DOWN(PORT_COUNT_RX_DOWN),
    .PORT_COUNT_TX_DOWN(PORT_COUNT_TX_DOWN),

    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

    .AXIL_APP_CTRL_DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
    .AXIL_APP_CTRL_ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),
    .AXIL_APP_CTRL_STRB_WIDTH(AXIL_APP_CTRL_STRB_WIDTH),

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
    .DROP(DROP),
    .TCAM_INIT(TCAM_INIT),

    .TCAM_ADDR_WIDTH(TCAM_ADDR_WIDTH),
    .TCAM_KEY_WIDTH(TCAM_KEY_WIDTH),
    .TCAM_DATA_WIDTH(TCAM_DATA_WIDTH),
    .TCAM_MASK_DISABLE(TCAM_MASK_DISABLE),
    .TCAM_RAM_STYLE(TCAM_RAM_STYLE),

    .PACKET_SCHEDULING_ENABLE_DOWN(PACKET_SCHEDULING_ENABLE_DOWN),
    .PACKET_SCHEDULING_ENABLE_UP(PACKET_SCHEDULING_ENABLE_UP),

    .N_FIFO(N_FIFO),
    
    .FIFO0_DEPTH(FIFO0_DEPTH),
    .FIFO1_DEPTH(FIFO1_DEPTH),
    .FIFO2_DEPTH(FIFO2_DEPTH),

    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_KEEP_ENABLE(FIFO_KEEP_ENABLE),
    .FIFO_KEEP_WIDTH(FIFO_KEEP_WIDTH),
    .FIFO_LAST_ENABLE(FIFO_LAST_ENABLE),
    .FIFO_ID_ENABLE(FIFO_ID_ENABLE),
    .FIFO_ID_WIDTH(FIFO_ID_WIDTH),
    .FIFO_DEST_ENABLE(FIFO_DEST_ENABLE),
    .FIFO_DEST_WIDTH(FIFO_DEST_WIDTH),
    .FIFO_USER_ENABLE(FIFO_USER_ENABLE),
    .FIFO_USER_WIDTH(FIFO_USER_WIDTH),
    .FIFO_RAM_PIPELINE(FIFO_RAM_PIPELINE),
    .FIFO_OUTPUT_FIFO_ENABLE(FIFO_OUTPUT_FIFO_ENABLE),
    .FIFO_FRAME_FIFO(FIFO_FRAME_FIFO),
    .FIFO_USER_BAD_FRAME_VALUE(FIFO_USER_BAD_FRAME_VALUE),
    .FIFO_USER_BAD_FRAME_MASK(FIFO_USER_BAD_FRAME_MASK),
    .FIFO_DROP_OVERSIZE_FRAME(FIFO_DROP_OVERSIZE_FRAME),
    .FIFO_DROP_BAD_FRAME(FIFO_DROP_BAD_FRAME),
    .FIFO_DROP_WHEN_FULL(FIFO_DROP_WHEN_FULL),
    .FIFO_MARK_WHEN_FULL(FIFO_MARK_WHEN_FULL),
    .FIFO_PAUSE_ENABLE(FIFO_PAUSE_ENABLE),
    .FIFO_FRAME_PAUSE(FIFO_FRAME_PAUSE)
    )
    mqnic_app_block_scheduler_inst(
    .clk(clk),
    .rst(rst),

    .m_axis_if_tx_tdata     (m_axis_tdata),
    .m_axis_if_tx_tkeep     (m_axis_tkeep),
    .m_axis_if_tx_tvalid    (m_axis_tvalid),
    .m_axis_if_tx_tready    (m_axis_tready),
    .m_axis_if_tx_tlast     (m_axis_tlast),

    .s_axis_if_rx_tdata     (s_axis_tdata),
    .s_axis_if_rx_tkeep     (s_axis_tkeep),
    .s_axis_if_rx_tvalid    (s_axis_tvalid),
    .s_axis_if_rx_tready    (s_axis_tready),
    .s_axis_if_rx_tlast     (s_axis_tlast)
    );
    endmodule