module top_scheduler#(
    // Ethernet interface configuration
    parameter PORT_COUNT_RX= 3,
    parameter PORT_COUNT_TX = 1,

    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 3,

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
    parameter FIFO_FRAME_PAUSE = FIFO_FRAME_FIFO,
    
     ///////////Switch//////////
    parameter S_COUNT=PORT_COUNT_RX,
    parameter M_COUNT=N_FIFO,
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
    parameter ARB_LSB_HIGH_PRIORITY=1
)
(
    // System (internal at interface module)
    input wire clk,
    input wire rst,

    /*
     * Ethernet (internal at interface module)
     */
    input wire  [PORT_COUNT_RX*AXIS_DATA_WIDTH-1:0]  s_axis_top_scheduler_tdata,
    input wire  [PORT_COUNT_RX*AXIS_KEEP_WIDTH-1:0]  s_axis_top_scheduler_tkeep,
    input wire  [PORT_COUNT_RX-1:0]                  s_axis_top_scheduler_tvalid,
    output wire [PORT_COUNT_RX-1:0]                  s_axis_top_scheduler_tready,
    input wire  [PORT_COUNT_RX-1:0]                  s_axis_top_scheduler_tlast,

    output wire [PORT_COUNT_TX*AXIS_DATA_WIDTH-1:0]  m_axis_top_scheduler_tdata,
    output wire [PORT_COUNT_TX*AXIS_KEEP_WIDTH-1:0]  m_axis_top_scheduler_tkeep,
    output wire [PORT_COUNT_TX-1:0]                  m_axis_top_scheduler_tvalid,
    input wire  [PORT_COUNT_TX-1:0]                  m_axis_top_scheduler_tready,
    output wire [PORT_COUNT_TX-1:0]                  m_axis_top_scheduler_tlast,

    /*
     * AXI-Lite input/output
     */

    input wire w_enable_dp,
    input wire [32-1:0]w_configurable_ipv4_address,
    input wire w_rst_drop_counter,
    output wire [PORT_COUNT_RX*32-1:0] w_drop_counter

);
    wire [PORT_COUNT_RX*AXIS_DATA_WIDTH-1:0] w_axis_packet_dispatcher_switch_tdata;
    wire [PORT_COUNT_RX*AXIS_KEEP_WIDTH -1:0] w_axis_packet_dispatcher_switch_tkeep;
    wire [PORT_COUNT_RX-1:0] w_axis_packet_dispatcher_switch_tvalid;
    wire [PORT_COUNT_RX-1:0] w_axis_packet_dispatcher_switch_tready;
    wire [PORT_COUNT_RX-1:0] w_axis_packet_dispatcher_switch_tlast;
    wire [PORT_COUNT_RX*AXIS_DEST_WIDTH-1:0] w_axis_packet_dispatcher_switch_tdest;

    genvar i;
    generate
        for (i = 0; i < PORT_COUNT_RX; i = i + 1) begin : gen_packet_dispatchers

            top_packet_dispatcher #(
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
            .TCAM_INIT(TCAM_INIT)
            
            ) top_packet_dispatcher_inst (
                .clk(clk),
                .rst(rst),

                .s_axis_top_packet_dispatcher_tdata(s_axis_top_scheduler_tdata[AXIS_DATA_WIDTH+AXIS_DATA_WIDTH*i-1-:AXIS_DATA_WIDTH]),
                .s_axis_top_packet_dispatcher_tkeep(s_axis_top_scheduler_tkeep[AXIS_KEEP_WIDTH+AXIS_KEEP_WIDTH*i-1-:AXIS_KEEP_WIDTH]),
                .s_axis_top_packet_dispatcher_tvalid(s_axis_top_scheduler_tvalid[i]),
                .s_axis_top_packet_dispatcher_tready(s_axis_top_scheduler_tready[i]),
                .s_axis_top_packet_dispatcher_tlast(s_axis_top_scheduler_tlast[i]),

                .m_axis_top_packet_dispatcher_tdata(w_axis_packet_dispatcher_switch_tdata[AXIS_DATA_WIDTH+AXIS_DATA_WIDTH*i-1-:AXIS_DATA_WIDTH]),
                .m_axis_top_packet_dispatcher_tkeep(w_axis_packet_dispatcher_switch_tkeep[AXIS_KEEP_WIDTH+AXIS_KEEP_WIDTH*i-1-:AXIS_KEEP_WIDTH]),
                .m_axis_top_packet_dispatcher_tvalid(w_axis_packet_dispatcher_switch_tvalid[i]),
                .m_axis_top_packet_dispatcher_tready(w_axis_packet_dispatcher_switch_tready[i]),
                .m_axis_top_packet_dispatcher_tlast(w_axis_packet_dispatcher_switch_tlast[i]),
                .m_axis_top_packet_dispatcher_tdest(w_axis_packet_dispatcher_switch_tdest[AXIS_DEST_WIDTH+AXIS_DEST_WIDTH*i-1-:AXIS_DEST_WIDTH]),

                .w_enable_dp(w_enable_dp),
                .w_configurable_ipv4_address(w_configurable_ipv4_address),
                .w_rst_drop_counter(w_rst_drop_counter),
                .w_drop_counter(w_drop_counter[32+32*i-1-:32])
            );
        end
    endgenerate

    generate 
    if (PACKET_SCHEDULING_ENABLE) begin : SCHED_EN

        wire [PORT_COUNT_RX*AXIS_DATA_WIDTH-1:0]     w_axis_switch_FIFO_tdata;
        wire [PORT_COUNT_RX*AXIS_KEEP_WIDTH -1:0]    w_axis_switch_FIFO_tkeep;
        wire [PORT_COUNT_RX-1:0]                     w_axis_switch_FIFO_tvalid;
        wire [PORT_COUNT_RX-1:0]                     w_axis_switch_FIFO_tready;
        wire [PORT_COUNT_RX-1:0]                     w_axis_switch_FIFO_tlast;
        wire [PORT_COUNT_RX*AXIS_DEST_WIDTH-1:0]     w_axis_switch_FIFO_tdest;

        axis_switch #(
        .S_COUNT(S_COUNT),
        .M_COUNT(M_COUNT),
        .DATA_WIDTH(AXIS_DATA_WIDTH),
        .KEEP_ENABLE(AXIS_DATA_WIDTH>8),
        .KEEP_WIDTH(AXIS_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH),
        .M_DEST_WIDTH(AXIS_DEST_WIDTH),
        .S_DEST_WIDTH(AXIS_DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .M_BASE(M_BASE),
        .M_TOP(M_TOP),
        .M_CONNECT(M_CONNECT),
        .UPDATE_TID(UPDATE_TID),
        .S_REG_TYPE(S_REG_TYPE),
        .M_REG_TYPE(M_REG_TYPE),
        .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
        .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
        )
        axis_switch_inst (

            .clk(clk),
            .rst(rst),

            .s_axis_tdata(w_axis_packet_dispatcher_switch_tdata),
            .s_axis_tkeep(w_axis_packet_dispatcher_switch_tkeep),
            .s_axis_tvalid(w_axis_packet_dispatcher_switch_tvalid),
            .s_axis_tready(w_axis_packet_dispatcher_switch_tready),
            .s_axis_tlast(w_axis_packet_dispatcher_switch_tlast),
            .s_axis_tdest(w_axis_packet_dispatcher_switch_tdest),

            .m_axis_tdata(w_axis_switch_FIFO_tdata),
            .m_axis_tkeep(w_axis_switch_FIFO_tkeep),
            .m_axis_tvalid(w_axis_switch_FIFO_tvalid),
            .m_axis_tready(w_axis_switch_FIFO_tready),
            .m_axis_tlast(w_axis_switch_FIFO_tlast)

        );
        
        top_priority_FIFO #(
        .PORT_COUNT_RX(PORT_COUNT_RX),
        .PORT_COUNT_TX(PORT_COUNT_TX),
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

        .PACKET_SCHEDULING_ENABLE(PACKET_SCHEDULING_ENABLE),

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
        top_priority_FIFO_inst(
            .clk(clk),
            .rst(rst),

            .s_axis_priority_fifo_tdata(w_axis_switch_FIFO_tdata),
            .s_axis_priority_fifo_tkeep(w_axis_switch_FIFO_tkeep),
            .s_axis_priority_fifo_tvalid(w_axis_switch_FIFO_tvalid),
            .s_axis_priority_fifo_tready(w_axis_switch_FIFO_tready),
            .s_axis_priority_fifo_tlast(w_axis_switch_FIFO_tlast),

            .m_axis_priority_fifo_tdata(m_axis_top_scheduler_tdata),
            .m_axis_priority_fifo_tkeep(m_axis_top_scheduler_tkeep),
            .m_axis_priority_fifo_tvalid(m_axis_top_scheduler_tvalid),
            .m_axis_priority_fifo_tready(m_axis_top_scheduler_tready),
            .m_axis_priority_fifo_tlast(m_axis_top_scheduler_tlast)
        );
    end else begin
        axis_switch #(
        .S_COUNT(S_COUNT),
        .M_COUNT(M_COUNT),
        .DATA_WIDTH(AXIS_DATA_WIDTH),
        .KEEP_ENABLE(AXIS_DATA_WIDTH>8),
        .KEEP_WIDTH(AXIS_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH),
        .M_DEST_WIDTH(AXIS_DEST_WIDTH),
        .S_DEST_WIDTH(AXIS_DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .M_BASE(M_BASE),
        .M_TOP(M_TOP),
        .M_CONNECT(M_CONNECT),
        .UPDATE_TID(UPDATE_TID),
        .S_REG_TYPE(S_REG_TYPE),
        .M_REG_TYPE(M_REG_TYPE),
        .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
        .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
        )
        axis_switch_inst (

            .clk(clk),
            .rst(rst),

            .s_axis_tdata(w_axis_packet_dispatcher_switch_tdata),
            .s_axis_tkeep(w_axis_packet_dispatcher_switch_tkeep),
            .s_axis_tvalid(w_axis_packet_dispatcher_switch_tvalid),
            .s_axis_tready(w_axis_packet_dispatcher_switch_tready),
            .s_axis_tlast(w_axis_packet_dispatcher_switch_tlast),
            .s_axis_tdest(w_axis_packet_dispatcher_switch_tdest),

            .m_axis_tdata(m_axis_top_scheduler_tdata),
            .m_axis_tkeep(m_axis_top_scheduler_tkeep),
            .m_axis_tvalid(m_axis_top_scheduler_tvalid),
            .m_axis_tready(m_axis_top_scheduler_tready),
            .m_axis_tlast(m_axis_top_scheduler_tlast)

        );
    end
    endgenerate
    
endmodule
