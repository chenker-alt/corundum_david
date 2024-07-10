module top_dp_simple_fw #(
parameter IF_COUNT = 1,
parameter DATA_WIDTH = 64,
parameter KEEP_WIDTH = DATA_WIDTH/8,
parameter ID_WIDTH =1,
parameter DEST_WIDTH = 9,
parameter USER_WIDTH = 97,

parameter META_DATA_WIDTH_MAX=272,
parameter COUNT_META_DATA_MAX=(META_DATA_WIDTH_MAX/DATA_WIDTH)+1,
parameter COUNTER_WIDTH= $clog2(COUNT_META_DATA_MAX+1),

parameter IDLE                  = 0,
parameter PARSE_DATA            = 1,
parameter CONTROL               = 2,
parameter SEND_ANALYSED_DATA    = 3,
parameter SEND_REMAIN           = 4,
parameter DROP                  = 5
)
(
input wire clk,
input wire rst,

input wire [IF_COUNT*DATA_WIDTH-1:0]   s_axis_dp_top_tdata,
input wire [IF_COUNT*KEEP_WIDTH-1:0]   s_axis_dp_top_tkeep,
input wire [IF_COUNT-1:0]              s_axis_dp_top_tvalid,
input wire [IF_COUNT-1:0]              m_axis_dp_top_tready,
input wire [IF_COUNT-1:0]              s_axis_dp_top_tlast,
input wire [IF_COUNT*USER_WIDTH-1:0]   s_axis_dp_top_tuser,
input wire [IF_COUNT*ID_WIDTH-1:0]     s_axis_dp_top_tid,
input wire [IF_COUNT*DEST_WIDTH-1:0]   s_axis_dp_top_tdest,

output wire  [DATA_WIDTH-1:0]          m_axis_dp_top_tdata,
output wire  [KEEP_WIDTH-1:0]          m_axis_dp_top_tkeep,
output wire  [IF_COUNT-1:0]            m_axis_dp_top_tvalid,
output wire  [IF_COUNT-1:0]            s_axis_dp_top_tready,
output wire  [IF_COUNT-1:0]            m_axis_dp_top_tlast,
output wire  [USER_WIDTH-1:0]          m_axis_dp_top_tuser,
output wire  [ID_WIDTH-1:0]            m_axis_dp_top_tid,
output wire  [DEST_WIDTH-1:0]          m_axis_dp_top_tdest

);
// wire demultiplexeur/multiplexeur

wire [IF_COUNT*DATA_WIDTH-1:0] w_axis_demultiplexeur_multiplexeur_tdata;
wire [IF_COUNT*KEEP_WIDTH-1:0] w_axis_demultiplexeur_multiplexeur_tkeep;
wire [IF_COUNT*USER_WIDTH-1:0] w_axis_demultiplexeur_multiplexeur_tuser;
wire [IF_COUNT*ID_WIDTH-1:0]   w_axis_demultiplexeur_multiplexeur_tid;
wire [IF_COUNT*DEST_WIDTH-1:0] w_axis_demultiplexeur_multiplexeur_tdest;

wire [IF_COUNT*DATA_WIDTH-1:0] w_axis_demultiplexeur_parser_tdata;
wire [IF_COUNT*KEEP_WIDTH-1:0] w_axis_demultiplexeur_parser_tkeep;
wire [IF_COUNT*USER_WIDTH-1:0] w_axis_demultiplexeur_parser_tuser;
wire [IF_COUNT*ID_WIDTH-1:0]   w_axis_demultiplexeur_parser_tid;
wire [IF_COUNT*DEST_WIDTH-1:0] w_axis_demultiplexeur_parser_tdest;

