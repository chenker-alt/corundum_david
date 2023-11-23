module top_heartbeat #(
//axi streaming interface
parameter IF_COUNT = 1,
parameter AXIS_DATA_WIDTH = 512,
parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
parameter AXIS_USER_WIDTH = 1,
parameter AXIS_ID_WIDTH = 1,
parameter AXIS_DEST_WIDTH = 1,

//clock_counters
parameter CLK_FREQ = 250_000_000,

parameter X_MS_HEARTBEAT1 = 1,
parameter COUNTER_WIDTH_HEARTBEAT1 = 32,
parameter COUNTER_MAX_HEARTBEAT1 = (X_MS_HEARTBEAT1 * CLK_FREQ) / 10000,

parameter X_MS_HEARTBEAT2 = 2,
parameter COUNTER_WIDTH_HEARTBEAT2 = 32,
parameter COUNTER_MAX_HEARTBEAT2 = (X_MS_HEARTBEAT2 * CLK_FREQ) / 10000,

parameter X_MS_HEARTBEAT3 = 3,
parameter COUNTER_WIDTH_HEARTBEAT3 = 32,
parameter COUNTER_MAX_HEARTBEAT3 = (X_MS_HEARTBEAT3 * CLK_FREQ) / 10000,

//packet generator
parameter PACKET_SIZE = 400,

parameter PAYLOAD_SIZE= 128,

parameter MAC_DEST = 48'hFFFFFFFFFFFF,
parameter MAC_SRC = 48'h001122334455,
parameter ETH_TYPE = 16'h0800,
parameter IHL = 8'h45,
parameter DSCP = 6'h00,
parameter ECN = 2'h00,
parameter LENGTH = 16'h0024,
parameter IDENTIFIANT = 16'h0001,
parameter FLAGS_FRAGMENT_OFFSET = 16'h0000,
parameter TTL = 8'h40,
parameter PROTOCOL = 8'h00,
parameter HEADER_CHECKSUM = 16'h1099,
parameter SRC_IPV4 = 32'hAC110914,
parameter DEST_IPV4 = 32'hAC11090A,

parameter PAYLOAD_heartbeat1 = 128'h68656C6C6F2068656172746265617431,
parameter PAYLOAD_heartbeat2 = 128'h68656C6C6F2068656172746265617432,
parameter PAYLOAD_heartbeat3 = 128'h68656C6C6F2068656172746265617433
)
(
input wire clk,
input wire rst,

input wire [IF_COUNT*AXIS_DATA_WIDTH-1:0]        s_axis_top_heartbeat_tdata,
input wire [IF_COUNT*AXIS_KEEP_WIDTH-1:0]        s_axis_top_heartbeat_tkeep,
input wire [IF_COUNT-1:0]                        s_axis_top_heartbeat_tvalid,
input wire [IF_COUNT-1:0]                        m_axis_top_heartbeat_tready,
input wire [IF_COUNT-1:0]                        s_axis_top_heartbeat_tlast,
input wire [IF_COUNT*AXIS_USER_WIDTH-1:0]     s_axis_top_heartbeat_tuser,
input wire [IF_COUNT*AXIS_ID_WIDTH-1:0]       s_axis_top_heartbeat_tid,
input wire [IF_COUNT*AXIS_DEST_WIDTH-1:0]     s_axis_top_heartbeat_tdest,

output wire  [AXIS_DATA_WIDTH-1:0]                m_axis_top_heartbeat_tdata,
output wire  [AXIS_KEEP_WIDTH-1:0]                m_axis_top_heartbeat_tkeep,
output wire  [IF_COUNT-1:0]                       m_axis_top_heartbeat_tvalid,
output wire  [IF_COUNT-1:0]                       s_axis_top_heartbeat_tready,
output wire  [IF_COUNT-1:0]                       m_axis_top_heartbeat_tlast,
output wire  [AXIS_USER_WIDTH-1:0]             m_axis_top_heartbeat_tuser,
output wire  [AXIS_ID_WIDTH-1:0]               m_axis_top_heartbeat_tid,
output wire  [AXIS_DEST_WIDTH-1:0]             m_axis_top_heartbeat_tdest

);
//wire simple_crontroller SFP/axis_multiplexeur
wire [AXIS_DATA_WIDTH-1:0]      axis_simple_controller_SFP_axis_multiplexeur_tdata;
wire [AXIS_KEEP_WIDTH-1:0]      axis_simple_controller_SFP_axis_multiplexeur_tkeep;
wire [IF_COUNT-1:0]             axis_simple_controller_SFP_axis_multiplexeur_tvalid;
wire [IF_COUNT-1:0]             axis_simple_controller_SFP_axis_multiplexeur_tready;
wire [IF_COUNT-1:0]             axis_simple_controller_SFP_axis_multiplexeur_tlast;
wire [AXIS_USER_WIDTH-1:0]   axis_simple_controller_SFP_axis_multiplexeur_tuser;
wire [AXIS_ID_WIDTH-1:0]     axis_simple_controller_SFP_axis_multiplexeur_tid;
wire [AXIS_DEST_WIDTH-1:0]   axis_simple_controller_SFP_axis_multiplexeur_tdest;

