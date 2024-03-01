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

    // wire demultiplexeur/multiplexeur

    wire [AXIS_DATA_WIDTH-1:0] w_axis_demultiplexeur_multiplexeur_tdata;

    wire [AXIS_DATA_WIDTH-1:0] w_axis_demultiplexeur_parser_tdata;

    //wire axis_dp_multiplexeur/parser
    wire [AXIS_DATA_WIDTH-1:0] w_axis_parser_multiplexeur_tdata;

    //wire parser/deparser
    wire [COUNT_META_DATA_MAX*AXIS_DATA_WIDTH -1:0] w_meta_tdata;

    //wire parser/mat

        // Ethernet
    wire [47:0] w_parsed_Mac_dest;
    wire        w_valid_parsed_Mac_dest;
    wire [47:0] w_parsed_Mac_src;
    wire        w_valid_parsed_Mac_src;
    wire [15:0] w_parsed_ethtype;
    wire        w_valid_parsed_ethtype;

        // IPv4
    wire [7:0]  w_parsed_IHL;
    wire        w_valid_parsed_IHL;
    wire [5:0]  w_parsed_DSCP;
    wire        w_valid_parsed_DSCP;
    wire [1:0]  w_parsed_ECN;
    wire        w_valid_parsed_ECN;
    wire [15:0] w_parsed_Length;
    wire        w_valid_parsed_Length;
    wire [15:0] w_parsed_Identifiant;
    wire        w_valid_parsed_Identifiant;
    wire [15:0] w_parsed_Flags_FragmentOffset;
    wire        w_valid_parsed_Flags_FragmentOffset;
    wire [7:0]  w_parsed_TTL;
    wire        w_valid_parsed_TTL;
    wire [7:0]  w_parsed_Protocol;
    wire        w_valid_parsed_Protocol;
    wire [15:0] w_parsed_HeaderChecksum;
    wire        w_valid_parsed_HeaderChecksum;
    wire [31:0] w_parsed_src_Ipv4;
    wire        w_valid_parsed_src_Ipv4;
    wire [31:0] w_parsed_dest_Ipv4;
    wire        w_valid_parsed_dest_Ipv4;

    // wire FSM_dp_orchestrator_inst/others
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

    buffer_parser_packet_dispatcher #(
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    
    .COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
    .COUNTER_WIDTH(COUNTER_WIDTH),

    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP)
    )
    buffer_parser_packet_dispatcher_inst
    (
        .clk(clk),

        .state(w_state),
        .count(w_count),

        .s_axis_parser_tdata(w_axis_demultiplexeur_parser_tdata),

        .m_axis_parser_tdata(w_axis_parser_multiplexeur_tdata),

        .parsed_Mac_dest(w_parsed_Mac_dest),
        .valid_parsed_Mac_dest(w_valid_parsed_Mac_dest),
        .parsed_Mac_src(w_parsed_Mac_src),
        .valid_parsed_Mac_src(w_valid_parsed_Mac_src),
        .parsed_ethtype(w_parsed_ethtype),
        .valid_parsed_ethtype(w_valid_parsed_ethtype),

        .parsed_IHL(w_parsed_IHL),
        .valid_parsed_IHL(w_valid_parsed_IHL),
        .parsed_DSCP(w_parsed_DSCP),
        .valid_parsed_DSCP(w_valid_parsed_DSCP),
        .parsed_ECN(w_parsed_ECN),
        .valid_parsed_ECN(w_valid_parsed_ECN),
        .parsed_Length(w_parsed_Length),
        .valid_parsed_Length(w_valid_parsed_Length),
        .parsed_Identifiant(w_parsed_Identifiant),
        .valid_parsed_Identifiant(w_valid_parsed_Identifiant),
        .parsed_Flags_FragmentOffset(w_parsed_Flags_FragmentOffset),
        .valid_parsed_Flags_FragmentOffset(w_valid_parsed_Flags_FragmentOffset),
        .parsed_TTL(w_parsed_TTL),
        .valid_parsed_TTL(w_valid_parsed_TTL),
        .parsed_Protocol(w_parsed_Protocol),
        .valid_parsed_Protocol(w_valid_parsed_Protocol),
        .parsed_HeaderChecksum(w_parsed_HeaderChecksum),
        .valid_parsed_HeaderChecksum(w_valid_parsed_HeaderChecksum),
        .parsed_src_Ipv4(w_parsed_src_Ipv4),
        .valid_parsed_src_Ipv4(w_valid_parsed_src_Ipv4),
        .parsed_dest_Ipv4(w_parsed_dest_Ipv4),
        .valid_parsed_dest_Ipv4(w_valid_parsed_dest_Ipv4)
    );

    mat_packet_dispatcher #(
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

    mat_packet_dispatcher_inst
    (
        .clk(clk),
        .rst(rst),

        .state(w_state),

        .parsed_Mac_dest(w_parsed_Mac_dest),
        .valid_parsed_Mac_dest(w_valid_parsed_Mac_dest),
        .parsed_Mac_src(w_parsed_Mac_src),
        .valid_parsed_Mac_src(w_valid_parsed_Mac_src),
        .parsed_ethtype(w_parsed_ethtype),
        .valid_parsed_ethtype(w_valid_parsed_ethtype),

        .parsed_IHL(w_parsed_IHL),
        .valid_parsed_IHL(w_valid_parsed_IHL),
        .parsed_DSCP(w_parsed_DSCP),
        .valid_parsed_DSCP(w_valid_parsed_DSCP),
        .parsed_ECN(w_parsed_ECN),
        .valid_parsed_ECN(w_valid_parsed_ECN),
        .parsed_Length(w_parsed_Length),
        .valid_parsed_Length(w_valid_parsed_Length),
        .parsed_Identifiant(w_parsed_Identifiant),
        .valid_parsed_Identifiant(w_valid_parsed_Identifiant),
        .parsed_Flags_FragmentOffset(w_parsed_Flags_FragmentOffset),
        .valid_parsed_Flags_FragmentOffset(w_valid_parsed_Flags_FragmentOffset),
        .parsed_TTL(w_parsed_TTL),
        .valid_parsed_TTL(w_valid_parsed_TTL),
        .parsed_Protocol(w_parsed_Protocol),
        .valid_parsed_Protocol(w_valid_parsed_Protocol),
        .parsed_HeaderChecksum(w_parsed_HeaderChecksum),
        .valid_parsed_HeaderChecksum(w_valid_parsed_HeaderChecksum),
        .parsed_src_Ipv4(w_parsed_src_Ipv4),
        .valid_parsed_src_Ipv4(w_valid_parsed_src_Ipv4),
        .parsed_dest_Ipv4(w_parsed_dest_Ipv4),
        .valid_parsed_dest_Ipv4(w_valid_parsed_dest_Ipv4),

        .drop(w_drop),

        .configurable_ipv4_address(w_configurable_ipv4_address),

        .m_axis_mat_tdest(m_axis_top_packet_dispatcher_tdest)

    );

    FSM_packet_dispatcher #(
    .COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
    .COUNTER_WIDTH(COUNTER_WIDTH),

    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP),

    .AXIL_APP_CTRL_DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
    .AXIL_APP_CTRL_ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),
    .AXIL_APP_CTRL_STRB_WIDTH(AXIL_APP_CTRL_STRB_WIDTH)
    )
    FSM_packet_dispatcher_inst(

        .clk(clk),
        .rst(rst),

        .s_axis_FSM_tlast(s_axis_top_packet_dispatcher_tlast),
        .s_axis_FSM_tvalid(s_axis_top_packet_dispatcher_tvalid),
        .s_axis_FSM_tready(s_axis_top_packet_dispatcher_tready),
        .s_axis_FSM_tkeep(s_axis_top_packet_dispatcher_tkeep),

        .m_axis_FSM_tlast(m_axis_top_packet_dispatcher_tlast),
        .m_axis_FSM_tvalid(m_axis_top_packet_dispatcher_tvalid),
        .m_axis_FSM_tready(m_axis_top_packet_dispatcher_tready),
        .m_axis_FSM_tkeep(m_axis_top_packet_dispatcher_tkeep),

        .drop(w_drop),

        .state(w_state),
        .count(w_count),

        .enable_dp(w_enable_dp),
        .rst_drop_counter(w_rst_drop_counter),

        .reg_drop_counter(w_drop_counter)
    );
endmodule