//wire axis_dp_multiplexeur/deparser
wire [IF_COUNT*DATA_WIDTH-1:0] w_axis_deparser_multiplexeur_tdata;
wire [IF_COUNT*KEEP_WIDTH-1:0] w_axis_deparser_multiplexeur_tkeep;
wire [IF_COUNT*USER_WIDTH-1:0] w_axis_deparser_multiplexeur_tuser;
wire [IF_COUNT*ID_WIDTH-1:0] w_axis_deparser_multiplexeur_tid;
wire [IF_COUNT*DEST_WIDTH-1:0] w_axis_deparser_multiplexeur_tdest;

//wire parser/deparser
wire [COUNT_META_DATA_MAX*DATA_WIDTH -1:0] w_reg_meta_tdata;
wire [COUNT_META_DATA_MAX*KEEP_WIDTH -1:0] w_reg_meta_tkeep;
wire [COUNT_META_DATA_MAX*USER_WIDTH -1:0] w_reg_meta_tuser;
wire [COUNT_META_DATA_MAX*ID_WIDTH -1:0] w_reg_meta_tid;
wire [COUNT_META_DATA_MAX*DEST_WIDTH -1:0] w_reg_meta_tdest;

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

// wire mat/deparser
wire [47:0] w_deparsed_Mac_dest;
wire [47:0] w_deparsed_Mac_src;
wire [15:0] w_deparsed_ethtype;

wire [7:0]  w_deparsed_IHL;
wire [5:0]  w_deparsed_DSCP;
wire [1:0]  w_deparsed_ECN;
wire [15:0] w_deparsed_Length;
wire [15:0] w_deparsed_Identifiant;
wire [15:0] w_deparsed_Flags_FragmentOffset;
wire [7:0]  w_deparsed_TTL;
wire [7:0]  w_deparsed_Protocol;
wire [15:0] w_deparsed_HeaderChecksum;
wire [31:0] w_deparsed_src_Ipv4;
wire [31:0] w_deparsed_dest_Ipv4;

// Fils pour les connexions entre FSM_dp_orchestrator_inst et les autres modules
wire [2:0] w_state;
wire [COUNTER_WIDTH-1:0] w_count;

axis_dp_demultiplexeur #(
.IF_COUNT(IF_COUNT),
.DATA_WIDTH(DATA_WIDTH),
.KEEP_WIDTH(KEEP_WIDTH),
.USER_WIDTH(USER_WIDTH),
.ID_WIDTH(ID_WIDTH),
.DEST_WIDTH(DEST_WIDTH),

.IDLE(IDLE),
.PARSE_DATA(PARSE_DATA),
.CONTROL(CONTROL),
.SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
.SEND_REMAIN(SEND_REMAIN),
.DROP(DROP)
)

axis_dp_demultiplexeur_inst
(
.state(w_state),

.s_axis_dp_top_tdata(s_axis_dp_top_tdata),
.s_axis_dp_top_tkeep(s_axis_dp_top_tkeep),
.s_axis_dp_top_tuser(s_axis_dp_top_tuser),
.s_axis_dp_top_tid(s_axis_dp_top_tid),
.s_axis_dp_top_tdest(s_axis_dp_top_tdest),

.m_axis_direct_source_tdata(w_axis_demultiplexeur_multiplexeur_tdata),
.m_axis_direct_source_tkeep(w_axis_demultiplexeur_multiplexeur_tkeep),
.m_axis_direct_source_tuser(w_axis_demultiplexeur_multiplexeur_tuser),
.m_axis_direct_source_tid(w_axis_demultiplexeur_multiplexeur_tid),
.m_axis_direct_source_tdest(w_axis_demultiplexeur_multiplexeur_tdest),

.m_axis_parser_tdata(w_axis_demultiplexeur_parser_tdata),
.m_axis_parser_tkeep(w_axis_demultiplexeur_parser_tkeep),
.m_axis_parser_tuser(w_axis_demultiplexeur_parser_tuser),
.m_axis_parser_tid(w_axis_demultiplexeur_parser_tid),
.m_axis_parser_tdest(w_axis_demultiplexeur_parser_tdest)

);