//wire simple_crontroller heartbeat1/axis_multiplexeur
wire [AXIS_DATA_WIDTH-1:0]      axis_simple_controller_heartbeat1_axis_multiplexeur_tdata;
wire [AXIS_KEEP_WIDTH-1:0]      axis_simple_controller_heartbeat1_axis_multiplexeur_tkeep;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat1_axis_multiplexeur_tvalid;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat1_axis_multiplexeur_tready;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat1_axis_multiplexeur_tlast;
wire [AXIS_USER_WIDTH-1:0]   axis_simple_controller_heartbeat1_axis_multiplexeur_tuser;
wire [AXIS_ID_WIDTH-1:0]     axis_simple_controller_heartbeat1_axis_multiplexeur_tid;
wire [AXIS_DEST_WIDTH-1:0]   axis_simple_controller_heartbeat1_axis_multiplexeur_tdest;

//wire simple_crontroller heartbeat2/axis_multiplexeur
wire [AXIS_DATA_WIDTH-1:0]      axis_simple_controller_heartbeat2_axis_multiplexeur_tdata;
wire [AXIS_KEEP_WIDTH-1:0]      axis_simple_controller_heartbeat2_axis_multiplexeur_tkeep;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat2_axis_multiplexeur_tvalid;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat2_axis_multiplexeur_tready;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat2_axis_multiplexeur_tlast;
wire [AXIS_USER_WIDTH-1:0]   axis_simple_controller_heartbeat2_axis_multiplexeur_tuser;
wire [AXIS_ID_WIDTH-1:0]     axis_simple_controller_heartbeat2_axis_multiplexeur_tid;
wire [AXIS_DEST_WIDTH-1:0]   axis_simple_controller_heartbeat2_axis_multiplexeur_tdest;
//wire simple_crontroller heartbeat3/axis_multiplexeur
wire [AXIS_DATA_WIDTH-1:0]      axis_simple_controller_heartbeat3_axis_multiplexeur_tdata;
wire [AXIS_KEEP_WIDTH-1:0]      axis_simple_controller_heartbeat3_axis_multiplexeur_tkeep;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat3_axis_multiplexeur_tvalid;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat3_axis_multiplexeur_tready;
wire [IF_COUNT-1:0]             axis_simple_controller_heartbeat3_axis_multiplexeur_tlast;
wire [AXIS_USER_WIDTH-1:0]   axis_simple_controller_heartbeat3_axis_multiplexeur_tuser;
wire [AXIS_ID_WIDTH-1:0]     axis_simple_controller_heartbeat3_axis_multiplexeur_tid;
wire [AXIS_DEST_WIDTH-1:0]   axis_simple_controller_heartbeat3_axis_multiplexeur_tdest;

//wire simple_crontroller SFP/arbiter
wire grant_SFP;

//wire simple_crontroller heartbeat1/arbiter
wire grant_heartbeat1;

//wire simple_crontroller heartbeat2/arbiter
wire grant_heartbeat2;

//wire simple_crontroller heartbeat3/arbiter
wire grant_heartbeat3;

//wire simple_crontroller axis_multiplexeur/arbiter
wire [IF_COUNT-1:0] axis_axis_multiplexeur_arbiter_tlast;

//wire simple_crontroller/Packet_generator heartbeat1
wire [AXIS_DATA_WIDTH-1:0]      axis_simple_controller_Packet_generator_heartbeat1_tdata;
wire [AXIS_KEEP_WIDTH-1:0]      axis_simple_controller_Packet_generator_heartbeat1_tkeep;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat1_tvalid;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat1_tready;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat1_tlast;
wire [AXIS_USER_WIDTH-1:0]   axis_simple_controller_Packet_generator_heartbeat1_tuser;
wire [AXIS_ID_WIDTH-1:0]     axis_simple_controller_Packet_generator_heartbeat1_tid;
wire [AXIS_DEST_WIDTH-1:0]   axis_simple_controller_Packet_generator_heartbeat1_tdest;

