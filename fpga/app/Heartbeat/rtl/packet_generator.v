module packet_generator #(
    parameter IF_COUNT = 1,
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_ID_WIDTH = 1,
    parameter AXIS_DEST_WIDTH = 9,
    parameter AXIS_USER_WIDTH = 97,

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
    parameter PAYLOAD = 128'h68656C6C6F2068656172746265617431
)
(
    input wire clk,
    input wire rst,

    output reg  [AXIS_DATA_WIDTH-1:0]             m_axis_top_packet_generator_tdata=0,
    output reg  [AXIS_KEEP_WIDTH-1:0]             m_axis_top_packet_generator_tkeep=0,
    output reg  [IF_COUNT-1:0]                    m_axis_top_packet_generator_tvalid=1,
    input wire  [IF_COUNT-1:0]                    m_axis_top_packet_generator_tready,
    output reg  [IF_COUNT-1:0]                    m_axis_top_packet_generator_tlast=0,
    output reg  [AXIS_USER_WIDTH-1:0]             m_axis_top_packet_generator_tuser=0,
    output reg  [AXIS_ID_WIDTH-1:0]               m_axis_top_packet_generator_tid=0,
    output reg  [AXIS_DEST_WIDTH-1:0]             m_axis_top_packet_generator_tdest=0
);
localparam AXIS_PACKET_WIDTH= ((PACKET_SIZE / AXIS_DATA_WIDTH) * AXIS_DATA_WIDTH) + ((PACKET_SIZE % AXIS_DATA_WIDTH) ? AXIS_DATA_WIDTH : 0);

    reg [47:0]  reg_mac_dest = MAC_DEST;
    reg [47:0]  reg_mac_src = MAC_SRC;
    reg [15:0]  reg_ethtype = ETH_TYPE;
    reg [7:0]   reg_IHL = IHL;
    reg [5:0]   reg_DSCP = DSCP;
    reg [1:0]   reg_ECN = ECN;
    reg [15:0]  reg_length = LENGTH;
    reg [15:0]  reg_identifiant = IDENTIFIANT;
    reg [15:0]  reg_flags_fragmentOffset = FLAGS_FRAGMENT_OFFSET;
    reg [7:0]   reg_TTL = TTL;
    reg [7:0]   reg_protocol = PROTOCOL;
    reg [15:0]  reg_header_checksum = HEADER_CHECKSUM;
    reg [31:0]  reg_src_ipv4 = SRC_IPV4;
    reg [31:0]  reg_dest_ipv4 = DEST_IPV4;
    reg [PAYLOAD_SIZE-1:0] reg_payload = PAYLOAD;


wire    [AXIS_PACKET_WIDTH - 1:0] packet;    
reg     [6:0] index=PACKET_SIZE/AXIS_DATA_WIDTH;
reg     [AXIS_PACKET_WIDTH-PACKET_SIZE-1:0] compl =0;

    function [63:0] reverse_bytes(input [63:0] data);
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                reverse_bytes[i*8 +: 8] = data[(7-i)*8 +: 8];
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            index <= PACKET_SIZE/AXIS_DATA_WIDTH;
        end else if (m_axis_top_packet_generator_tready && m_axis_top_packet_generator_tvalid) begin
            if (index == 0) begin
                index <= PACKET_SIZE/AXIS_DATA_WIDTH;
            end else begin
                index <= index - 1;
            end
        end
        m_axis_top_packet_generator_tdata <= reverse_bytes(packet[index*AXIS_DATA_WIDTH +: AXIS_DATA_WIDTH]);
        m_axis_top_packet_generator_tvalid <= 1'b1;
        m_axis_top_packet_generator_tlast <= (index == 0) ? 1'b1 : 1'b0;
        m_axis_top_packet_generator_tuser <= 0;
        m_axis_top_packet_generator_tid <= 0;
        m_axis_top_packet_generator_tdest <= 0;

    if (index == 0) begin
        m_axis_top_packet_generator_tkeep <= (1 << (PACKET_SIZE % AXIS_DATA_WIDTH)/8) - 1;
    end else begin
        m_axis_top_packet_generator_tkeep <= {AXIS_KEEP_WIDTH{1'b1}};
    end
    end

assign packet = ({reg_mac_dest, reg_mac_src, reg_ethtype, reg_IHL, reg_DSCP, reg_ECN,
reg_length, reg_identifiant, reg_flags_fragmentOffset, reg_TTL,
reg_protocol, reg_header_checksum, reg_src_ipv4, reg_dest_ipv4, reg_payload,compl});

endmodule
