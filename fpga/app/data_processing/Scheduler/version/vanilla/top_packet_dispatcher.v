module top_packet_dispatcher #(
    // Ethernet interface configuration
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2,

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // Parser/Mat/deparser configuration
    parameter META_DATA_WIDTH_MAX=128,
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
    parameter TCAM_KEY_WIDTH =META_DATA_WIDTH_MAX,
    parameter TCAM_DATA_WIDTH=4,
    parameter TCAM_MASK_DISABLE=0,
    parameter TCAM_RAM_STYLE="block"
)
(
    // System (internal at interface module)
    input wire clk,
    input wire rst,

    /*
     * Ethernet (internal at interface module)
     */
    input wire [AXIS_DATA_WIDTH-1:0]    s_axis_top_packet_dispatcher_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0]    s_axis_top_packet_dispatcher_tkeep,
    input wire                          s_axis_top_packet_dispatcher_tvalid,
    input wire                          m_axis_top_packet_dispatcher_tready,
    input wire                          s_axis_top_packet_dispatcher_tlast,

    output wire  [AXIS_DATA_WIDTH-1:0]  m_axis_top_packet_dispatcher_tdata,
    output wire  [AXIS_KEEP_WIDTH-1:0]  m_axis_top_packet_dispatcher_tkeep,
    output wire                         m_axis_top_packet_dispatcher_tvalid,
    output wire                         s_axis_top_packet_dispatcher_tready,
    output wire                         m_axis_top_packet_dispatcher_tlast,
    output wire  [AXIS_DEST_WIDTH-1:0]  m_axis_top_packet_dispatcher_tdest,

    input wire w_enable_dp,
    input wire [32-1:0] w_configurable_ipv4_address,
    input wire w_rst_drop_counter,
    output wire [32-1:0] w_drop_counter
);

    //IP header byte configuration
    localparam IP_HEADER_OFFSET = 14 * 8;  // IP header starts at byte 14
    localparam LENGTH_FIELD_OFFSET = IP_HEADER_OFFSET + 2 * 8; // Total Length field is at bytes 2-3 of IP header
    localparam PACKET_LENGTH_WIDTH = 16;

    // wire demultiplexeur/multiplexeur

    wire [AXIS_DATA_WIDTH-1:0] w_axis_demultiplexeur_multiplexeur_tdata;

    wire [AXIS_DATA_WIDTH-1:0] w_axis_demultiplexeur_parser_tdata;

    //wire axis_dp_multiplexeur/parser
    wire [AXIS_DATA_WIDTH-1:0] w_axis_parser_multiplexeur_tdata;

    //wire parser/TCAM
    wire [TCAM_KEY_WIDTH-1:0] w_tcam_req_key;

    //wire FSM/TCAM
    wire w_tcam_req_valid;
    wire w_tcam_req_ready;
    wire w_tcam_res_valid;
    wire w_tcam_res_null;
    wire [TCAM_DATA_WIDTH-1:0] w_tcam_res_data;

    wire w_end_init_tcam;

    // //wire AXIL/TCAM
    wire [TCAM_ADDR_WIDTH-1:0]  w_tcam_set_addr;
    wire [TCAM_DATA_WIDTH-1:0]  w_tcam_set_data;
    wire [TCAM_KEY_WIDTH-1:0]   w_tcam_set_key;
    wire [TCAM_KEY_WIDTH-1:0]   w_tcam_set_xmask;
    wire                        w_tcam_set_clear;
    wire                        w_tcam_set_valid;
    
    // wire FSM STATE
    wire [(STATE_WIDTH)-1:0] w_state;
    wire [(COUNTER_WIDTH)-1:0] w_count;

    //wire axil register interface
    
    wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]     w_reg_wr_addr;
    wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]     w_reg_wr_data;
    wire [AXIL_APP_CTRL_STRB_WIDTH-1:0]     w_reg_wr_strb;
    wire                                    w_reg_wr_en;
    wire                                    w_reg_wr_wait;
    wire                                    w_reg_wr_ack;
    wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]     w_reg_rd_addr;
    wire                                    w_reg_rd_en;
    wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]     w_reg_rd_data;
    wire                                    w_reg_rd_wait;
    wire                                    w_reg_rd_ack;

    axis_packet_dispatcher_demultiplexeur #(
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

    .STATE_WIDTH(STATE_WIDTH),

    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP)
    )

    axis_packet_dispatcher_demultiplexeur_inst
    (
    .state(w_state),

    .s_axis_demultiplexeur_tdata(s_axis_top_packet_dispatcher_tdata),

    .m_axis_demultiplexeur_to_multiplexeur_tdata(w_axis_demultiplexeur_multiplexeur_tdata),

    .m_axis_demultiplexeur_to_parser_tdata(w_axis_demultiplexeur_parser_tdata)

    );
    
    axis_packet_dispatcher_multiplexeur #(
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP)
    )
    axis_packet_dispatcher_multiplexeur_inst(
    .state(w_state),

    .m_axis_multiplexeur_tdata(m_axis_top_packet_dispatcher_tdata),
    
    .s_axis_demultiplexeur_to_multiplexeur_tdata(w_axis_demultiplexeur_multiplexeur_tdata),
    .s_axis_parser_to_multiplexeur_tdata(w_axis_parser_multiplexeur_tdata)   
    );

    buffer #(
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    
    .COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .BUFFER_DATA_WIDTH(BUFFER_DATA_WIDTH),
    .TCAM_KEY_WIDTH(TCAM_KEY_WIDTH),

    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP)
    )

    buffer_inst
    (
        .clk(clk),

        .state(w_state),
        .count(w_count),

        .s_axis_parser_tdata(w_axis_demultiplexeur_parser_tdata),

        .m_axis_parser_tdata(w_axis_parser_multiplexeur_tdata),

        .tcam_key(w_tcam_req_key)
    );

    FSM_packet_dispatcher #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
        .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

        .AXIL_APP_CTRL_DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
        .AXIL_APP_CTRL_ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),
        .AXIL_APP_CTRL_STRB_WIDTH(AXIL_APP_CTRL_STRB_WIDTH),

        .META_DATA_WIDTH_MAX(LENGTH_FIELD_OFFSET),
        .PACKET_LENGTH_WIDTH(PACKET_LENGTH_WIDTH),
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
    )
    FSM_packet_dispatcher_inst(
        .clk(clk),
        .rst(rst),

        .s_axis_FSM_tlast(s_axis_top_packet_dispatcher_tlast),
        .s_axis_FSM_tvalid(s_axis_top_packet_dispatcher_tvalid),
        .s_axis_FSM_tready(s_axis_top_packet_dispatcher_tready),
        .s_axis_FSM_tkeep(s_axis_top_packet_dispatcher_tkeep),
        .s_axis_FSM_tdata(s_axis_top_packet_dispatcher_tdata),

        .m_axis_FSM_tlast(m_axis_top_packet_dispatcher_tlast),
        .m_axis_FSM_tdest(m_axis_top_packet_dispatcher_tdest),
        .m_axis_FSM_tvalid(m_axis_top_packet_dispatcher_tvalid),
        .m_axis_FSM_tready(m_axis_top_packet_dispatcher_tready),
        .m_axis_FSM_tkeep(m_axis_top_packet_dispatcher_tkeep),

        .reg_tcam_req_valid(w_tcam_req_valid),
        .tcam_req_ready(w_tcam_req_ready),

        .state(w_state),
        .count(w_count),

        .enable_dp(w_enable_dp),
        .rst_drop_counter(w_rst_drop_counter),

        .reg_drop_counter(w_drop_counter),

        .tcam_res_valid(w_tcam_res_valid),
        .tcam_res_null(w_tcam_res_null),
        .tcam_res_data(w_tcam_res_data),

        .end_init_tcam(w_end_init_tcam)
    );

    // reg [TCAM_ADDR_WIDTH-1:0] w_tcam_set_addr=0;
    // reg [TCAM_DATA_WIDTH-1:0] w_tcam_set_data=0;
    // reg [TCAM_KEY_WIDTH-1:0] w_tcam_set_key=0;
    // reg [TCAM_KEY_WIDTH-1:0] w_tcam_set_xmask=0; 
    // reg w_tcam_set_clear=0;
    // reg w_tcam_set_valid=0;

    tcam #(
    .ADDR_WIDTH(TCAM_ADDR_WIDTH),
    .KEY_WIDTH(TCAM_KEY_WIDTH),
    .DATA_WIDTH(TCAM_DATA_WIDTH),
    .MASK_DISABLE(TCAM_MASK_DISABLE),
    .RAM_STYLE_DATA(TCAM_RAM_STYLE)

    )
    tcam_inst(
    .clk(clk),
    .rst(rst),

    .set_addr(w_tcam_set_addr),
    .set_data(w_tcam_set_data),
    .set_key(w_tcam_set_key),
    .set_xmask(w_tcam_set_xmask),
    .set_clr(w_tcam_set_clear),
    .set_valid(w_tcam_set_valid),

    .req_key(w_tcam_req_key),
    .req_valid(w_tcam_req_valid),
    .req_ready(w_tcam_req_ready),

    //.res_addr(),
    .res_data(w_tcam_res_data),
    .res_valid(w_tcam_res_valid),
    .res_null(w_tcam_res_null)
    );

    init_rst_tcam #(
    .TCAM_ADDR_WIDTH(TCAM_ADDR_WIDTH),
    .TCAM_KEY_WIDTH(TCAM_KEY_WIDTH),
    .TCAM_DATA_WIDTH(TCAM_DATA_WIDTH),
    .TCAM_MASK_DISABLE(TCAM_MASK_DISABLE),
    .TCAM_RAM_STYLE_DATA(TCAM_RAM_STYLE),
    
    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP),
    .TCAM_INIT(TCAM_INIT)
    )

    init_rst_tcam_inst(

    .clk(clk),
    .rst(rst),

    .state(w_state),

    .init_set_addr(w_tcam_set_addr),
	.init_set_data(w_tcam_set_data),
	.init_set_key(w_tcam_set_key),
	.init_set_xmask(w_tcam_set_xmask),
	.init_set_clr(w_tcam_set_clear),
	.init_set_valid(w_tcam_set_valid),

    .end_init_tcam(w_end_init_tcam)
    );

endmodule