//wire simple_crontroller/Packet_generator heartbeat2
wire [AXIS_DATA_WIDTH-1:0]      axis_simple_controller_Packet_generator_heartbeat2_tdata;
wire [AXIS_KEEP_WIDTH-1:0]      axis_simple_controller_Packet_generator_heartbeat2_tkeep;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat2_tvalid;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat2_tready;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat2_tlast;
wire [AXIS_USER_WIDTH-1:0]   axis_simple_controller_Packet_generator_heartbeat2_tuser;
wire [AXIS_ID_WIDTH-1:0]     axis_simple_controller_Packet_generator_heartbeat2_tid;
wire [AXIS_DEST_WIDTH-1:0]   axis_simple_controller_Packet_generator_heartbeat2_tdest;

//wire simple_crontroller/Packet_generator heartbeat3
wire [AXIS_DATA_WIDTH-1:0]      axis_simple_controller_Packet_generator_heartbeat3_tdata;
wire [AXIS_KEEP_WIDTH-1:0]      axis_simple_controller_Packet_generator_heartbeat3_tkeep;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat3_tvalid;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat3_tready;
wire [IF_COUNT-1:0]             axis_simple_controller_Packet_generator_heartbeat3_tlast;
wire [AXIS_USER_WIDTH-1:0]   axis_simple_controller_Packet_generator_heartbeat3_tuser;
wire [AXIS_ID_WIDTH-1:0]     axis_simple_controller_Packet_generator_heartbeat3_tid;
wire [AXIS_DEST_WIDTH-1:0]   axis_simple_controller_Packet_generator_heartbeat3_tdest;

axis_simple_controller #(
.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
)
axis_simple_controller_SFP
(
.clk(clk),
.rst(rst),

.s_axis_simple_controller_tdata(s_axis_top_heartbeat_tdata),
.s_axis_simple_controller_tkeep(s_axis_top_heartbeat_tkeep),
.s_axis_simple_controller_tvalid(s_axis_top_heartbeat_tvalid),
.s_axis_simple_controller_tready(s_axis_top_heartbeat_tready),
.s_axis_simple_controller_tlast(s_axis_top_heartbeat_tlast),
.s_axis_simple_controller_tuser(s_axis_top_heartbeat_tuser),
.s_axis_simple_controller_tid(s_axis_top_heartbeat_tid),
.s_axis_simple_controller_tdest(s_axis_top_heartbeat_tdest),

.m_axis_simple_controller_tdata(axis_simple_controller_SFP_axis_multiplexeur_tdata),
.m_axis_simple_controller_tkeep(axis_simple_controller_SFP_axis_multiplexeur_tkeep),
.m_axis_simple_controller_tvalid(axis_simple_controller_SFP_axis_multiplexeur_tvalid),
.m_axis_simple_controller_tready(axis_simple_controller_SFP_axis_multiplexeur_tready),
.m_axis_simple_controller_tlast(axis_simple_controller_SFP_axis_multiplexeur_tlast),
.m_axis_simple_controller_tuser(axis_simple_controller_SFP_axis_multiplexeur_tuser),
.m_axis_simple_controller_tid(axis_simple_controller_SFP_axis_multiplexeur_tid),
.m_axis_simple_controller_tdest(axis_simple_controller_SFP_axis_multiplexeur_tdest),

.grant(grant_SFP)
);

