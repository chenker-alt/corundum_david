module buffer_parser_packet_dispatcher #(
    // Ethernet interface configuration
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2,

    // Parser/Mat/deparser configuration
    parameter COUNT_META_DATA_MAX=5,
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
    input wire clk,

    input wire [STATE_WIDTH-1:0] state,
    input wire [COUNTER_WIDTH-1:0] count,

    input wire [AXIS_DATA_WIDTH-1:0]   s_axis_parser_tdata,

    output reg [AXIS_DATA_WIDTH-1:0]   m_axis_parser_tdata,

    //ethernet
    output wire [48-1:0] parsed_Mac_dest,
    output reg valid_parsed_Mac_dest,
    output wire [48-1:0] parsed_Mac_src,
    output reg valid_parsed_Mac_src,
    output wire [16-1:0] parsed_ethtype,
    output reg valid_parsed_ethtype,

    //ipv4
    output wire [8-1:0] parsed_IHL,
    output reg valid_parsed_IHL,
    output wire [6-1:0] parsed_DSCP,
    output reg valid_parsed_DSCP,
    output wire [2-1:0] parsed_ECN,
    output reg valid_parsed_ECN,
    output wire [16-1:0] parsed_Length,
    output reg valid_parsed_Length,
    output wire [16-1:0] parsed_Identifiant,
    output reg valid_parsed_Identifiant,
    output wire [16-1:0] parsed_Flags_FragmentOffset,
    output reg valid_parsed_Flags_FragmentOffset,
    output wire [8-1:0] parsed_TTL,
    output reg valid_parsed_TTL,
    output wire [8-1:0] parsed_Protocol,
    output reg valid_parsed_Protocol,
    output wire [16-1:0] parsed_HeaderChecksum,
    output reg valid_parsed_HeaderChecksum,
    output wire [32-1:0] parsed_src_Ipv4,
    output reg valid_parsed_src_Ipv4,
    output wire [32-1:0] parsed_dest_Ipv4,
    output reg valid_parsed_dest_Ipv4

);

    reg [BUFFER_DATA_WIDTH -1:0]   meta_tdata=0;

    initial begin

        if (AXIS_DATA_WIDTH != 64) begin
            $error("Error: DATA_WIDTH doit être 64, actuellement il est de %d", DATA_WIDTH);
            $finish;
        end
    end

    function [AXIS_DATA_WIDTH-1:0] reverse_bytes(input [AXIS_DATA_WIDTH-1:0] data);
        parameter BYTE_WIDTH = 8;
        parameter NUM_BYTES = AXIS_DATA_WIDTH / BYTE_WIDTH;
        integer i;
        begin
            for (i = 0; i < NUM_BYTES; i = i + 1) begin
                reverse_bytes[i*BYTE_WIDTH +: BYTE_WIDTH] = data[(NUM_BYTES-1-i)*BYTE_WIDTH +: BYTE_WIDTH];
            end
        end
    endfunction

    localparam PTR_MAC_DEST =48;
    localparam MAC_DEST_WIDTH=48;
    localparam PTR_MAC_SRC = 96;
    localparam MAC_SRC_WIDTH=48;
    localparam PTR_ETHTYPE = 112;
    localparam ETHTYPE_WIDTH=16;

    localparam PTR_IHL=8;
    localparam IHL_WIDTH=8;
    localparam PTR_DSCP=14;
    localparam DSCP_WIDTH=6;
    localparam PTR_ECN=16;
    localparam ECN_WIDTH=2;
    localparam PTR_LENGTH=32;
    localparam LENGTH_WIDTH=16;
    localparam PTR_IDENTIFIANT=48;
    localparam IDENTIFIANT_WIDTH=16;
    localparam PTR_FLAGS_FRAGMENTOFFSET=64;
    localparam FLAGS_FRAGMENTOFFSET_WIDTH=16;
    localparam PTR_TTL=72;
    localparam TTL_WIDTH=8;
    localparam PTR_PROTOCOL=80;
    localparam PROTOCOL_WIDTH=8;
    localparam PTR_HEADERCHECKSUM=96;
    localparam HEADERCHECKSUM_WIDTH=16;
    localparam PTR_SRC_IPV4=128;
    localparam SRC_IPV4_WIDTH=32;
    localparam PTR_DEST_IPV4=160;
    localparam DEST_IPV4_WIDTH=32;

    assign parsed_Mac_dest             = valid_parsed_Mac_dest ? meta_tdata[BUFFER_DATA_WIDTH-PTR_MAC_DEST +: MAC_DEST_WIDTH] : 0;
    assign parsed_Mac_src              = valid_parsed_Mac_src ? meta_tdata[BUFFER_DATA_WIDTH-PTR_MAC_SRC +: MAC_SRC_WIDTH] : 0;
    assign parsed_ethtype              = valid_parsed_ethtype ? meta_tdata[BUFFER_DATA_WIDTH-PTR_ETHTYPE +: MAC_SRC_WIDTH] : 0;

    assign parsed_IHL                  = valid_parsed_IHL ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_IHL+PTR_ETHTYPE) +: IHL_WIDTH] : 0;
    assign parsed_DSCP                 = valid_parsed_DSCP ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_DSCP+PTR_ETHTYPE) +: DSCP_WIDTH] : 0;
    assign parsed_ECN                  = valid_parsed_ECN ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_ECN+PTR_ETHTYPE) +: ECN_WIDTH] : 0;
    assign parsed_Length               = valid_parsed_Length ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_LENGTH+PTR_ETHTYPE) +: LENGTH_WIDTH] : 0;
    assign parsed_Identifiant          = valid_parsed_Identifiant ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_IDENTIFIANT+PTR_ETHTYPE) +: IDENTIFIANT_WIDTH] : 0;
    assign parsed_Flags_FragmentOffset = valid_parsed_Flags_FragmentOffset ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_FLAGS_FRAGMENTOFFSET+PTR_ETHTYPE) +: FLAGS_FRAGMENTOFFSET_WIDTH] : 0;
    assign parsed_TTL                  = valid_parsed_TTL ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_TTL+PTR_ETHTYPE) +: TTL_WIDTH] : 0;
    assign parsed_Protocol             = valid_parsed_Protocol ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_PROTOCOL+PTR_ETHTYPE) +: PROTOCOL_WIDTH] : 0;
    assign parsed_HeaderChecksum       = valid_parsed_HeaderChecksum ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_HEADERCHECKSUM+PTR_ETHTYPE) +: HEADERCHECKSUM_WIDTH] : 0;
    assign parsed_src_Ipv4             = valid_parsed_src_Ipv4 ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_SRC_IPV4+PTR_ETHTYPE) +: SRC_IPV4_WIDTH] : 0;
    assign parsed_dest_Ipv4            = valid_parsed_dest_Ipv4 ? meta_tdata[BUFFER_DATA_WIDTH-(PTR_DEST_IPV4+PTR_ETHTYPE) +: DEST_IPV4_WIDTH] : 0;

    always @(posedge clk) begin
        case(state)
            IDLE:begin
                meta_tdata                  =0;

                valid_parsed_Mac_dest               = 1'b0;
                valid_parsed_Mac_src                = 1'b0;
                valid_parsed_ethtype                = 1'b0;
                valid_parsed_IHL                    = 1'b0;
                valid_parsed_DSCP                   = 1'b0;
                valid_parsed_ECN                    = 1'b0;
                valid_parsed_Length                 = 1'b0;
                valid_parsed_Identifiant            = 1'b0;
                valid_parsed_Flags_FragmentOffset   = 1'b0;
                valid_parsed_TTL                    = 1'b0;
                valid_parsed_Protocol               = 1'b0;
                valid_parsed_HeaderChecksum         = 1'b0;
                valid_parsed_src_Ipv4               = 1'b0;
                valid_parsed_dest_Ipv4              = 1'b0;
            end
            PARSE_DATA:begin
                meta_tdata  [(BUFFER_DATA_WIDTH)-count*AXIS_DATA_WIDTH-1-:AXIS_DATA_WIDTH]=reverse_bytes(s_axis_parser_tdata);

                if ((count+1)*AXIS_DATA_WIDTH>PTR_MAC_DEST) begin
                    valid_parsed_Mac_dest=1;
                end else begin
                    valid_parsed_Mac_dest=0;
                end
                if ((count+1)*AXIS_DATA_WIDTH>PTR_MAC_SRC) begin
                    valid_parsed_Mac_src=1;
                end else begin
                    valid_parsed_Mac_src=0;
                end
                if ((count+1)*AXIS_DATA_WIDTH>PTR_ETHTYPE) begin
                    valid_parsed_ethtype=1;
                end else begin
                    valid_parsed_ethtype=0;
                end

                if (parsed_ethtype == 16'h0800) begin // IPv4
                // IHL
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_IHL + PTR_ETHTYPE) begin
                        valid_parsed_IHL = 1;
                    end else begin
                        valid_parsed_IHL = 0;
                    end

                    // DSCP
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_DSCP + PTR_ETHTYPE) begin
                        valid_parsed_DSCP = 1;
                    end else begin
                        valid_parsed_DSCP = 0;
                    end

                    // ECN
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_ECN + PTR_ETHTYPE) begin
                        valid_parsed_ECN = 1;
                    end else begin
                        valid_parsed_ECN = 0;
                    end

                    // Total Length
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_LENGTH + PTR_ETHTYPE) begin
                        valid_parsed_Length = 1;
                    end else begin
                        valid_parsed_Length = 0;
                    end

                    // Identification
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_IDENTIFIANT + PTR_ETHTYPE) begin
                        valid_parsed_Identifiant = 1;
                    end else begin
                        valid_parsed_Identifiant = 0;
                    end

                    // Flags and Fragment Offset
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_FLAGS_FRAGMENTOFFSET + PTR_ETHTYPE) begin
                        valid_parsed_Flags_FragmentOffset = 1;
                    end else begin
                        valid_parsed_Flags_FragmentOffset = 0;
                    end

                    // TTL
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_TTL + PTR_ETHTYPE) begin
                        valid_parsed_TTL = 1;
                    end else begin
                        valid_parsed_TTL = 0;
                    end

                    // Protocol
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_PROTOCOL + PTR_ETHTYPE) begin
                        valid_parsed_Protocol = 1;
                    end else begin
                        valid_parsed_Protocol = 0;
                    end

                    // Header Checksum
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_HEADERCHECKSUM + PTR_ETHTYPE) begin
                        valid_parsed_HeaderChecksum = 1;
                    end else begin
                        valid_parsed_HeaderChecksum = 0;
                    end

                    // Source IP Address
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_SRC_IPV4 + PTR_ETHTYPE) begin
                        valid_parsed_src_Ipv4 = 1;
                    end else begin
                        valid_parsed_src_Ipv4 = 0;
                    end

                    // Destination IP Address
                    if ((count+1 + 1) *AXIS_DATA_WIDTH > PTR_DEST_IPV4 + PTR_ETHTYPE) begin
                        valid_parsed_dest_Ipv4 = 1;
                    end else begin
                        valid_parsed_dest_Ipv4 = 0;
                    end
                end
            end
            SEND_ANALYSED_DATA:begin
                m_axis_parser_tdata =reverse_bytes(meta_tdata[(COUNT_META_DATA_MAX*AXIS_DATA_WIDTH)-count*AXIS_DATA_WIDTH-1-:AXIS_DATA_WIDTH]);

            end
            default: begin
                meta_tdata                  <= meta_tdata;

                valid_parsed_Mac_dest               = valid_parsed_Mac_dest ;
                valid_parsed_Mac_src                 = valid_parsed_Mac_src ;
                valid_parsed_ethtype                 = valid_parsed_ethtype ;
                valid_parsed_IHL                     = valid_parsed_IHL ;
                valid_parsed_DSCP                    = valid_parsed_DSCP ;
                valid_parsed_ECN                     = valid_parsed_ECN ;
                valid_parsed_Length                  = valid_parsed_Length ;
                valid_parsed_Identifiant             = valid_parsed_Identifiant ;
                valid_parsed_Flags_FragmentOffset    = valid_parsed_Flags_FragmentOffset ;
                valid_parsed_TTL                     = valid_parsed_TTL ;
                valid_parsed_Protocol                = valid_parsed_Protocol ;
                valid_parsed_HeaderChecksum          = valid_parsed_HeaderChecksum ;
                valid_parsed_src_Ipv4                = valid_parsed_src_Ipv4 ;
                valid_parsed_dest_Ipv4               = valid_parsed_dest_Ipv4 ;
            end
        endcase
    end
endmodule




