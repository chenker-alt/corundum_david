module deparser #(
    parameter IF_COUNT = 1,
    parameter DATA_WIDTH = 64,
    parameter KEEP_WIDTH = DATA_WIDTH/8,
    parameter ID_WIDTH =1,
    parameter DEST_WIDTH = 9,
    parameter USER_WIDTH = 97,

    parameter COUNT_META_DATA_MAX=1,
    parameter COUNTER_WIDTH=1,

    parameter IDLE                  = 0,
    parameter PARSE_DATA            = 1,
    parameter CONTROL               = 2,
    parameter SEND_ANALYSED_DATA    = 3,
    parameter SEND_REMAIN           = 4,
    parameter DROP                  = 5
)
(
    input wire clk,

    input wire [2:0] state,
    input wire [COUNTER_WIDTH-1:0] count,

    input wire [47:0] deparsed_Mac_dest,
    input wire [47:0] deparsed_Mac_src,
    input wire [15:0] deparsed_ethtype,
    input wire [7:0] deparsed_IHL,
    input wire [5:0] deparsed_DSCP,
    input wire [1:0] deparsed_ECN,
    input wire [15:0] deparsed_Length,
    input wire [15:0] deparsed_Identifiant,
    input wire [15:0] deparsed_Flags_FragmentOffset,
    input wire [7:0] deparsed_TTL,
    input wire [7:0] deparsed_Protocol,
    input wire [15:0] deparsed_HeaderChecksum,
    input wire [31:0] deparsed_src_Ipv4,
    input wire [31:0] deparsed_dest_Ipv4,

    input wire [COUNT_META_DATA_MAX*DATA_WIDTH -1:0]   reg_meta_tdata,
    input wire [COUNT_META_DATA_MAX*KEEP_WIDTH -1:0]   reg_meta_tkeep,
    input wire [COUNT_META_DATA_MAX*USER_WIDTH -1:0]   reg_meta_tuser,
    input wire [COUNT_META_DATA_MAX*ID_WIDTH -1:0]     reg_meta_tid,
    input wire [COUNT_META_DATA_MAX*DEST_WIDTH -1:0]   reg_meta_tdest,

    output reg [IF_COUNT*DATA_WIDTH-1:0]   m_axis_deparser_tdata,
    output reg [IF_COUNT*KEEP_WIDTH-1:0]   m_axis_deparser_tkeep,
    output reg [IF_COUNT*USER_WIDTH-1:0]   m_axis_deparser_tuser,
    output reg [IF_COUNT*ID_WIDTH-1:0]     m_axis_deparser_tid,
    output reg [IF_COUNT*DEST_WIDTH-1:0]   m_axis_deparser_tdest
);

function [DATA_WIDTH-1:0] reverse_bytes(input [DATA_WIDTH-1:0] data);
        parameter BYTE_WIDTH = 8;
        parameter NUM_BYTES = DATA_WIDTH / BYTE_WIDTH;
        integer i;
        begin
            for (i = 0; i < NUM_BYTES; i = i + 1) begin
                reverse_bytes[i*BYTE_WIDTH +: BYTE_WIDTH] = data[(NUM_BYTES-1-i)*BYTE_WIDTH +: BYTE_WIDTH];
            end
        end
    endfunction

    always @(*) begin
                m_axis_deparser_tdata=0;
                m_axis_deparser_tkeep=0;
                m_axis_deparser_tuser=0;
                m_axis_deparser_tid=0;
                m_axis_deparser_tdest=0;
        case(state)
            SEND_ANALYSED_DATA:begin
                m_axis_deparser_tdata=reverse_bytes(reg_meta_tdata[(COUNT_META_DATA_MAX*DATA_WIDTH)-count*DATA_WIDTH-1-:DATA_WIDTH]);
                m_axis_deparser_tkeep=reg_meta_tkeep[(COUNT_META_DATA_MAX*KEEP_WIDTH)-count*KEEP_WIDTH-1-:KEEP_WIDTH];
                m_axis_deparser_tuser=reg_meta_tuser[(COUNT_META_DATA_MAX*USER_WIDTH)-count*USER_WIDTH-1-:USER_WIDTH];
                m_axis_deparser_tid=reg_meta_tid[(COUNT_META_DATA_MAX*ID_WIDTH)-count*ID_WIDTH-1-:ID_WIDTH];
                m_axis_deparser_tdest=reg_meta_tdest[(COUNT_META_DATA_MAX*DEST_WIDTH)-count*DEST_WIDTH-1-:DEST_WIDTH];
            end
            default begin
                m_axis_deparser_tdata=0;
                m_axis_deparser_tkeep=0;
                m_axis_deparser_tuser=0;
                m_axis_deparser_tid=0;
                m_axis_deparser_tdest=0;
            end
        endcase
     end
endmodule