axis_simple_controller #(
.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
)
axis_simple_controller_heartbeat1(
.clk(clk),
.rst(rst),

.s_axis_simple_controller_tdata(axis_simple_controller_Packet_generator_heartbeat1_tdata),
.s_axis_simple_controller_tkeep(axis_simple_controller_Packet_generator_heartbeat1_tkeep),
.s_axis_simple_controller_tvalid(axis_simple_controller_Packet_generator_heartbeat1_tvalid),
.s_axis_simple_controller_tready(axis_simple_controller_Packet_generator_heartbeat1_tready),
.s_axis_simple_controller_tlast(axis_simple_controller_Packet_generator_heartbeat1_tlast),
.s_axis_simple_controller_tuser(axis_simple_controller_Packet_generator_heartbeat1_tuser),
.s_axis_simple_controller_tid(axis_simple_controller_Packet_generator_heartbeat1_tid),
.s_axis_simple_controller_tdest(axis_simple_controller_Packet_generator_heartbeat1_tdest),

.m_axis_simple_controller_tdata(axis_simple_controller_heartbeat1_axis_multiplexeur_tdata),
.m_axis_simple_controller_tkeep(axis_simple_controller_heartbeat1_axis_multiplexeur_tkeep),
.m_axis_simple_controller_tvalid(axis_simple_controller_heartbeat1_axis_multiplexeur_tvalid),
.m_axis_simple_controller_tready(axis_simple_controller_heartbeat1_axis_multiplexeur_tready),
.m_axis_simple_controller_tlast(axis_simple_controller_heartbeat1_axis_multiplexeur_tlast),
.m_axis_simple_controller_tuser(axis_simple_controller_heartbeat1_axis_multiplexeur_tuser),
.m_axis_simple_controller_tid(axis_simple_controller_heartbeat1_axis_multiplexeur_tid),
.m_axis_simple_controller_tdest(axis_simple_controller_heartbeat1_axis_multiplexeur_tdest),

.grant(grant_heartbeat1)
);
axis_simple_controller #(
.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
)
axis_simple_controller_heartbeat2
(
.clk(clk),
.rst(rst),

.s_axis_simple_controller_tdata(axis_simple_controller_Packet_generator_heartbeat2_tdata),
.s_axis_simple_controller_tkeep(axis_simple_controller_Packet_generator_heartbeat2_tkeep),
.s_axis_simple_controller_tvalid(axis_simple_controller_Packet_generator_heartbeat2_tvalid),
.s_axis_simple_controller_tready(axis_simple_controller_Packet_generator_heartbeat2_tready),
.s_axis_simple_controller_tlast(axis_simple_controller_Packet_generator_heartbeat2_tlast),
.s_axis_simple_controller_tuser(axis_simple_controller_Packet_generator_heartbeat2_tuser),
.s_axis_simple_controller_tid(axis_simple_controller_Packet_generator_heartbeat2_tid),
.s_axis_simple_controller_tdest(axis_simple_controller_Packet_generator_heartbeat2_tdest),

.m_axis_simple_controller_tdata(axis_simple_controller_heartbeat2_axis_multiplexeur_tdata),
.m_axis_simple_controller_tkeep(axis_simple_controller_heartbeat2_axis_multiplexeur_tkeep),
.m_axis_simple_controller_tvalid(axis_simple_controller_heartbeat2_axis_multiplexeur_tvalid),
.m_axis_simple_controller_tready(axis_simple_controller_heartbeat2_axis_multiplexeur_tready),
.m_axis_simple_controller_tlast(axis_simple_controller_heartbeat2_axis_multiplexeur_tlast),
.m_axis_simple_controller_tuser(axis_simple_controller_heartbeat2_axis_multiplexeur_tuser),
.m_axis_simple_controller_tid(axis_simple_controller_heartbeat2_axis_multiplexeur_tid),
.m_axis_simple_controller_tdest(axis_simple_controller_heartbeat2_axis_multiplexeur_tdest),

.grant(grant_heartbeat2)
);
axis_simple_controller #(
.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
)
axis_simple_controller_heartbeat3
(
.clk(clk),
.rst(rst),

.s_axis_simple_controller_tdata(axis_simple_controller_Packet_generator_heartbeat3_tdata),
.s_axis_simple_controller_tkeep(axis_simple_controller_Packet_generator_heartbeat3_tkeep),
.s_axis_simple_controller_tvalid(axis_simple_controller_Packet_generator_heartbeat3_tvalid),
.s_axis_simple_controller_tready(axis_simple_controller_Packet_generator_heartbeat3_tready),
.s_axis_simple_controller_tlast(axis_simple_controller_Packet_generator_heartbeat3_tlast),
.s_axis_simple_controller_tuser(axis_simple_controller_Packet_generator_heartbeat3_tuser),
.s_axis_simple_controller_tid(axis_simple_controller_Packet_generator_heartbeat3_tid),
.s_axis_simple_controller_tdest(axis_simple_controller_Packet_generator_heartbeat3_tdest),

.m_axis_simple_controller_tdata(axis_simple_controller_heartbeat3_axis_multiplexeur_tdata),
.m_axis_simple_controller_tkeep(axis_simple_controller_heartbeat3_axis_multiplexeur_tkeep),
.m_axis_simple_controller_tvalid(axis_simple_controller_heartbeat3_axis_multiplexeur_tvalid),
.m_axis_simple_controller_tready(axis_simple_controller_heartbeat3_axis_multiplexeur_tready),
.m_axis_simple_controller_tlast(axis_simple_controller_heartbeat3_axis_multiplexeur_tlast),
.m_axis_simple_controller_tuser(axis_simple_controller_heartbeat3_axis_multiplexeur_tuser),
.m_axis_simple_controller_tid(axis_simple_controller_heartbeat3_axis_multiplexeur_tid),
.m_axis_simple_controller_tdest(axis_simple_controller_heartbeat3_axis_multiplexeur_tdest),

.grant(grant_heartbeat3)
);

