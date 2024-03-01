module mat_packet_dispatcher #(
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2,

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // State
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

    input wire [2:0]state,

    input wire [31:0] configurable_ipv4_address,

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
    output wire [AXIS_DEST_WIDTH-1:0] m_axis_mat_tdest
);
    reg reg_drop=1'b0;
    reg [AXIS_DEST_WIDTH-1:0] reg_tdest;

    assign drop=reg_drop;
    assign m_axis_mat_tdest=reg_tdest;

    always @(posedge clk)begin
        reg_drop=1'b0;
        reg_tdest=0;

        case (state)
            CONTROL:begin
                if (parsed_ethtype==16'h0800 && valid_parsed_ethtype)begin

                    if (parsed_src_Ipv4==configurable_ipv4_address && valid_parsed_src_Ipv4) begin
                        reg_drop=1'b1;
                    end
                    else begin
                        reg_drop=1'b0;
                    end
                end else begin
                    reg_drop=1'b0;
                end

                reg_tdest=parsed_src_Ipv4[1:0];
            end
            SEND_ANALYSED_DATA:begin
                reg_tdest=parsed_src_Ipv4[1:0];
            end
            SEND_REMAIN:begin
                reg_tdest=parsed_src_Ipv4[1:0];
            end
        endcase
    end

endmodule




