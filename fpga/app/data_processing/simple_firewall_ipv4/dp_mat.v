module mat #(
    parameter IDLE                  = 0,
    parameter PARSE_DATA            = 1,
    parameter CONTROL               = 2,
    parameter SEND_ANALYSED_DATA    = 3,
    parameter SEND_REMAIN           = 4,
    parameter DROP                  = 5

)
(
    input wire clk,

    input wire [2:0]state,

    //ethernet
    input wire [47:0] parsed_Mac_dest,
    input wire valid_parsed_Mac_dest,
    input wire [47:0] parsed_Mac_src,
    input wire valid_parsed_Mac_src,
    input wire [15:0] parsed_ethtype,
    input wire valid_parsed_ethtype,

    //Ipv4
    input wire [7:0] parsed_IHL,
    input wire valid_parsed_IHL,
    input wire [5:0] parsed_DSCP,
    input wire valid_parsed_DSCP,
    input wire [1:0] parsed_ECN,
    input wire valid_parsed_ECN,
    input wire [15:0] parsed_Length,
    input wire valid_parsed_Length,
    input wire [15:0] parsed_Identifiant,
    input wire valid_parsed_Identifiant,
    input wire [15:0] parsed_Flags_FragmentOffset,
    input wire valid_parsed_Flags_FragmentOffset,
    input wire [7:0] parsed_TTL,
    input wire valid_parsed_TTL,
    input wire [7:0] parsed_Protocol,
    input wire valid_parsed_Protocol,
    input wire [15:0] parsed_HeaderChecksum,
    input wire valid_parsed_HeaderChecksum,
    input wire [31:0] parsed_src_Ipv4,
    input wire valid_parsed_src_Ipv4,
    input wire [31:0] parsed_dest_Ipv4,
    input wire valid_parsed_dest_Ipv4,

    output wire drop,

    output wire [47:0] deparsed_Mac_dest,
    output wire [47:0] deparsed_Mac_src,
    output wire [15:0] deparsed_ethtype,

    output wire [7:0] deparsed_IHL,
    output wire [5:0] deparsed_DSCP,
    output wire [1:0] deparsed_ECN,
    output wire [15:0] deparsed_Length,
    output wire [15:0] deparsed_Identifiant,
    output wire [15:0] deparsed_Flags_FragmentOffset,
    output wire [7:0] deparsed_TTL,
    output wire [7:0] deparsed_Protocol,
    output wire [15:0] deparsed_HeaderChecksum,
    output wire [31:0] deparsed_src_Ipv4,
    output wire [31:0] deparsed_dest_Ipv4
);

    reg reg_drop=1'b0;
    assign drop=reg_drop;

    assign deparsed_Mac_dest = parsed_Mac_dest;
    assign deparsed_Mac_src = parsed_Mac_src;
    assign deparsed_ethtype = parsed_ethtype;

    assign deparsed_IHL = parsed_IHL;
    assign deparsed_DSCP = parsed_DSCP;
    assign deparsed_ECN = parsed_ECN;
    assign deparsed_Length = parsed_Length;
    assign deparsed_Identifiant = parsed_Identifiant;
    assign deparsed_Flags_FragmentOffset = parsed_Flags_FragmentOffset;
    assign deparsed_TTL = parsed_TTL;
    assign deparsed_Protocol = parsed_Protocol;
    assign deparsed_HeaderChecksum = parsed_HeaderChecksum;
    assign deparsed_src_Ipv4 = parsed_src_Ipv4;
    assign deparsed_dest_Ipv4 = parsed_dest_Ipv4;

    always @(*)begin

        case (state)
            IDLE:begin
                reg_drop=1'b0;
            end

            CONTROL:begin
                if (parsed_ethtype==16'h0800 && valid_parsed_ethtype)begin

                    if (parsed_src_Ipv4==32'hAC110114 && valid_parsed_src_Ipv4) begin //172.17.1.20
                        reg_drop=1'b1;
                    end
                    else begin
                        reg_drop=1'b0;
                    end
                end else begin
                    reg_drop=1'b0;
                end
            end

        default: begin
            reg_drop=1'b0;
            end

        endcase
    end

endmodule