axis_multiplexeur #(
.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
)

axis_multiplexeur(

// output    
.m_axis_mux_tdata           (m_axis_top_heartbeat_tdata),
.m_axis_mux_tkeep           (m_axis_top_heartbeat_tkeep),
.m_axis_mux_tvalid          (m_axis_top_heartbeat_tvalid),
.m_axis_mux_tready          (m_axis_top_heartbeat_tready),
.m_axis_mux_tlast           (m_axis_top_heartbeat_tlast),
.m_axis_mux_tuser           (m_axis_top_heartbeat_tuser),
.m_axis_mux_tid             (m_axis_top_heartbeat_tid),
.m_axis_mux_tdest           (m_axis_top_heartbeat_tdest),

//  SFP
.grant_SFP                  (grant_SFP),

.s_axis_SFP_tdata           (axis_simple_controller_SFP_axis_multiplexeur_tdata),
.s_axis_SFP_tkeep           (axis_simple_controller_SFP_axis_multiplexeur_tkeep),
.s_axis_SFP_tvalid          (axis_simple_controller_SFP_axis_multiplexeur_tvalid),
.s_axis_SFP_tready          (axis_simple_controller_SFP_axis_multiplexeur_tready),
.s_axis_SFP_tlast           (axis_simple_controller_SFP_axis_multiplexeur_tlast),
.s_axis_SFP_tuser           (axis_simple_controller_SFP_axis_multiplexeur_tuser),
.s_axis_SFP_tid             (axis_simple_controller_SFP_axis_multiplexeur_tid),
.s_axis_SFP_tdest           (axis_simple_controller_SFP_axis_multiplexeur_tdest), 

//  heartbeat 1
.grant_heartbeat1           (grant_heartbeat1),

.s_axis_heartbeat1_tdata    (axis_simple_controller_heartbeat1_axis_multiplexeur_tdata),
.s_axis_heartbeat1_tkeep    (axis_simple_controller_heartbeat1_axis_multiplexeur_tkeep),
.s_axis_heartbeat1_tvalid   (axis_simple_controller_heartbeat1_axis_multiplexeur_tvalid),
.s_axis_heartbeat1_tready   (axis_simple_controller_heartbeat1_axis_multiplexeur_tready),
.s_axis_heartbeat1_tlast    (axis_simple_controller_heartbeat1_axis_multiplexeur_tlast),
.s_axis_heartbeat1_tuser    (axis_simple_controller_heartbeat1_axis_multiplexeur_tuser),
.s_axis_heartbeat1_tid      (axis_simple_controller_heartbeat1_axis_multiplexeur_tid),
.s_axis_heartbeat1_tdest    (axis_simple_controller_heartbeat1_axis_multiplexeur_tdest), 

//  heartbeat 2
.grant_heartbeat2           (grant_heartbeat2),

.s_axis_heartbeat2_tdata    (axis_simple_controller_heartbeat2_axis_multiplexeur_tdata),
.s_axis_heartbeat2_tkeep    (axis_simple_controller_heartbeat2_axis_multiplexeur_tkeep),
.s_axis_heartbeat2_tvalid   (axis_simple_controller_heartbeat2_axis_multiplexeur_tvalid),
.s_axis_heartbeat2_tready   (axis_simple_controller_heartbeat2_axis_multiplexeur_tready),
.s_axis_heartbeat2_tlast    (axis_simple_controller_heartbeat2_axis_multiplexeur_tlast),
.s_axis_heartbeat2_tuser    (axis_simple_controller_heartbeat2_axis_multiplexeur_tuser),
.s_axis_heartbeat2_tid      (axis_simple_controller_heartbeat2_axis_multiplexeur_tid),
.s_axis_heartbeat2_tdest    (axis_simple_controller_heartbeat2_axis_multiplexeur_tdest),

//  heartbeat 3
.grant_heartbeat3           (grant_heartbeat3),

.s_axis_heartbeat3_tdata    (axis_simple_controller_heartbeat3_axis_multiplexeur_tdata),
.s_axis_heartbeat3_tkeep    (axis_simple_controller_heartbeat3_axis_multiplexeur_tkeep),
.s_axis_heartbeat3_tvalid   (axis_simple_controller_heartbeat3_axis_multiplexeur_tvalid),
.s_axis_heartbeat3_tready   (axis_simple_controller_heartbeat3_axis_multiplexeur_tready),
.s_axis_heartbeat3_tlast    (axis_simple_controller_heartbeat3_axis_multiplexeur_tlast),
.s_axis_heartbeat3_tuser    (axis_simple_controller_heartbeat3_axis_multiplexeur_tuser),
.s_axis_heartbeat3_tid      (axis_simple_controller_heartbeat3_axis_multiplexeur_tid),
.s_axis_heartbeat3_tdest    (axis_simple_controller_heartbeat3_axis_multiplexeur_tdest) 

);