axis_dp_multiplexeur #(
.IF_COUNT(IF_COUNT),
.DATA_WIDTH(DATA_WIDTH),
.KEEP_WIDTH(KEEP_WIDTH),
.USER_WIDTH(USER_WIDTH),
.ID_WIDTH(ID_WIDTH),
.DEST_WIDTH(DEST_WIDTH),

.IDLE(IDLE),
.PARSE_DATA(PARSE_DATA),
.CONTROL(CONTROL),
.SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
.SEND_REMAIN(SEND_REMAIN),
.DROP(DROP)
)
axis_dp_multiplexeur_inst(
.state(w_state),

.m_axis_dp_top_tdata(m_axis_dp_top_tdata),
.m_axis_dp_top_tkeep(m_axis_dp_top_tkeep),
.m_axis_dp_top_tuser(m_axis_dp_top_tuser),
.m_axis_dp_top_tid(m_axis_dp_top_tid),
.m_axis_dp_top_tdest(m_axis_dp_top_tdest),

.s_axis_direct_source_tdata(w_axis_demultiplexeur_multiplexeur_tdata),
.s_axis_direct_source_tkeep(w_axis_demultiplexeur_multiplexeur_tkeep),
.s_axis_direct_source_tuser(w_axis_demultiplexeur_multiplexeur_tuser),
.s_axis_direct_source_tid(w_axis_demultiplexeur_multiplexeur_tid),
.s_axis_direct_source_tdest(w_axis_demultiplexeur_multiplexeur_tdest),

.s_axis_deparser_tdata(w_axis_deparser_multiplexeur_tdata),
.s_axis_deparser_tkeep(w_axis_deparser_multiplexeur_tkeep),
.s_axis_deparser_tuser(w_axis_deparser_multiplexeur_tuser),
.s_axis_deparser_tid(w_axis_deparser_multiplexeur_tid),
.s_axis_deparser_tdest(w_axis_deparser_multiplexeur_tdest)
);

parser #(
.IF_COUNT(IF_COUNT),
.DATA_WIDTH(DATA_WIDTH),
.KEEP_WIDTH(KEEP_WIDTH),
.USER_WIDTH(USER_WIDTH),
.ID_WIDTH(ID_WIDTH),
.DEST_WIDTH(DEST_WIDTH),

.COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
.COUNTER_WIDTH(COUNTER_WIDTH),

.IDLE(IDLE),
.PARSE_DATA(PARSE_DATA),
.CONTROL(CONTROL),
.SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
.SEND_REMAIN(SEND_REMAIN),
.DROP(DROP)
)
parser_inst
(
.clk(clk),

.state(w_state),
.count(w_count),

.s_axis_parser_tdata(w_axis_demultiplexeur_parser_tdata),
.s_axis_parser_tkeep(w_axis_demultiplexeur_parser_tkeep),
.s_axis_parser_tuser(w_axis_demultiplexeur_parser_tuser),
.s_axis_parser_tid(w_axis_demultiplexeur_parser_tid),
.s_axis_parser_tdest(w_axis_demultiplexeur_parser_tdest),

.reg_meta_tdata(w_reg_meta_tdata),
.reg_meta_tkeep(w_reg_meta_tkeep),
.reg_meta_tuser(w_reg_meta_tuser),
.reg_meta_tid(w_reg_meta_tid),
.reg_meta_tdest(w_reg_meta_tdest),

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
mat #(
.IDLE(IDLE),
.PARSE_DATA(PARSE_DATA),
.CONTROL(CONTROL),
.SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
.SEND_REMAIN(SEND_REMAIN),
.DROP(DROP)
)
mat_inst
(
.clk(clk),

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

.deparsed_Mac_dest(w_deparsed_Mac_dest),
.deparsed_Mac_src(w_deparsed_Mac_src),
.deparsed_ethtype(w_deparsed_ethtype),

.deparsed_IHL(w_deparsed_IHL),
.deparsed_DSCP(w_deparsed_DSCP),
.deparsed_ECN(w_deparsed_ECN),
.deparsed_Length(w_deparsed_Length),
.deparsed_Identifiant(w_deparsed_Identifiant),
.deparsed_Flags_FragmentOffset(w_deparsed_Flags_FragmentOffset),
.deparsed_TTL(w_deparsed_TTL),
.deparsed_Protocol(w_deparsed_Protocol),
.deparsed_HeaderChecksum(w_deparsed_HeaderChecksum),
.deparsed_src_Ipv4(w_deparsed_src_Ipv4),
.deparsed_dest_Ipv4(w_deparsed_dest_Ipv4)
);