//arbiter
arbiter_module arbiter_inst(
.clk(clk),
.rst(rst),

.s_axis_arbiter_tlast(m_axis_top_heartbeat_tlast),

.handshake_heartbeat1(handshake_heartbeat1),
.handshake_heartbeat2(handshake_heartbeat2),
.handshake_heartbeat3(handshake_heartbeat3),
.handshake_SFP(s_axis_top_heartbeat_tvalid),

.grant_SFP(grant_SFP),
.grant_heartbeat1(grant_heartbeat1),
.grant_heartbeat2(grant_heartbeat2),
.grant_heartbeat3(grant_heartbeat3)
);

//clock counters
clock_counter #(
.COUNTER_MAX(COUNTER_MAX_HEARTBEAT1)
)
clock_counter_heartbeat1_inst
(
.clk(clk),
.rst(rst),

.handshake(handshake_heartbeat1),
.grant(grant_heartbeat1)
);

clock_counter #(
.COUNTER_MAX(COUNTER_MAX_HEARTBEAT2)
)
clock_counter_heartbeat2_inst
(
.clk(clk),
.rst(rst),

.handshake(handshake_heartbeat2),
.grant(grant_heartbeat2)
);

clock_counter #(
.COUNTER_MAX(COUNTER_MAX_HEARTBEAT3)
)
clock_counter_heartbeat3_inst
(
.clk(clk),
.rst(rst),

.handshake(handshake_heartbeat3),
.grant(grant_heartbeat3)
);

//packet generator
packet_generator #(
.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

.PACKET_SIZE(PACKET_SIZE),
.PAYLOAD_SIZE(PAYLOAD_SIZE),

.MAC_DEST(MAC_DEST),
.MAC_SRC(MAC_SRC),
.ETH_TYPE(ETH_TYPE),
.IHL(IHL),
.DSCP(DSCP),
.ECN(ECN),
.LENGTH(LENGTH),
.IDENTIFIANT(IDENTIFIANT),
.FLAGS_FRAGMENT_OFFSET(FLAGS_FRAGMENT_OFFSET),
.TTL(TTL),
.PROTOCOL(PROTOCOL),
.HEADER_CHECKSUM(HEADER_CHECKSUM),
.SRC_IPV4(SRC_IPV4),
.DEST_IPV4(DEST_IPV4),
.PAYLOAD(PAYLOAD_heartbeat1)
)

packet_generator_heartbeat1_inst(
.clk(clk),
.rst(rst),

.m_axis_top_packet_generator_tdata(axis_simple_controller_Packet_generator_heartbeat1_tdata),
.m_axis_top_packet_generator_tkeep(axis_simple_controller_Packet_generator_heartbeat1_tkeep),
.m_axis_top_packet_generator_tvalid(axis_simple_controller_Packet_generator_heartbeat1_tvalid),
.m_axis_top_packet_generator_tready(axis_simple_controller_Packet_generator_heartbeat1_tready),
.m_axis_top_packet_generator_tlast(axis_simple_controller_Packet_generator_heartbeat1_tlast),
.m_axis_top_packet_generator_tuser(axis_simple_controller_Packet_generator_heartbeat1_tuser),
.m_axis_top_packet_generator_tid(axis_simple_controller_Packet_generator_heartbeat1_tid),
.m_axis_top_packet_generator_tdest(axis_simple_controller_Packet_generator_heartbeat1_tdest)
);

packet_generator #(
.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

.PACKET_SIZE(PACKET_SIZE),
.PAYLOAD_SIZE(PAYLOAD_SIZE),

.MAC_DEST(MAC_DEST),
.MAC_SRC(MAC_SRC),
.ETH_TYPE(ETH_TYPE),
.IHL(IHL),
.DSCP(DSCP),
.ECN(ECN),
.LENGTH(LENGTH),
.IDENTIFIANT(IDENTIFIANT),
.FLAGS_FRAGMENT_OFFSET(FLAGS_FRAGMENT_OFFSET),
.TTL(TTL),
.PROTOCOL(PROTOCOL),
.HEADER_CHECKSUM(HEADER_CHECKSUM),
.SRC_IPV4(SRC_IPV4),
.DEST_IPV4(DEST_IPV4),
.PAYLOAD(PAYLOAD_heartbeat2)
)
packet_generator_heartbeat2_inst(

.clk(clk),
.rst(rst),

.m_axis_top_packet_generator_tdata(axis_simple_controller_Packet_generator_heartbeat2_tdata),
.m_axis_top_packet_generator_tkeep(axis_simple_controller_Packet_generator_heartbeat2_tkeep),
.m_axis_top_packet_generator_tvalid(axis_simple_controller_Packet_generator_heartbeat2_tvalid),
.m_axis_top_packet_generator_tready(axis_simple_controller_Packet_generator_heartbeat2_tready),
.m_axis_top_packet_generator_tlast(axis_simple_controller_Packet_generator_heartbeat2_tlast),
.m_axis_top_packet_generator_tuser(axis_simple_controller_Packet_generator_heartbeat2_tuser),
.m_axis_top_packet_generator_tid(axis_simple_controller_Packet_generator_heartbeat2_tid),
.m_axis_top_packet_generator_tdest(axis_simple_controller_Packet_generator_heartbeat2_tdest)
);

packet_generator #(

.IF_COUNT(IF_COUNT),
.AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
.AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
.AXIS_USER_WIDTH(AXIS_USER_WIDTH),
.AXIS_ID_WIDTH(AXIS_ID_WIDTH),
.AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

.PACKET_SIZE(PACKET_SIZE),
.PAYLOAD_SIZE(PAYLOAD_SIZE),

.MAC_DEST(MAC_DEST),
.MAC_SRC(MAC_SRC),
.ETH_TYPE(ETH_TYPE),
.IHL(IHL),
.DSCP(DSCP),
.ECN(ECN),
.LENGTH(LENGTH),
.IDENTIFIANT(IDENTIFIANT),
.FLAGS_FRAGMENT_OFFSET(FLAGS_FRAGMENT_OFFSET),
.TTL(TTL),
.PROTOCOL(PROTOCOL),
.HEADER_CHECKSUM(HEADER_CHECKSUM),
.SRC_IPV4(SRC_IPV4),
.DEST_IPV4(DEST_IPV4),
.PAYLOAD(PAYLOAD_heartbeat3)
)

packet_generator_heartbeat3_inst(

.clk(clk),
.rst(rst),

.m_axis_top_packet_generator_tdata(axis_simple_controller_Packet_generator_heartbeat3_tdata),
.m_axis_top_packet_generator_tkeep(axis_simple_controller_Packet_generator_heartbeat3_tkeep),
.m_axis_top_packet_generator_tvalid(axis_simple_controller_Packet_generator_heartbeat3_tvalid),
.m_axis_top_packet_generator_tready(axis_simple_controller_Packet_generator_heartbeat3_tready),
.m_axis_top_packet_generator_tlast(axis_simple_controller_Packet_generator_heartbeat3_tlast),
.m_axis_top_packet_generator_tuser(axis_simple_controller_Packet_generator_heartbeat3_tuser),
.m_axis_top_packet_generator_tid(axis_simple_controller_Packet_generator_heartbeat3_tid),
.m_axis_top_packet_generator_tdest(axis_simple_controller_Packet_generator_heartbeat3_tdest)
);

endmodule