deparser #(
.IF_COUNT(IF_COUNT),
.DATA_WIDTH(DATA_WIDTH),
.KEEP_WIDTH(KEEP_WIDTH),
.USER_WIDTH(USER_WIDTH),
.ID_WIDTH(ID_WIDTH),
.DEST_WIDTH(DEST_WIDTH),

.COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
.COUNTER_WIDTH(COUNTER_WIDTH),

.IDLE(IDLE),
.PARSE_DATA(PARSE_DATA),
.CONTROL(CONTROL),
.SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
.SEND_REMAIN(SEND_REMAIN),
.DROP(DROP)
)

deparser_inst(
.clk(clk),

.state(w_state),
.count(w_count),

.deparsed_Mac_dest(w_deparsed_Mac_dest),
.deparsed_Mac_src(w_deparsed_Mac_src),
.deparsed_ethtype(w_deparsed_ethtype),
.deparsed_IHL(w_deparsed_IHL),
.deparsed_DSCP(w_deparsed_DSCP),
.deparsed_ECN(w_deparsed_ECN),
.deparsed_Length(w_deparsed_Length),
.deparsed_Identifiant(w_deparsed_Identifiant),
.deparsed_Flags_FragmentOffset(w_deparsed_Flags_FragmentOffset),
.deparsed_TTL(w_deparsed_TTL),
.deparsed_Protocol(w_deparsed_Protocol),
.deparsed_HeaderChecksum(w_deparsed_HeaderChecksum),
.deparsed_src_Ipv4(w_deparsed_src_Ipv4),
.deparsed_dest_Ipv4(w_deparsed_dest_Ipv4),

.reg_meta_tdata(w_reg_meta_tdata),
.reg_meta_tkeep(w_reg_meta_tkeep),
.reg_meta_tuser(w_reg_meta_tuser),
.reg_meta_tid(w_reg_meta_tid),
.reg_meta_tdest(w_reg_meta_tdest),

.m_axis_deparser_tdata(w_axis_deparser_multiplexeur_tdata),
.m_axis_deparser_tkeep(w_axis_deparser_multiplexeur_tkeep),
.m_axis_deparser_tuser(w_axis_deparser_multiplexeur_tuser),
.m_axis_deparser_tid(w_axis_deparser_multiplexeur_tid),
.m_axis_deparser_tdest(w_axis_deparser_multiplexeur_tdest)
);

FSM_dp_orchestrator #(
.DATA_WIDTH(DATA_WIDTH),

.COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
.COUNTER_WIDTH(COUNTER_WIDTH),

.IDLE(IDLE),
.PARSE_DATA(PARSE_DATA),
.CONTROL(CONTROL),
.SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
.SEND_REMAIN(SEND_REMAIN),
.DROP(DROP)
)
FSM_dp_orchestrator_inst(

.clk(clk),
.rst(rst),

.s_axis_dp_top_tlast(s_axis_dp_top_tlast),
.s_axis_dp_top_tvalid(s_axis_dp_top_tvalid),
.s_axis_dp_top_tready(s_axis_dp_top_tready),

.m_axis_dp_top_tlast(m_axis_dp_top_tlast),
.m_axis_dp_top_tvalid(m_axis_dp_top_tvalid),
.m_axis_dp_top_tready(m_axis_dp_top_tready),

.drop(w_drop),

.out_state(w_state),
.out_count(w_count)
);
endmodule
